import 'package:equatable/equatable.dart';

/// {@template database_client_exception}
/// Exceptions from the database client.
/// {@endtemplate}
abstract class DatabaseClientException
    with EquatableMixin
    implements Exception {
  /// {@macro database_client_exception}
  const DatabaseClientException(this.error, [this.message]);

  /// The error which was caught.
  final Object error;

  /// The message to display.
  final String? message;

  @override
  String toString() =>
      '$runtimeType: ${message != null ? '${message!}: $error' : '$error'}';

  @override
  List<Object?> get props => [error, message];
}

/// {@template get_public_url_failure}
/// Thrown when getting public URL fails.
/// {@endtemplate}
class GetPublicUrlFailure extends DatabaseClientException {
  /// {@macro get_public_url_failure}
  const GetPublicUrlFailure(super.error, [super.message]);
}

/// {@template not_authenticated_exception}
/// Thrown when not authenticated.
/// {@endtemplate}
class NotAuthenticatedException extends DatabaseClientException {
  /// {@macro not_authenticated_exception}
  const NotAuthenticatedException(super.error, [super.message]);
}

/// {@template create_post_failure}
/// Thrown when creating a post fails.
/// {@endtemplate}
class CreatePostFailure extends DatabaseClientException {
  /// {@macro create_post_failure}
  const CreatePostFailure(super.error, [super.message]);
}

/// {@template delete_post_failure}
/// Thrown when deleting a post fails.
/// {@endtemplate}
class DeletePostFailure extends DatabaseClientException {
  /// {@macro delete_post_failure}
  const DeletePostFailure(super.error, [super.message]);
}

/// {@template fetch_posts_failure}
/// Thrown when fetching posts fails.
/// {@endtemplate}
class FetchPostsFailure extends DatabaseClientException {
  /// {@macro fetch_posts_failure}
  const FetchPostsFailure(super.error, [super.message]);
}
