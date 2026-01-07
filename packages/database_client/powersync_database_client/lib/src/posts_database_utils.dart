import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';

/// {@template posts_database_utils}
/// Utility class for posts database operations.
/// {@endtemplate}
abstract class PostsDatabaseUtils {
  /// {@macro posts_database_utils}
  const PostsDatabaseUtils();

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

  /// Parses the posts from the result of a database query in the Isolate.
  static Future<List<Post>> parsePosts(
    List<Map<String, dynamic>> result, {
    bool local = false,
    String Function(String postId, String attachmentName)?
    getAttachmentImageUrl,
  }) async {
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

      var post = Post.fromJson(json).copyWith(localOnly: local);

      if (getAttachmentImageUrl != null) {
        final updatedAttachments = post.attachments.map((attachment) {
          if (attachment.imageUrl case final imageUrl?
              when imageUrl.isNotEmpty) {
            return attachment.copyWith(
              imageUrl: getAttachmentImageUrl(post.id, imageUrl),
            );
          }
          return attachment;
        }).toList();

        post = post.copyWith(attachments: updatedAttachments);
      }

      posts.add(post);
    }
    return posts;
  }
}
