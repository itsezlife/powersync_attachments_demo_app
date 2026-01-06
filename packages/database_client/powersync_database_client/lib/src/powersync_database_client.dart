import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:database_client/database_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:powersync_client/powersync_client.dart';
import 'package:shared/shared.dart' as shared show Attachment;
import 'package:shared/shared.dart' hide Attachment;

/// {@template wait_for_sync_exception}
/// Thrown when waiting for sync fails.
/// {@endtemplate}
class WaitForSyncException extends DatabaseClientException {
  /// {@macro wait_for_sync_exception}
  const WaitForSyncException(super.error, [super.message]);
}

/// {@template powersync_database_client}
/// A PowerSync database implementation of the base DatabaseClient interface.
/// {@endtemplate}
class PowerSyncDatabaseClient extends DatabaseClient {
  /// {@macro powersync_database_client}
  PowerSyncDatabaseClient({required PowerSyncClient powerSyncClient})
    : _powerSyncClient = powerSyncClient;

  final PowerSyncClient _powerSyncClient;

  @override
  String? get currentUserId =>
      _powerSyncClient.supabase.auth.currentSession?.user.id;

  @override
  String getPublicUrl({
    required String storageBucket,
    required String name,
    required String Function(String value) path,
    TransformOptions? transform,
  }) {
    try {
      final url = _powerSyncClient.getPublicUrl(
        storageBucket: storageBucket,
        name: name,
        path: path,
        transform: transform,
      );
      return url;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(GetPublicUrlFailure(error), stackTrace);
    }
  }

  @override
  Future<void> createPost({
    required String id,
    String? content,
    List<shared.Attachment> attachments = const [],
  }) async {
    try {
      final userId = currentUserId;
      if (currentUserId == null) {
        Error.throwWithStackTrace(
          const NotAuthenticatedException(
            'User is not authenticated to create a post',
          ),
          StackTrace.current,
        );
      }

      final postTable = attachments.isEmpty ? 'posts' : 'posts_local';

      final currentLocalTime = DateTime.now().toUtc();

      await _powerSyncClient.db().writeTransaction(
        (tx) async {
          final postRow = await tx.get(
            '''
            INSERT INTO $postTable (id, user_id, content, created_at, updated_at) VALUES (?, ?, ?, ?, ?)
            RETURNING id
          ''',
            [
              id,
              userId,
              content,
              currentLocalTime.toIso8601String(),
              currentLocalTime.toIso8601String(),
            ],
          );

          if (attachments case final attachments when attachments.isNotEmpty) {
            await tx.executeBatch(
              '''
            INSERT INTO post_attachments_local (id, post_id, type, title_link, title,
            thumb_url, text, pretext, og_scrape_url, image_url, footer_icon,
            footer, fields, fallback, color, author_name, author_link,
            author_icon, asset_url, original_width, original_height,
            file_size, mime_type, minithumbnail, created_at, updated_at) VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
            ?, ?, ?, ?)
          ''',
              [
                for (final (index, attachment) in attachments.indexed)
                  [
                    attachment.id,
                    postRow['id'],
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
        },
      );

      if (attachments case final attachments when attachments.isNotEmpty) {
        final minithumbnailsFutures = attachments.map((e) async {
          if (e.minithumbnail != null) {
            return e.minithumbnail;
          }
          return compute(generateMinithumbnail, {'image': e.file!.bytes});
        }).toList();

        final minithumbnails = await minithumbnailsFutures.waitWithStrategy(
          ParallelWaitOptions(
            onError: (index, error, stackTrace) {
              final attachment = attachments[index];
              dev.log(
                'Failed to process minithumbnail for $attachment',
              );
            },
          ),
        );

        for (final (index, attachment) in attachments.indexed) {
          final minithumbnail = minithumbnails.all[index];
          assert(
            minithumbnail != null,
            'Minithumbnail is null for attachment $attachment',
          );

          final file = attachment.file;
          assert(
            file != null,
            'File is null for attachment $attachment',
          );

          await _powerSyncClient.saveAttachment(
            data: File(file!.path!).openRead(),
            file: file,
            postId: id,
            attachmentId: attachment.imageUrl?.removeExtension,
            isUploaded: attachment.uploadState.isSuccess,
            minithumbnail: minithumbnail,
          );
        }
      }
    } on NotAuthenticatedException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(CreatePostFailure(error), stackTrace);
    }
  }

  @override
  Future<void> deletePost({required String postId}) async {
    try {
      final userId = currentUserId;
      if (currentUserId == null) {
        Error.throwWithStackTrace(
          const NotAuthenticatedException(
            'User is not authenticated to delete a post',
          ),
          StackTrace.current,
        );
      }

      await _powerSyncClient.db().writeTransaction(
        (tx) async {
          await tx.execute(
            'DELETE FROM posts WHERE id = ? AND user_id = ?',
            [postId, userId],
          );

          await tx.execute(
            'DELETE FROM post_attachments WHERE post_id = ?',
            [postId],
          );
        },
      );
    } on NotAuthenticatedException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(DeletePostFailure(error), stackTrace);
    }
  }

  static List<List<Map<String, dynamic>>?> _computeJsonListAttachments(
    List<dynamic> args,
  ) {
    final rootToken = args[0] as RootIsolateToken;
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    final jsonListAttachments = args[1] as List<String?>;
    if (jsonListAttachments.isEmpty) return [];

    final listAttachments = jsonListAttachments
        .map(
          (jsonAttachment) =>
              jsonAttachment == null ||
                        jsonAttachment.isEmpty ||
                        jsonAttachment == 'null'
                    ? null
                    : (jsonDecode(jsonAttachment) as List<dynamic>)
                          .cast<Map<String, dynamic>>()
                ?..removeWhere((e) => e['id'] == null)
                ..forEach((attachment) {
                  if (attachment['minithumbnail']
                      case final String minithumbnail
                      when minithumbnail.isNotEmpty) {
                    attachment['minithumbnail'] =
                        jsonDecode(minithumbnail) as Map<String, dynamic>;
                  }
                }),
        )
        .toList();

    return listAttachments;
  }

  static List<Map<String, dynamic>?> _computeJsonListAuthor(
    List<dynamic> args,
  ) {
    final rootToken = args[0] as RootIsolateToken;
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    final jsonListAuthor = args[1] as List<String?>;
    final listAuthor = <Map<String, dynamic>?>[];
    for (final jsonAuthor in jsonListAuthor) {
      if (jsonAuthor == null || jsonAuthor.isEmpty) {
        listAuthor.add(null);
        continue;
      }
      final json = jsonDecode(jsonAuthor) as Map<String, dynamic>;
      if (json['id'] == null) {
        listAuthor.add(null);
        continue;
      }
      listAuthor.add(json);
    }
    return listAuthor;
  }

  Future<List<Post>> _parsePosts(
    List<Map<String, dynamic>> result,
  ) async {
    final jsonListAttachments = result.map((row) {
      final json = Map<String, dynamic>.from(row);
      return json['attachments'] as String?;
    }).toList();

    final rootToken = RootIsolateToken.instance!;
    final listAttachments = await compute(
      _computeJsonListAttachments,
      [rootToken, jsonListAttachments],
    );

    final jsonListAuthor = result.map((row) {
      final json = Map<String, dynamic>.from(row);
      return json['author'] as String?;
    }).toList();

    final listAuthor = await compute(
      _computeJsonListAuthor,
      [rootToken, jsonListAuthor],
    );

    final posts = <Post>[];
    for (var i = 0; i < result.length; i++) {
      final json = Map<String, dynamic>.from(result[i]);
      final attachments = listAttachments[i];
      json['attachments'] = attachments;

      final authorJson = listAuthor[i];
      if (authorJson != null) {
        json['author'] = authorJson;
      }

      final post = Post.fromJson(json);

      posts.add(post);
    }
    return posts;
  }

  @override
  Future<List<Post>> fetchPosts({
    required int limit,
    required int offset,
    String? userId,
  }) async {
    try {
      return _powerSyncClient.waitForSync(() async {
        final posts = await _powerSyncClient.db().execute(
          '''
        SELECT p.id, p.user_id, p.content, p.created_at, p.updated_at,
        COALESCE(
        (SELECT json_group_array(
          json_object(
            'id', a.id,
            'post_id', a.post_id,
            'type', a.type,
            'title_link', a.title_link,
            'title', a.title,
            'thumb_url', a.thumb_url,
            'text', a.text,
            'pretext', a.pretext,
            'og_scrape_url', a.og_scrape_url,
            'image_url', a.image_url,
            'footer_icon', a.footer_icon,
            'footer', a.footer,
            'fields', a.fields,
            'fallback', a.fallback,
            'color', a.color,
            'author_name', a.author_name,
            'author_link', a.author_link,
            'author_icon', a.author_icon,
            'asset_url', a.asset_url,
            'actions', a.actions,
            'original_width', a.original_width,
            'original_height', a.original_height,
            'file_size', a.file_size,
            'mime_type', a.mime_type,
            'created_at', a.created_at,
            'minithumbnail', a.minithumbnail,
            'updated_at', a.updated_at
          )
          ORDER BY a.created_at ASC
        ) FROM post_attachments a WHERE a.post_id = p.id),
        '[]'
      ) as attachments,
        json_object(
          'id', s.id,
          'name', s.name,
          'avatar_url', s.avatar_url
        ) as author
        FROM posts p
        LEFT JOIN users s ON p.user_id = s.id
        WHERE p.user_id = ?
        ORDER BY p.created_at DESC
        LIMIT ? OFFSET ?
        ''',
          [userId, limit, offset],
        );
        return _parsePosts(posts);
      });
    } on NotAuthenticatedException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(FetchPostsFailure(error), stackTrace);
    }
  }
}
