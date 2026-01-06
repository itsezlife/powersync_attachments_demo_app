// ignore_for_file: document_ignores

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared/shared.dart' as shared;
import 'package:storage/storage.dart';

/// Keys for the uploaded attachments storage.
sealed class UploadedAttachmentsStorageKeys {
  /// Key for the uploaded attachments.
  static const uploadedAttachments = '__uploaded_attachments_key__';
}

/// {@template uploaded_attachments_storage_exception}
/// Exception thrown when uploaded attachments storage operation fails.
/// {@endtemplate}
abstract class UploadedAttachmentsStorageException implements Exception {
  /// {@macro uploaded_attachments_storage_exception}
  const UploadedAttachmentsStorageException(this.error, [this.message]);

  /// The error which was caught.
  final Object error;

  /// The message to display.
  final String? message;

  @override
  String toString() => message != null ? '${message!}: $error' : '$error';
}

/// {@template get_uploaded_attachments_failure}
/// Thrown when getting uploaded attachments fails.
/// {@endtemplate}
final class GetUploadedAttachmentsFailure
    extends UploadedAttachmentsStorageException {
  /// {@macro get_uploaded_attachments_failure}
  const GetUploadedAttachmentsFailure(super.error, [super.message]);
}

/// {@template save_uploaded_attachment_failure}
/// Thrown when saving uploaded attachment fails.
/// {@endtemplate}
final class SaveUploadedAttachmentFailure
    extends UploadedAttachmentsStorageException {
  /// {@macro save_uploaded_attachment_failure}
  const SaveUploadedAttachmentFailure(super.error, [super.message]);
}

/// {@template remove_uploaded_attachment_failure}
/// Thrown when removing uploaded attachment fails.
/// {@endtemplate}
final class RemoveUploadedAttachmentFailure
    extends UploadedAttachmentsStorageException {
  /// {@macro remove_uploaded_attachment_failure}
  const RemoveUploadedAttachmentFailure(super.error, [super.message]);
}

/// {@template uploaded_attachments_storage}
/// Storage for managing uploaded attachments in the SupabaseStorageAdapter.
///
/// This storage manages successfully uploaded attachments.
/// {@endtemplate}
class UploadedAttachmentsStorage {
  /// {@macro uploaded_attachments_storage}
  UploadedAttachmentsStorage({
    required ListStorage storage,
  }) : _storage = storage {
    unawaited(_init());
  }

  final ListStorage _storage;

  final _uploadedAttachmentsStreamController =
      BehaviorSubject<Map<String, List<shared.Attachment>>>.seeded({});

  Future<List<String>?> _getValue(String key) => _storage.read(key: key);
  Future<void> _setValue(List<String> value, String key) => _storage.write(
    key: key,
    value: value,
  );

  Future<void> _init() async {
    try {
      // Load uploaded attachments
      final uploadedAttachmentsData = await _getValue(
        UploadedAttachmentsStorageKeys.uploadedAttachments,
      );
      if (uploadedAttachmentsData != null) {
        final uploadedAttachments = await compute(
          (data) {
            final result = <String, List<shared.Attachment>>{};
            for (final item in data) {
              final json = jsonDecode(item) as Map<String, dynamic>;
              final postId = json['post_id'] as String;
              final attachments = (json['attachments'] as List)
                  .map(
                    (e) =>
                        shared.Attachment.fromJson(e as Map<String, dynamic>),
                  )
                  .toList();
              result[postId] = attachments;
            }
            return result;
          },
          uploadedAttachmentsData,
        );
        _uploadedAttachmentsStreamController.add(uploadedAttachments);
      }
    } catch (error, stackTrace) {
      log(
        'Failed to initialize uploaded attachments storage: $error',
        name: 'UploadedAttachmentsStorage',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Adds uploaded attachments for a post.
  Future<List<shared.Attachment>> addUploadedAttachments({
    required String postId,
    required List<shared.Attachment> attachments,
  }) async {
    try {
      final currentAttachments = _uploadedAttachmentsStreamController.value;
      currentAttachments[postId] = [
        ...(currentAttachments[postId] ?? []),
        ...attachments,
      ];

      await _setValue(
        currentAttachments.entries
            .map(
              (entry) => jsonEncode({
                'post_id': entry.key,
                'attachments': entry.value.map((e) => e.toJson()).toList(),
              }),
            )
            .toList(),
        UploadedAttachmentsStorageKeys.uploadedAttachments,
      );

      _uploadedAttachmentsStreamController.add(currentAttachments);

      return currentAttachments[postId]!;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SaveUploadedAttachmentFailure(
          'Failed to add uploaded attachments for post $postId: $error',
        ),
        stackTrace,
      );
    }
  }

  /// Removes uploaded attachments for a post.
  Future<void> removeUploadedAttachments(String postId) async {
    try {
      final currentAttachments = _uploadedAttachmentsStreamController.value
        ..remove(postId);

      await _setValue(
        currentAttachments.entries
            .map(
              (entry) => jsonEncode({
                'post_id': entry.key,
                'attachments': entry.value.map((e) => e.toJson()).toList(),
              }),
            )
            .toList(),
        UploadedAttachmentsStorageKeys.uploadedAttachments,
      );

      _uploadedAttachmentsStreamController.add(currentAttachments);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        RemoveUploadedAttachmentFailure(
          'Failed to remove uploaded attachments for post $postId: $error',
        ),
        stackTrace,
      );
    }
  }

  /// Removes uploaded attachments for a post.
  Future<void> removeUploadedAttachmentById(String attachmentUrl) async {
    try {
      final currentAttachments = _uploadedAttachmentsStreamController.value
        ..removeWhere(
          (entry, value) => value.any((e) => e.imageUrl == attachmentUrl),
        );

      await _setValue(
        currentAttachments.entries
            .map(
              (entry) => jsonEncode({
                'post_id': entry.key,
                'attachments': entry.value.map((e) => e.toJson()).toList(),
              }),
            )
            .toList(),
        UploadedAttachmentsStorageKeys.uploadedAttachments,
      );

      _uploadedAttachmentsStreamController.add(currentAttachments);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        RemoveUploadedAttachmentFailure(
          'Failed to remove uploaded attachments '
          'for attachment $attachmentUrl: $error',
        ),
        stackTrace,
      );
    }
  }

  /// Gets uploaded attachments for a specific post.
  List<shared.Attachment> getUploadedAttachments(String postId) {
    return _uploadedAttachmentsStreamController.value[postId] ?? [];
  }

  /// Gets all uploaded attachments.
  Map<String, List<shared.Attachment>> getAllUploadedAttachments() {
    return Map.from(_uploadedAttachmentsStreamController.value);
  }

  /// Provides a stream of uploaded attachments for a specific post.
  Stream<List<shared.Attachment>> uploadedAttachmentsFor(String postId) {
    return _uploadedAttachmentsStreamController.stream.map(
      (attachments) => attachments[postId] ?? [],
    );
  }

  /// Provides a stream of all uploaded attachments.
  Stream<Map<String, List<shared.Attachment>>> uploadedAttachments() =>
      _uploadedAttachmentsStreamController.stream;

  /// Clears all stored data and resets the streams.
  Future<void> clearStorage() async {
    try {
      _uploadedAttachmentsStreamController.add({});

      await _setValue([], UploadedAttachmentsStorageKeys.uploadedAttachments);
    } catch (error, stackTrace) {
      log(
        'Failed to clear uploaded attachments storage: $error',
        name: 'UploadedAttachmentsStorage',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Disposes the storage and closes all streams.
  void dispose() {
    unawaited(_uploadedAttachmentsStreamController.close());
  }
}
