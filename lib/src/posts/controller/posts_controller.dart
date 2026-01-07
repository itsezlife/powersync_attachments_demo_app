// ignore_for_file: use_setters_to_change_properties, lines_longer_than_80_chars

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:powersync_attachments_example/src/common/models/post_progress.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:powersync_attachments_example/src/posts/create_post/utils/asset_entity_extensions.dart';
import 'package:powersync_attachments_example/src/posts/create_post/widgets/dynamic_media_display.dart';
import 'package:powersync_attachments_example/src/user_profile/bloc/user_profile_bloc.dart';
import 'package:powersync_client/powersync_client.dart';
import 'package:shared/shared.dart' as shared;
import 'package:shared/shared.dart' hide Attachment;

class PostMediaArgs extends Equatable {
  const PostMediaArgs({
    required this.originFile,
    required this.displayBytes,
    required this.targetWidth,
    required this.targetHeight,
    required this.originalWidth,
    required this.originalHeight,
    this.cropRect,
  });

  final File originFile;
  final Uint8List displayBytes;
  final int targetWidth;
  final int targetHeight;
  final int originalWidth;
  final int originalHeight;
  final Rect? cropRect;

  @override
  List<Object?> get props => [
    displayBytes,
    targetWidth,
    targetHeight,
    originalWidth,
    originalHeight,
    cropRect,
  ];
}

void createFile(List<dynamic> message) =>
    File(message[1] as String).writeAsBytesSync(message[0] as List<int>);

class PostsController {
  factory PostsController() => _instance;

  PostsController._();

  static final PostsController _instance = PostsController._();

  late BuildContext _context;

  late final supabase = Supabase.instance.client;

  late final _postsMediaStorage = supabase.storage.from('post_attachments');

  void init({required BuildContext context}) {
    _context = context;
  }

  void showError(String message, {Object? error, StackTrace? stackTrace}) {
    log('Error: $message', error: error, stackTrace: stackTrace);
    ScaffoldMessenger.of(
      _context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _postsMediaStorage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        cacheControl: '31536000',
      ),
    );
    return _postsMediaStorage.getPublicUrl(path);
  }

  Future<void> processPostMedia({
    required String postId,
    List<PostMediaArgs>? attachmentArgs,
    String? content,
  }) async {
    void uploadPost({List<shared.Attachment> attachments = const []}) {
      _context.read<UserProfileBloc>().add(
        UserProfilePostCreateRequested(
          postId: postId,
          content: content,
          attachments: attachments,
        ),
      );
    }

    if (attachmentArgs == null) {
      uploadPost();
      return;
    }

    final attachments = <shared.Attachment>[];
    for (final attachmentArg in attachmentArgs) {
      final name = attachmentArg.originFile.path.split('/').last;
      final attachmentFile = shared.AttachmentFile(
        name: name,
        path: attachmentArg.originFile.path,
        bytes: attachmentArg.originFile.readAsBytesSync(),
        size: attachmentArg.originFile.lengthSync(),
      );

      final attachment = shared.Attachment(
        id: uuid.v4(),
        type: AttachmentType.image,
        mimeType: attachmentFile.mediaType?.mimeType,
        file: attachmentFile,
        fileSize: attachmentFile.size,
      );
      attachments.add(attachment);
    }

    final futures = <Future<void>>[];
    for (final attachment in attachments) {
      futures.add(
        compute(createFile, [
          attachment.file!.bytes!,
          Config.appDocsPath.resolveFilePath(attachment.file!.name!),
        ]),
      );
    }
    unawaited(Future.wait(futures));

    uploadPost(attachments: attachments);
  }
}

class PostProvider with ChangeNotifier {
  PostProvider({required this.powerSyncClient}) {
    _initializeProgressFromLocalPosts();
  }

  final PowerSyncClient powerSyncClient;

  List<PostProgress> _progress = [];
  final Map<String, StreamSubscription<void>> _progressListeners = {};
  StreamSubscription<void>? _postsLocalWatcher;

  List<PostProgress> get progress => _progress;

  /// Initialize progress tracking from existing posts_local records
  Future<void> _initializeProgressFromLocalPosts() async {
    try {
      // Query all posts from posts_local table
      final localPosts = await powerSyncClient.db().getAll(
        'SELECT id FROM posts_local',
      );

      // Add progress for each local post
      for (final post in localPosts) {
        final postId = post['id'] as String;
        if (_progress.indexWhere((p) => p.postId == postId) == -1) {
          final localAttachment = await powerSyncClient.db().getOptional(
            'SELECT image_url FROM post_attachments_local WHERE post_id = ? '
            'ORDER BY created_at DESC LIMIT 1',
            [postId],
          );
          if (localAttachment == null) continue;
          _progress.add(
            PostProgress(
              postId: postId,
              asset: null, // No asset available when restoring from DB
              file: File(
                Config.appDocsPath.resolveFilePath(
                  localAttachment['image_url'] as String,
                ),
              ),
              value: 0,
            ),
          );

          // Start watching progress for this post
          _startWatchingProgress(postId);
        }
      }

      if (_progress.isNotEmpty) {
        notifyListeners();
      }

      // Start watching posts_local for deletions
      _startWatchingPostsLocal();
    } on Object catch (e) {
      log(
        'Error initializing progress from local posts: $e',
        name: 'PostProvider',
      );
    }
  }

  /// Watch posts_local table for deletions to remove progress
  void _startWatchingPostsLocal() {
    _postsLocalWatcher?.cancel();

    final stream = powerSyncClient.db().watch('SELECT id FROM posts_local');

    _postsLocalWatcher = stream.listen((results) {
      // Get list of post IDs still in posts_local
      final activePostIds = results.map((r) => r['id'] as String).toSet();

      // Remove progress for posts that are no longer in posts_local
      final progressToRemove = <String>[];
      for (final p in _progress) {
        if (!activePostIds.contains(p.postId)) {
          progressToRemove.add(p.postId);
        }
      }

      progressToRemove.forEach(removeProgress);
    });
  }

  PostProgress? _addProgress(String postId, AssetEntity asset) {
    final list = [..._progress];
    if (list.indexWhere((p) => p.postId == postId) != -1) return null;
    final p = PostProgress(postId: postId, asset: asset, value: 0);
    _progress = [p, ...list];
    notifyListeners();

    // Start watching upload progress
    _startWatchingProgress(postId);

    return p;
  }

  void _updateProgress(String postId, double value, {bool? hasError}) {
    final list = [..._progress];
    final index = list.indexWhere((p) => p.postId == postId);
    if (index == -1) return;
    list[index] = PostProgress(
      postId: postId,
      asset: list[index].asset,
      value: value,
      hasError: hasError,
    );
    _progress = list;
    notifyListeners();
  }

  void removeProgress(String postId) {
    final list = [..._progress];
    final index = list.indexWhere((p) => p.postId == postId);
    if (index == -1) return;
    list.removeAt(index);
    _progress = list;

    // Cancel progress listener
    _progressListeners[postId]?.cancel();
    _progressListeners.remove(postId);

    notifyListeners();
  }

  /// Query post_attachments_local by post_id and calculate upload progress
  Future<double> _calculateUploadProgress(String postId) async {
    try {
      final results = await powerSyncClient.db().getAll(
        '''
        SELECT file_size, sent 
        FROM post_attachments_local 
        WHERE post_id = ?
        ''',
        [postId],
      );

      if (results.isEmpty) {
        return 0.0;
      }

      var totalBytes = 0;
      var sentBytes = 0;

      for (final row in results) {
        final fileSize = row['file_size'] as int? ?? 0;
        final sent = row['sent'] as int? ?? 0;
        totalBytes += fileSize;
        sentBytes += sent;
      }

      if (totalBytes == 0) {
        return 0.0;
      }

      final progress = sentBytes / totalBytes;
      return progress.clamp(0.0, 1.0);
    } on Object catch (e) {
      log('Error calculating upload progress: $e', name: 'PostProvider');
      return 0.0;
    }
  }

  /// Start watching upload progress for a post
  void _startWatchingProgress(String postId) {
    // Cancel existing listener if any
    _progressListeners[postId]?.cancel();

    // Watch for changes in post_attachments_local for this post
    final stream = powerSyncClient.db().watch(
      '''
      SELECT file_size, sent 
      FROM post_attachments_local 
      WHERE post_id = ?
      ''',
      parameters: [postId],
    );

    _progressListeners[postId] = stream.listen((_) async {
      final progress = await _calculateUploadProgress(postId);
      _updateProgress(postId, progress);

      // Progress will be automatically removed when the post is deleted
      // from posts_local via _startWatchingPostsLocal()
    });
  }

  @override
  void dispose() {
    // Cancel all progress listeners
    for (final subscription in _progressListeners.values) {
      subscription.cancel();
    }
    _progressListeners.clear();

    // Cancel posts_local watcher
    _postsLocalWatcher?.cancel();

    super.dispose();
  }

  Future<void> uploadPost({
    required BuildContext context,
    List<MultiModeProcessedAsset>? processedAssets,
    String? content,
  }) async {
    try {
      if (processedAssets == null || processedAssets.isEmpty) {
        final postId = uuid.v4();
        try {
          await PostsController().processPostMedia(
            postId: postId,
            content: content,
          );
        } catch (_) {
          rethrow;
        }
        return;
      }

      final postId = uuid.v4();
      final progress = _addProgress(
        postId,
        processedAssets.first.processedAsset.asset,
      );

      if (progress == null) {
        Error.throwWithStackTrace(
          Exception('Error: Progress already in progress'),
          StackTrace.current,
        );
      }

      final attachmentArgs = <PostMediaArgs>[];
      final step = 1 / processedAssets.length;

      for (var i = 0; i < processedAssets.length; i++) {
        final item = processedAssets[i];

        final progressValue = (i + 1) * step;

        final originFile = await item.processedAsset.asset.toFile();

        if (originFile == null) {
          _updateProgress(postId, progressValue, hasError: true);
          Error.throwWithStackTrace(
            Exception('Error: File cannot be fetched'),
            StackTrace.current,
          );
        }

        final compressedOriginFile = await ImageUtils().compressImage(
          originFile,
          quality: 75,
        );

        log(
          'Compressed origin file: from '
          '${originFile.readAsBytesSync().length} to '
          '${compressedOriginFile.readAsBytesSync().length}',
          name: 'PostsController',
        );

        final processedAsset = item.processedAsset;

        attachmentArgs.add(
          PostMediaArgs(
            originFile: compressedOriginFile,
            displayBytes: processedAssets.length == 1
                ? item.singleModeThumbnail
                : item.multipleModeThumbnail,
            targetWidth: processedAssets.length == 1
                ? item.singleModeTargetWidth
                : item.multipleModeTargetWidth,
            targetHeight: processedAssets.length == 1
                ? item.singleModeTargetHeight
                : item.multipleModeTargetHeight,
            originalWidth: processedAsset.originalWidth,
            originalHeight: processedAsset.originalHeight,
            cropRect: processedAsset.cropRect,
          ),
        );
        // _updateProgress(postId, progressValue);
      }

      if (attachmentArgs.isEmpty) {
        _updateProgress(postId, 1, hasError: true);
        Error.throwWithStackTrace(
          Exception('Error: result is empty'),
          StackTrace.current,
        );
      }

      try {
        await PostsController().processPostMedia(
          attachmentArgs: attachmentArgs,
          postId: postId,
          content: content,
        );
        // _updateProgress(postId, 1);
        // Future<void>.delayed(
        //   const Duration(seconds: 1),
        //   () => removeProgress(postId),
        // );
      } catch (_) {
        _updateProgress(postId, 1, hasError: true);
        rethrow;
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'PostsController',
          context: ErrorDescription('Error during post upload process'),
        ),
      );
      PostsController().showError(
        context.mounted
            ? context.l10n.postUploadFailedLabel
            : 'Something went wrong',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
