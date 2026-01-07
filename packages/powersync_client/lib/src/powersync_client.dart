import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:developer';
import 'dart:ui';

import 'package:env/env.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync_client/powersync_client.dart';
import 'package:powersync_client/src/attachments/post/uploaded_attachments_storage.dart';
import 'package:powersync_client/src/schema/schema.dart';
import 'package:powersync_core/attachments/attachments.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared/shared.dart' as shared;
import 'package:storage/storage.dart';

/// Env value signature that can be used to get an environment value, base
/// on provided [Env].
typedef EnvValue = String Function(Env env);

/// Postgres Response codes that we cannot recover from by retrying.
final List<RegExp> fatalResponseCodes = [
  // Class 22 — Data Exception
  // Examples include data type mismatch.
  RegExp(r'^22...$'),
  // Class 23 — Integrity Constraint Violation.
  // Examples include NOT NULL, FOREIGN KEY and UNIQUE violations.
  RegExp(r'^23...$'),
  // INSUFFICIENT PRIVILEGE - typically a row-level security violation
  RegExp(r'^42501$'),
];

/// Use Supabase for authentication and data upload.
class SupabaseConnector extends PowerSyncBackendConnector {
  /// {@macro supabase_connector}
  SupabaseConnector({required this.env});

  /// Environment values.
  final EnvValue env;

  Future<void>? _refreshFuture;

  /// Get a Supabase token to authenticate against the PowerSync instance.
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Wait for pending session refresh if any
    await _refreshFuture;

    // Use Supabase token for PowerSync
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return null;
    }

    // Use the access token to authenticate against PowerSync
    final token = session.accessToken;

    // userId and expiresAt are for debugging purposes only
    final userId = session.user.id;
    final expiresAt = session.expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return PowerSyncCredentials(
      endpoint: env(Env.powerSyncUrl),
      token: token,
      userId: userId,
      expiresAt: expiresAt,
    );
  }

  @override
  void invalidateCredentials() {
    // Trigger a session refresh if auth fails on PowerSync.
    // Generally, sessions should be refreshed automatically by Supabase.
    // However, in some cases it can be a while before the session refresh is
    // retried. We attempt to trigger the refresh as soon as we get an auth
    // failure on PowerSync.
    //
    // This could happen if the device was offline for a while and the session
    // expired, and nothing else attempt to use the session it in the meantime.
    //
    // Timeout the refresh call to avoid waiting for long retries,
    // and ignore any errors. Errors will surface as expired tokens.
    _refreshFuture = Supabase.instance.client.auth
        .refreshSession()
        .timeout(const Duration(seconds: 5))
        .then((response) => null, onError: (error) => null);
  }

  // Upload pending changes to Supabase.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // This function is called whenever there is data to upload, whether the
    // device is online or offline.
    // If this call throws an error, it is retried periodically.
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    final rest = Supabase.instance.client.rest;
    CrudEntry? lastOp;
    try {
      final batch = transaction.crud;

      // Note: If transactional consistency is important, use database functions
      // or edge functions to process the entire transaction in a single call.
      for (final op in batch) {
        lastOp = op;

        final table = rest.from(op.table);
        if (op.op == UpdateType.put) {
          final data = Map<String, dynamic>.of(op.opData!);
          data['id'] = op.id;
          await table.upsert(data);
        } else if (op.op == UpdateType.patch) {
          await table.update(op.opData!).eq('id', op.id);
        } else if (op.op == UpdateType.delete) {
          await table.delete().eq('id', op.id);
        }
      }

      // All operations successful.
      await transaction.complete();
    } on PostgrestException catch (e, stackTrace) {
      if (e.code != null &&
          fatalResponseCodes.any((re) => re.hasMatch(e.code!))) {
        /// Instead of blocking the queue with these errors,
        /// discard the (rest of the) transaction.
        ///
        /// Note that these errors typically indicate a bug in the application.
        /// If protecting against data loss is important, save the failing
        /// records
        /// elsewhere instead of discarding, and/or notify the user.
        log(
          'Data upload error - discarding $lastOp, error: $e, '
          'stackTrace: $stackTrace',
        );
        await transaction.complete();
      } else {
        /// Error may be retryable - e.g. network error or temporary server
        /// error. Throwing an error here causes this call to be retried after
        /// a delay.
        rethrow;
      }
    }
  }
}

/// {@template powersync_client}
/// A package that manages connection to the PowerSync cloud service and
/// database.
///
/// The [PowerSyncClient] client is responsible for managing the local
/// database and interacting with the Supabase client.
/// {@endtemplate}
class PowerSyncClient {
  /// {@macro powersync_client}
  PowerSyncClient({required this.env, required this.listStorage});

  /// Environment values.
  final EnvValue env;

  /// Persistent storage instance.
  final ListStorage listStorage;

  bool _isInitialized = false;

  late final PowerSyncDatabase _db;

  late final AttachmentQueue _attachmentQueue;
  late final RemoteStorage _remoteStorage;

  /// The Supabase client.
  late final SupabaseClient supabase = Supabase.instance.client;

  /// Initializes the local database and opens a new instance of the database.
  Future<void> initialize({bool offlineMode = false}) async {
    if (!_isInitialized) {
      await _openDatabase();
      _isInitialized = true;
    }
  }

  /// Returns the PowerSync database instance.
  PowerSyncDatabase db() {
    if (!_isInitialized) {
      throw Exception(
        'PowerSyncDatabase not initialized. Call initialize() first.',
      );
    }
    return _db;
  }

  /// Returns the attachments queue instance.
  AttachmentQueue attachmentQueue() {
    if (!_isInitialized) {
      throw Exception(
        'PowerSyncClient not initialized. Call initialize() first.',
      );
    }
    return _attachmentQueue;
  }

  /// Returns the remote storage instance.
  RemoteStorage remoteStorage() {
    if (!_isInitialized) {
      throw Exception(
        'PowerSyncClient not initialized. Call initialize() first.',
      );
    }
    return _remoteStorage;
  }

  /// Save the photo attachment
  Future<Attachment> saveAttachment({
    required Stream<List<int>> data,
    required shared.AttachmentFile file,
    required String postId,
    String? attachmentId,
    bool isUploaded = false,
    shared.Minithumbnail? minithumbnail,
  }) async {
    final attachment = await attachmentQueue().saveFile(
      data: data,
      mediaType: file.mediaType!.mimeType,
      fileExtension: file.extension,
      id: attachmentId ?? file.nameWithoutExtension,
      metaData: jsonEncode({
        'post_id': postId,
        'is_uploaded': isUploaded,
        if (minithumbnail != null)
          'minithumbnail': jsonEncode(minithumbnail.toJson()),
      }),
      updateHook: (tx, attachment) async {},
    );
    await db().execute(
      '''
      UPDATE ${AttachmentsQueueTable.defaultTableName}
      SET post_id = ? WHERE id = ?
    ''',
      [postId, attachment.id],
    );
    log(
      'Saved attachment: $attachment and updated with post id: $postId',
      name: 'PowerSyncClient',
    );
    return attachment;
  }

  /// Returns the relative directory of the local database.
  Future<String> getDatabasePath() async {
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, 'powersync-attachments-example.db');
  }

  /// Checks if a user is logged in.
  bool isLoggedIn() {
    return supabase.auth.currentSession?.accessToken != null;
  }

  /// Loads the Supabase client with the provided environment values.
  Future<void> _loadSupabase() async {
    await Supabase.initialize(
      url: env(Env.supabaseUrl),
      anonKey: env(Env.supabaseAnonKey),
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }

  /// Stream of whether the database has connected and synced.
  ///
  /// This stream is a very crucial part of the PowerSyncDatabase because of
  /// the syncing process.
  ///
  /// When we launch the app, it takes some time to sync the freshest data from
  /// the Supabase database, so we need to know when it was synced. We can then
  /// listen to the changes and fetch data when the db is fully synced with the
  /// latest data.
  final BehaviorSubject<bool> isConnectedAndSynced = BehaviorSubject.seeded(
    false,
  );

  /// Waits for the database to be synced.
  Future<T> waitForSync<T>(Future<T> Function() action) async {
    final completer = Completer<T>();
    await _waitForHasConnectedAndSynced(
      onHasConnectedAndSynced: () {
        completer.complete(action());
      },
    );
    return completer.future;
  }

  /// Waits for the database to be connected and synced.
  Future<void> _waitForHasConnectedAndSynced({
    VoidCallback? onHasConnectedAndSynced,
  }) async {
    var available = isConnectedAndSynced.value;
    while (!available) {
      available = isConnectedAndSynced.value;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return onHasConnectedAndSynced?.call();
  }

  Future<void> _onConnect() async {
    const delay = Duration(milliseconds: 500);
    const maxAttempts = 40; // 20 seconds (40 attempts * 500ms delay)
    var attempts = 0;

    // Use a periodic timer to check status without blocking
    Timer.periodic(delay, (timer) {
      attempts++;
      final hasConnected = _db.connected;
      final hasSynced = _db.currentStatus.hasSynced ?? false;

      if (hasConnected && hasSynced) {
        log(
          'Connection and sync with PowerSync established',
          name: 'PowerSyncClient',
        );
        isConnectedAndSynced.add(true);
        timer.cancel();
      } else if (attempts >= maxAttempts) {
        // If we reach the max attempts, we force the stream to true.
        // This is to prevent the app from getting stuck in a loop of
        // attempting to connect to PowerSync.
        //
        // This happens when the app is launched in offline mode, and the
        // device has no internet connection. PowerSync can't sync data with
        // Supabase database without an internet connection, therefore it's
        // gonna loop forever untill the connection is not resumed.
        //
        // Even if hasConnectedAndSynced is true and device is offline,
        // database anyways should display some data while being offline,
        // because this is what PowerSync is intended for.
        log(
          'Max attempts reached. Forcing hasConnectedAndSynced to true.',
          name: 'PowerSyncClient',
        );
        isConnectedAndSynced.add(true);
        timer.cancel();
      } else {
        if (!hasConnected) {
          log(
            'Trying to establish connection to PowerSync: $hasConnected',
            name: 'PowerSyncClient',
          );
        } else if (!hasSynced) {
          log(
            'Trying to establish current status '
            'with PowerSync: $hasSynced',
            name: 'PowerSyncClient',
          );
        }
      }
    });
  }

  /// Opens the local database, initializes the Supabase client, and connects
  /// to the database if the user is logged in.
  Future<void> _openDatabase() async {
    final db = PowerSyncDatabase(
      schema: schema,
      path: await getDatabasePath(),
    );
    await db.initialize();
    await _loadSupabase();

    _db = db;

    SupabaseConnector? currentConnector;

    currentConnector = SupabaseConnector(env: env);

    Future<void> connect() async {
      await _db
          .connect(
            connector: currentConnector!,
            options: const SyncOptions(),
          )
          .whenComplete(() async {
            try {
              await _onConnect();
            } catch (error, stackTrace) {
              log(
                'Error while waiting for connection and syncing to PowerSync.',
                name: 'PowerSyncClient',
                error: error,
                stackTrace: stackTrace,
              );
              isConnectedAndSynced.add(true);
            }
          });
    }

    if (isLoggedIn()) {
      currentConnector = SupabaseConnector(env: env);
      await connect();
    }

    supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.passwordRecovery) {
        isConnectedAndSynced.add(false);
        currentConnector = null;
        await _db.disconnect();

        currentConnector = SupabaseConnector(env: env);
        await connect();
      }
      if (event == AuthChangeEvent.signedOut) {
        currentConnector = null;
        await _db.disconnect().whenComplete(() async {
          isConnectedAndSynced.add(false);
        });
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        log('Token refreshed', name: 'PowerSyncClient');
        await currentConnector?.prefetchCredentials();
      }
    });
    _db.statusStream.listen((status) {
      log('PowerSync status: $status', name: 'PowerSyncClient');
    });

    // If you want to clear local queue and local storage, uncomment:
    // await _db.execute('DELETE FROM attachments_queue');
    // await _db.execute('DELETE FROM post_attachments_local');
    // await _db.execute('DELETE FROM posts_local');

    try {
      final uploadedAttachmentsStorage = UploadedAttachmentsStorage(
        storage: listStorage,
      );

      final remoteStorage = SupabasePostStorageAdapter(
        db: _db,
        uploadedAttachmentsStorage: uploadedAttachmentsStorage,
      );

      _remoteStorage = remoteStorage;

      final attachmentQueue = await initializePostAttachmentQueue(
        _db,
        remoteStorage,
      );

      _attachmentQueue = attachmentQueue;

      await attachmentQueue.startSync();
    } catch (error, stackTrace) {
      dev.log(
        'Error initializing remote storage',
        name: 'PowerSyncClient',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns a stream of authentication state changes from the Supabase client.
  Stream<AuthState> authStateChanges() =>
      supabase.auth.onAuthStateChange.asBroadcastStream();

  /// Updates the user app metadata.
  Future<void> updateUser({
    String? email,
    String? phone,
    String? password,
    String? nonce,
    Object? data,
  }) => supabase.auth.updateUser(
    UserAttributes(
      email: email,
      phone: phone,
      password: password,
      nonce: nonce,
      data: data,
    ),
  );

  /// Sends a password reset email to the specified email address.
  Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) => supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);

  /// Verifies the OTP token for password recovery.
  Future<void> verifyOTP({
    required String token,
    required String email,
  }) => supabase.auth.verifyOTP(
    email: email,
    token: token,
    type: OtpType.recovery,
  );

  /// Returns the public URL for a storage object.
  String getPublicUrl({
    required String storageBucket,
    required String name,
    required String Function(String name) path,
    TransformOptions? transform,
  }) => supabase.storage
      .from(storageBucket)
      .getPublicUrl(path(name), transform: transform);
}
