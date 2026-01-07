// ignore_for_file: lines_longer_than_80_chars

import 'package:bloc/bloc.dart' hide Change;
import 'package:diffutil_dart/diffutil.dart';
import 'package:powersync_attachments_example/src/user_profile/bloc/user_profile_bloc.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared/shared.dart';

enum DiffUpdateType { insert, remove, change, move }

bool _arePostsSame(Post oldPost, Post newPost) =>
    oldPost.content == newPost.content &&
    oldPost.createdAt.millisecondsSinceEpoch ==
        newPost.createdAt.millisecondsSinceEpoch &&
    oldPost.updatedAt.millisecondsSinceEpoch ==
        newPost.updatedAt.millisecondsSinceEpoch &&
    _areAttachmentListsSame(oldPost.attachments, newPost.attachments);

bool _areAttachmentListsSame(
  List<Attachment> oldAttachments,
  List<Attachment> newAttachments,
) {
  // If lengths are different, they're not the same
  if (oldAttachments.length != newAttachments.length) {
    return false;
  }

  // If both are empty, they're the same
  if (oldAttachments.isEmpty && newAttachments.isEmpty) {
    return true;
  }

  // For ordered comparison, check each attachment at the same index
  for (var i = 0; i < oldAttachments.length; i++) {
    if (!_areAttachmentsSame(oldAttachments[i], newAttachments[i])) {
      return false;
    }
  }

  return true;
}

bool _areAttachmentsSame(Attachment oldAttachment, Attachment newAttachment) =>
    oldAttachment.type == newAttachment.type &&
    oldAttachment.imageUrl == newAttachment.imageUrl &&
    oldAttachment.uploadState == newAttachment.uploadState;

List<DiffUpdate> calculatePostsChangesDiff(List<dynamic> args) {
  final oldList = args[0] as List<Post>;
  final newList = args[1] as List<Post>;
  final excludedDiffs = args[2] as List<DiffUpdateType>;

  // This algorithm assumes the `Message` class has a correct implementation
  // of `operator==` and `hashCode`. If not, it will fail to detect
  // matches and produce incorrect diffs.

  final updates = <DiffUpdate>[];

  if (!excludedDiffs.contains(DiffUpdateType.insert)) {
    if (oldList.isEmpty && newList.isNotEmpty) {
      for (var i = 0; i < newList.length; i++) {
        updates.add(Insert(position: i, count: 1));
      }
      return updates;
    }
  }

  // Create ID to position maps for quick lookups.
  // This is crucial for correctly identifying pure inserts and deletes.
  final oldIdToPos = <String, int>{};
  for (var i = 0; i < oldList.length; i++) {
    oldIdToPos[oldList[i].id] = i;
  }

  var oldPos = oldList.length - 1;
  var newPos = newList.length - 1;

  while (oldPos >= 0 || newPos >= 0) {
    // Case 1: We've run out of old messages, any remaining new ones are inserts.
    if (oldPos < 0) {
      if (!excludedDiffs.contains(DiffUpdateType.insert)) {
        updates.add(Insert(position: 0, count: newPos + 1));
      }
      break;
    }

    // Case 2: We've run out of new messages, any remaining old ones are deletes.
    if (newPos < 0) {
      if (!excludedDiffs.contains(DiffUpdateType.remove)) {
        for (var i = oldPos; i >= 0; i--) {
          // Don't detect removal if the message is localOnly
          if (!oldList[i].localOnly) {
            updates.add(Remove(position: i, count: 1));
          }
        }
      }
      break;
    }

    final oldPost = oldList[oldPos];
    final newPost = newList[newPos];

    // Case 3: The IDs match. The items are in the same relative position.
    // This is the path that should be taken for your "update at index 100" scenario.
    if (oldPost.id == newPost.id) {
      // Now, check if the content has actually changed.
      // This relies on your `Message.operator==` implementation.
      if (!_arePostsSame(oldPost, newPost) &&
          !excludedDiffs.contains(DiffUpdateType.change)) {
        // if (oldPost.localOnly && newPost.isDeleted) {
        //   updates.add(Remove(position: oldPos, count: 1));
        // } else {
        updates.add(
          Change(
            position: oldPos,
            payload: {'old_message': oldPost, 'new_message': newPost},
          ),
        );
        // }
      }
      oldPos--;
      newPos--;
    } else {
      // Case 4: The IDs at the current positions do not match.
      // We must determine if this is an insert, a delete, or an impossible state.
      final isNewItemInOldList = oldIdToPos.containsKey(newPost.id);

      // If the new message's ID does NOT exist in the old list, it's a pure insert.
      if (!isNewItemInOldList) {
        if (!excludedDiffs.contains(DiffUpdateType.insert)) {
          updates.add(Insert(position: newPos, count: 1));
        }
        newPos--; // Only consume the new list's item and re-evaluate oldPos.
      } else {
        // Otherwise, the old message must have been deleted.
        // Since moves are impossible, we can assume this is a removal.
        // Don't detect removal if the message is localOnly
        if (!excludedDiffs.contains(DiffUpdateType.remove) &&
            !oldPost.localOnly) {
          updates.add(Remove(position: oldPos, count: 1));
        }
        oldPos--; // Only consume the old list's item and re-evaluate newPos.
      }
    }
  }

  // The updates were added in reverse order, so we must reverse the list
  // to apply them from start to finish.
  return updates.reversed.toList();
}

mixin PostsDatabaseMixin on Bloc<UserProfileEvent, UserProfileState> {
  /// The stream notifying the state of [_subscribeToChanges] call
  Stream<DataDiffUpdate<Post>?> get postsChanges =>
      postsChangesController.stream;

  /// The stream notifying the state of [postsChanges] call
  final postsChangesController = BehaviorSubject<DataDiffUpdate<Post>?>.seeded(
    null,
  );

  String postsQuery({
    required bool local,
    String? andWhereClause,
    int? limit,
    bool orderByDesc = true,
  }) {
    if (!local) {
      return '''
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
        WHERE p.user_id = ?1 ${andWhereClause ?? ''}
        ORDER BY p.created_at ${orderByDesc ? 'DESC' : 'ASC'}
        ${limit != null ? 'LIMIT ?2' : ''}
      ''';
    }
    return '''
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
          ${local ? "'sent', a.sent," : ""}
          'updated_at', a.updated_at
        )
        ORDER BY a.created_at ASC
      ) FROM ${local ? 'post_attachments_local' : 'post_attachments'} a WHERE a.post_id = p.id),
      '[]'
    ) as attachments,
      json_object(
        'id', s.id,
        'name', s.name,
        'avatar_url', s.avatar_url
      ) as author
      FROM ${local ? 'posts_local' : 'posts'} p
      LEFT JOIN users s ON p.user_id = s.id
      WHERE p.user_id = ?1 ${andWhereClause ?? ''}
      GROUP BY p.id
      ORDER BY p.created_at ${orderByDesc ? 'DESC' : 'ASC'}
      ${limit != null ? 'LIMIT ?2' : ''}
    ''';
  }

  @override
  Future<void> close() {
    postsChangesController.close();
    return super.close();
  }
}
