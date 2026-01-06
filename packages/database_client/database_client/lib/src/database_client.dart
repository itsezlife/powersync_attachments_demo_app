import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// {@template database_client}
/// A base Dart interface for database clients.
/// {@endtemplate}
abstract class DatabaseClient {
  /// {@macro database_client}
  DatabaseClient();

  /// The current user id.
  String? get currentUserId;

  /// Fetches the public URL for an attachment image, with optional
  /// transformations.
  String getPublicUrl({
    required String storageBucket,
    required String name,
    required String Function(String value) path,
    TransformOptions? transform,
  });

  /// Creates a post in the database.
  /// Create a post
  Future<void> createPost({
    required String id,
    String? content,
    List<Attachment> attachments = const [],
  });

  /// Delete a post by id.
  Future<void> deletePost({required String postId});

  /// Fetches posts from the database.
  Future<List<Post>> fetchPosts({
    required int limit,
    required int offset,
    String? userId,
  });
}
