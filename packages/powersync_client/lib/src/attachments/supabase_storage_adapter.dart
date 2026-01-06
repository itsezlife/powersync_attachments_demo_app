// ignore_for_file: document_ignores, lines_longer_than_80_chars

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:powersync_client/powersync_client.dart' hide MultipartFile;
import 'package:powersync_client/src/attachments/uploaded_attachments_storage.dart';
import 'package:powersync_core/attachments/attachments.dart';
import 'package:shared/shared.dart' as shared;

/// {@template database_client_exception}
/// Exceptions from supabase storage adapter.
/// {@endtemplate}
abstract class SupabaseStorageAdapterException implements Exception {
  /// {@macro supabase_storage_adapter_exception}
  const SupabaseStorageAdapterException(this.error, [this.message]);

  /// The error which was caught.
  final Object error;

  /// The message to display.
  final String? message;

  @override
  String toString() => message != null ? '${message!}: $error' : '$error';
}

/// {@template upload_file_failure}
/// Thrown when uploading a file fails.
/// {@endtemplate}
final class UploadFileFailure extends SupabaseStorageAdapterException {
  /// {@macro upload_file_failure}
  const UploadFileFailure(super.error, [super.message]);
}

/// {@template upload_post_not_found_failure}
/// Thrown when uploading a post is not found.
/// {@endtemplate}
final class UploadPostNotFoundFailure extends SupabaseStorageAdapterException {
  /// {@macro upload_post_not_found_failure}
  const UploadPostNotFoundFailure(super.error, [super.message]);
}

/// {@template upload_file_not_found_failure}
/// Thrown when uploading a file is not found.
/// {@endtemplate}
final class UploadFileNotFoundFailure extends SupabaseStorageAdapterException {
  /// {@macro upload_file_not_found_failure}
  const UploadFileNotFoundFailure(super.error, [super.message]);
}

/// {@template download_file_failure}
/// Thrown when downloading a file fails.
/// {@endtemplate}
final class DownloadFileFailure extends SupabaseStorageAdapterException {
  /// {@macro download_file_failure}
  const DownloadFileFailure(super.error, [super.message]);
}

/// {@template delete_file_failure}
/// Thrown when deleting a file fails.
/// {@endtemplate}
final class DeleteFileFailure extends SupabaseStorageAdapterException {
  /// {@macro delete_file_failure}
  const DeleteFileFailure(super.error, [super.message]);
}

/// The bucket name for the attachments.
const attachmentsBucket = 'post_attachments';

/// {@template SupabaseStorageAdapter}
/// A Supabase implementation of the [RemoteStorage] interface.
/// {@endtemplate}
class SupabaseStorageAdapter implements RemoteStorage {
  /// {@macro SupabaseStorageAdapter}
  SupabaseStorageAdapter({
    required PowerSyncDatabase db,
    required UploadedAttachmentsStorage uploadedAttachmentsStorage,
  }) : _db = db,
       _uploadedAttachmentsStorage = uploadedAttachmentsStorage {
    unawaited(_pendingAttachmentsToDeleteSubscription?.cancel());
    _pendingAttachmentsToDeleteSubscription = _pendingAttachmentsToDelete.stream
        .listen(deleteFile);
  }

  final PowerSyncDatabase _db;
  final UploadedAttachmentsStorage _uploadedAttachmentsStorage;

  SupabaseClient get _supabase => Supabase.instance.client;

  final Dio _dio = Dio();

  final _pendingAttachmentsToDelete = StreamController<Attachment>.broadcast();

  StreamSubscription<Attachment>? _pendingAttachmentsToDeleteSubscription;

  final Map<String, CancelToken?> _uploadCancelTokens = {};
  final Map<String, CancelToken?> _downloadCancelTokens = {};

  // Map of deleted attachments filename to their post id
  final _deletedAttachments = <String, String>{};

  Future<void> _uploadPost({
    required String postId,
    required List<shared.Attachment> uploadedAttachments,
    required SqliteWriteContext tx,
    Map<String, dynamic>? localPostRow,
  }) async {
    // final currentLocalTime = await shared.LocalTimeUtil.getCurrentLocalTime();
    final currentLocalTime = DateTime.now().toUtc();

    localPostRow ??= await tx.get(
      '''
      SELECT * FROM posts_local WHERE id = ?
      ''',
      [postId],
    );

    await tx.execute(
      '''
      DELETE FROM posts_local WHERE id = ?
      ''',
      [postId],
    );

    await tx.get(
      '''
            INSERT INTO posts (id, user_id, content, created_at, updated_at) VALUES (?, ?, ?, ?, ?)
            RETURNING id
          ''',
      [
        postId,
        localPostRow['user_id'] as String,
        localPostRow['content'] as String,
        currentLocalTime.toIso8601String(),
        currentLocalTime.toIso8601String(),
      ],
    );

    if (uploadedAttachments case final uploadedAttachments
        when uploadedAttachments.isNotEmpty) {
      await tx.executeBatch(
        '''
            INSERT INTO post_attachments (id, post_id, type, title_link, title,
            thumb_url, text, pretext, og_scrape_url, image_url, footer_icon,
            footer, fields, fallback, color, author_name, author_link,
            author_icon, asset_url, original_width, original_height,
            file_size, mime_type, minithumbnail, created_at, updated_at) VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
            ?, ?, ?, ?)
          ''',
        [
          for (final (index, attachment) in uploadedAttachments.indexed)
            [
              attachment.id,
              postId,
              attachment.type,
              attachment.titleLink,
              attachment.title,
              attachment.thumbUrl,
              attachment.text,
              attachment.pretext,
              attachment.ogScrapeUrl,
              attachment.imageUrl ?? attachment.file!.name,
              attachment.footerIcon,
              attachment.footer,
              attachment.fields,
              attachment.fallback,
              attachment.color,
              attachment.authorName,
              attachment.authorLink,
              attachment.authorIcon,
              attachment.assetUrl,
              attachment.originalWidth,
              attachment.originalHeight,
              attachment.fileSize ?? attachment.file!.size,
              attachment.mimeType ?? attachment.file!.mediaType!.mimeType,
              if (attachment.minithumbnail case final minithumbnail?)
                jsonEncode(minithumbnail.toJson())
              else
                null,
              currentLocalTime
                  .add(Duration(seconds: index * 2))
                  .toIso8601String(),
              currentLocalTime
                  .add(Duration(seconds: index * 2))
                  .toIso8601String(),
            ],
        ],
      );
    }

    await tx.execute(
      '''
            DELETE FROM post_attachments_local WHERE post_id = ?
            ''',
      [postId],
    );

    await _uploadedAttachmentsStorage.removeUploadedAttachments(
      postId,
    );
  }

  @override
  Future<void> uploadFile(
    Stream<List<int>> fileData,
    Attachment attachment,
  ) async {
    assert(attachment.metaData != null, 'Attachment meta data is required');
    final attachmentMetaData =
        jsonDecode(attachment.metaData!) as Map<String, dynamic>;

    final postId = attachmentMetaData['post_id'] as String;
    final isUploaded = attachmentMetaData['is_uploaded'] as bool;

    dev.log('Uploading file: $attachment', name: 'SupabaseStorageAdapter');

    final storageFileName = attachment.filename;

    final localAttachmentRow = await _db.getOptional(
      '''
      SELECT * FROM post_attachments_local WHERE post_id = ? AND image_url = ?
      ''',
      [postId, storageFileName],
    );

    if (localAttachmentRow == null) {
      _pendingAttachmentsToDelete.add(attachment);
      Error.throwWithStackTrace(
        UploadFileNotFoundFailure(
          'File $storageFileName not found',
        ),
        StackTrace.current,
      );
    }

    if (isUploaded) {
      final localAttachmentRowJson = Map<String, dynamic>.from(
        localAttachmentRow,
      );
      final minithumbnail = await compute((data) {
        assert(data != null, "Minithumbnail can't be null");
        return jsonDecode(data as String) as Map<String, dynamic>;
      }, localAttachmentRowJson['minithumbnail']);

      localAttachmentRowJson['minithumbnail'] = minithumbnail;

      final uploadedLocalAttachment = shared.Attachment.fromJson(
        localAttachmentRowJson,
      );

      final uploadedAttachments = await _uploadedAttachmentsStorage
          .addUploadedAttachments(
            postId: postId,
            attachments: [uploadedLocalAttachment],
          );

      await _db.writeTransaction((tx) async {
        final existingLocalAttachments = await tx.getOptional(
          '''
        SELECT COUNT(*) as count FROM post_attachments_local WHERE post_id = ?
        ''',
          [postId],
        );

        final existingLocalAttachmentsCount =
            existingLocalAttachments!['count'] as int;

        dev.log(
          'Existing local attachments count: $existingLocalAttachmentsCount',
          name: 'SupabaseStorageAdapter.uploaded',
        );
        dev.log(
          'Uploaded attachments count: ${uploadedAttachments.length}',
          name: 'SupabaseStorageAdapter.uploaded',
        );

        final leftAttachmentsCount =
            existingLocalAttachmentsCount - uploadedAttachments.length;

        dev.log(
          'Left attachments count: $leftAttachmentsCount',
          name: 'SupabaseStorageAdapter.uploaded',
        );

        if (leftAttachmentsCount == 0) {
          await _uploadPost(
            tx: tx,
            postId: postId,
            uploadedAttachments: uploadedAttachments,
          );
        }
      });

      return;
    }

    final cancelToken = CancelToken();
    _uploadCancelTokens[storageFileName] = cancelToken;

    // Check if attachment size is specified (required for buffer allocation)
    final byteSize = attachment.size;
    if (byteSize == null) {
      throw Exception('Cannot upload a file with no byte size specified');
    }

    dev.log(
      'uploadFile: ${attachment.filename} (size: $byteSize bytes)',
      name: 'SupabaseStorageAdapter',
    );

    // Collect all stream data into a single Uint8List buffer
    final buffer = Uint8List(byteSize);
    var position = 0;

    await for (final chunk in fileData) {
      if (position + chunk.length > byteSize) {
        throw Exception('File data exceeds specified size');
      }
      buffer.setRange(position, position + chunk.length, chunk);
      position += chunk.length;
    }

    if (position != byteSize) {
      throw Exception(
        'File data size ($position) does not match specified size ($byteSize)',
      );
    }

    try {
      final minithumbnailRawJson =
          attachmentMetaData['minithumbnail'] as String;
      final minithumbnail = shared.Minithumbnail.fromJson(
        jsonDecode(minithumbnailRawJson) as Map<String, dynamic>,
      );

      final url =
          '${_supabase.storage.url}/object/$attachmentsBucket/$postId/$storageFileName';

      // Create multipart form data to match Supabase's expected format
      final formData = FormData();

      // Add required Supabase fields
      formData.fields.add(const MapEntry('cacheControl', '3600'));

      final headers = {
        'Authorization': 'Bearer ${shared.Config.getEnv(Env.supabaseAnonKey)}',
        'x-upsert': 'true',
        ..._supabase.storage.from(attachmentsBucket).headers,
      };

      final contentType = attachment.filename.mediaType;

      // Add the file as multipart
      final multipartFile = MultipartFile.fromBytes(
        buffer,
        filename: storageFileName,
        contentType: contentType,
      );
      formData.files.add(MapEntry('', multipartFile));

      await _dio.post<dynamic>(
        url,
        data: formData,
        options: Options(
          headers: headers,
          contentType: contentType!.mimeType,
        ),
        cancelToken: cancelToken,
        onSendProgress: (count, total) async {
          await _db.execute(
            '''
              UPDATE post_attachments_local 
              SET sent = ?, file_size = ? WHERE image_url = ? AND post_id = ?
            ''',
            [count, total, storageFileName, postId],
          );
        },
      );

      _uploadCancelTokens.remove(storageFileName);

      await _db.writeTransaction(
        (tx) async {
          final existingLocalAttachments = await tx.getOptional(
            '''
            SELECT COUNT(*) as count FROM post_attachments_local
            WHERE post_id = ?
            ''',
            [postId],
          );

          final existingQueueAttachments = await tx.getOptional(
            '''
            SELECT COUNT(*) as count FROM ${AttachmentsQueueTable.defaultTableName}
            WHERE post_id = ?
            ''',
            [postId],
          );

          dev.log('Existing queue attachments: $existingQueueAttachments');

          dev.log('Existing local attachments: $existingLocalAttachments');

          final localPostRow = await tx.getOptional(
            '''
            SELECT * FROM posts_local WHERE id = ?
            ''',
            [postId],
          );

          if (localPostRow == null) {
            _pendingAttachmentsToDelete.add(attachment);
            Error.throwWithStackTrace(
              UploadPostNotFoundFailure(
                'Post $postId not found (filename: $storageFileName)',
              ),
              StackTrace.current,
            );
          }

          final localAttachment = shared.Attachment.fromJson(
            localAttachmentRow,
          );

          final uploadedAttachment = localAttachment.copyWith(
            id: shared.uuid.v4(),
            minithumbnail: minithumbnail,
            mimeType: contentType.mimeType,
          );

          final uploadedAttachments = await _uploadedAttachmentsStorage
              .addUploadedAttachments(
                postId: postId,
                attachments: [uploadedAttachment],
              );

          dev.log(
            'Uploaded attachments(${uploadedAttachments.length}): '
            '${uploadedAttachments.map((e) => e.toJson()).join(', ')}',
          );

          var leftAttachments =
              (existingLocalAttachments!['count'] as int) -
              uploadedAttachments.length;

          final deletedAttachments = _deletedAttachments.entries
              .where((entry) => entry.value == postId)
              .map((entry) => entry.key)
              .toList();

          dev.log(
            'Deleted attachments: $deletedAttachments',
          );

          leftAttachments -= deletedAttachments.length;

          dev.log(
            'Left attachments: $leftAttachments by post id: $postId',
          );

          if (leftAttachments == 0) {
            await _uploadPost(
              tx: tx,
              postId: postId,
              localPostRow: localPostRow,
              uploadedAttachments: uploadedAttachments,
            );
          }
        },
      );
    } on DioException catch (error, stackTrace) {
      dev.log(
        'UploadFileFailure: ${error.response?.data ?? error}',
        name: 'SupabaseStorageAdapter',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(
        UploadFileFailure(
          error.response?.data as Object? ?? error,
          error.message,
        ),
        stackTrace,
      );
    } on UploadFileNotFoundFailure {
      rethrow;
    } on UploadPostNotFoundFailure {
      rethrow;
    } catch (error, stackTrace) {
      dev.log(
        'UploadFileFailure',
        name: 'SupabaseStorageAdapter',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(UploadFileFailure(error), stackTrace);
    }
  }

  @override
  Future<Stream<List<int>>> downloadFile(Attachment attachment) async {
    try {
      final cancelToken = CancelToken();
      _downloadCancelTokens[attachment.filename] = cancelToken;

      final fileBlob = await _supabase.storage
          .from(attachmentsBucket)
          .download(attachment.filename);

      return Stream.value(fileBlob);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(DownloadFileFailure(error), stackTrace);
    }
  }

  Future<void> _onDeleteAttachment({
    required String storageFileName,
    required String postId,
  }) async {
    await _db.writeTransaction((tx) async {
      final localPostRow = await tx.getOptional(
        '''
            SELECT * FROM posts_local WHERE id = ?
          ''',
        [postId],
      );

      if (localPostRow != null) {
        final existingLocalAttachments = await tx.getOptional(
          '''
            SELECT COUNT(*) as count FROM post_attachments_local
            WHERE post_id = ?
            ''',
          [postId],
        );

        final uploadedAttachments = _uploadedAttachmentsStorage
            .getUploadedAttachments(postId);

        final existingLocalAttachmentsCount =
            existingLocalAttachments!['count'] as int;

        final leftAttachments =
            existingLocalAttachmentsCount - uploadedAttachments.length;

        if (leftAttachments == 0 && existingLocalAttachmentsCount != 0) {
          await _uploadPost(
            tx: tx,
            postId: postId,
            localPostRow: localPostRow,
            uploadedAttachments: uploadedAttachments,
          );
        }
      }
    });
  }

  @override
  Future<void> deleteFile(Attachment attachment) async {
    final storageFileName = attachment.filename;
    dev.log(
      'Deleting attachment: $attachment, '
      'upload cancel tokens: $_uploadCancelTokens',
      name: 'SupabaseStorageAdapter',
    );
    _uploadCancelTokens[storageFileName]?.cancel();
    _uploadCancelTokens.remove(storageFileName);

    await _uploadedAttachmentsStorage.removeUploadedAttachmentById(
      storageFileName,
    );

    final attachmentMetaData =
        jsonDecode(attachment.metaData!) as Map<String, dynamic>;
    final postId = attachmentMetaData['post_id'] as String;

    _deletedAttachments[storageFileName] = postId;

    unawaited(
      _onDeleteAttachment(
        storageFileName: storageFileName,
        postId: postId,
      ),
    );

    try {
      final existingRemoteAttachmentsWithSameName = await _db.getOptional(
        '''
          SELECT COUNT(*) as count FROM attachments
          WHERE image_url = ?
          ''',
        [storageFileName],
      );

      final existingRemoteAttachmentsWithSameNameCount =
          existingRemoteAttachmentsWithSameName?['count'] as int? ?? 0;

      if (existingRemoteAttachmentsWithSameNameCount != 0) {
        dev.log(
          "Don't delete file, remote attachments with same name "
          '$storageFileName found: $existingRemoteAttachmentsWithSameNameCount',
          name: 'SupabaseStorageAdapter',
        );
        return;
      }

      await Supabase.instance.client.storage.from(attachmentsBucket).remove([
        storageFileName,
      ]);

      dev.log(
        'File deleted: $storageFileName',
        name: 'SupabaseStorageAdapter',
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(DeleteFileFailure(error), stackTrace);
    }
  }
}
