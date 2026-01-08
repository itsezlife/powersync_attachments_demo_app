import 'dart:async';

import 'package:database_client/database_client.dart';
import 'package:shared/shared.dart';

/// {@template posts_repository}
/// A repository for fetching posts from the database.
/// {@endtemplate}
class PostsRepository {
  /// {@macro posts_repository}
  PostsRepository({
    required DatabaseClient databaseClient,
  }) : _databaseClient = databaseClient;

  final DatabaseClient _databaseClient;

  /// Gets the current user ID.
  String? get currentUserId => _databaseClient.currentUserId;

  /// Fetches all posts from the database.
  Future<List<Post>> fetchPosts({
    required int limit,
    required int offset,
    String? userId,
  }) async {
    try {
      return _databaseClient.fetchPosts(
        limit: limit,
        offset: offset,
        userId: userId,
      );
    } on FetchPostsFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FetchPostsFailure(error),
        stackTrace,
      );
    }
  }

  /// Creates a new post in the database.
  Future<void> createPost({
    required String id,
    String? content,
    List<Attachment> attachments = const [],
  }) async {
    try {
      return _databaseClient.createPost(
        id: id,
        content: content,
        attachments: attachments,
      );
    } on CreatePostFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        CreatePostFailure(error),
        stackTrace,
      );
    }
  }

  /// Fetches the public URL of a property image.
  ///
  /// Returns a [String] representing the public URL of the property image.
  String getPostImageUrl({
    required String imageName,
    required String postId,
    bool useHashedImageUrl = true,
    TransformOptions? transform,
  }) {
    if (imageName.startsWith('http') ||
        imageName.startsWith('https') ||
        imageName.contains('fake')) {
      return imageName;
    }
    try {
      return _databaseClient.getPublicUrl(
        name: imageName,
        storageBucket: 'post_attachments',
        path: (name) => '$postId/$name',
        transform: transform,
      );
    } on GetPublicUrlFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        GetPublicUrlFailure(error),
        stackTrace,
      );
    }
  }

  /// Deletes a post by id.
  Future<void> deletePost({required String postId}) async {
    try {
      return _databaseClient.deletePost(postId: postId);
    } on DeletePostFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        DeletePostFailure(error),
        stackTrace,
      );
    }
  }
}
