import 'package:authentication_client/authentication_client.dart';
import 'package:database_client/database_client.dart';
import 'package:powersync_client/powersync_client.dart';
import 'package:user_repository/user_repository.dart';

/// {@template user_repository}
/// A package that manages user flow.
/// {@endtemplate}
class UserRepository {
  /// {@macro user_repository}
  const UserRepository({
    required AuthenticationClient authenticationClient,
    required DatabaseClient databaseClient,
  }) : _authenticationClient = authenticationClient,
       _databaseClient = databaseClient;

  final DatabaseClient _databaseClient;
  final AuthenticationClient _authenticationClient;

  /// Current user id.
  String? get currentUserId => _authenticationClient.currentUserId;

  /// Stream of [User] which will emit the current user when
  /// the authentication state changes.
  Stream<User> get user =>
      _authenticationClient.user.map(User.fromAuthenticationUser);

  /// Stream of [AuthState] which will emit the current authentication state.
  Stream<AuthState> get authStateChange =>
      _authenticationClient.authStateChange;

  /// Updates the user's metadata.
  Future<void> updateUser({
    String? email,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      return _authenticationClient.updateUser(
        email: email,
        name: name,
        avatarUrl: avatarUrl,
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        UpdateUserFailure(error),
        stackTrace,
      );
    }
  }

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [LogInWithGoogleCanceled] if the flow is canceled by the user.
  /// Throws a [LogInWithGoogleFailure] if an exception occurs.
  Future<void> logInWithGoogle() async {
    try {
      await _authenticationClient.logInWithGoogle();
    } on LogInWithGoogleFailure {
      rethrow;
    } on LogInWithGoogleCanceled {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LogInWithGoogleFailure(error),
        stackTrace,
      );
    }
  }

  /// Signs out the current user which will emit
  /// [User.anonymous] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  Future<void> logOut() async {
    try {
      await _authenticationClient.logOut();
    } on LogOutFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LogOutFailure(error),
        stackTrace,
      );
    }
  }

  /// Logins in with the provided [password].
  Future<void> logInWithPassword({
    required String password,
    String? email,
    String? phone,
  }) async {
    try {
      await _authenticationClient.logInWithPassword(
        email: email,
        phone: phone,
        password: password,
      );
    } on LogInWithPasswordFailure {
      rethrow;
    } on LogInWithPasswordCanceled {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LogInWithPasswordFailure(error),
        stackTrace,
      );
    }
  }

  /// Sign up with the provided [password].
  Future<void> signUpWithPassword({
    required String password,
    required String name,
    String? avatarUrl,
    String? email,
    String? phone,
  }) async {
    try {
      await _authenticationClient.signUpWithPassword(
        email: email,
        phone: phone,
        password: password,
        name: name,
        avatarUrl: avatarUrl,
      );
    } on SignUpWithPasswordFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SignUpWithPasswordFailure(error),
        stackTrace,
      );
    }
  }

  /// Sends a password reset email to the provided [email].
  /// Optionally allows specifying a [redirectTo] url to redirect
  /// the user to after resetting their password.
  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await _authenticationClient.sendPasswordResetEmail(
        email: email,
        redirectTo: redirectTo,
      );
    } on SendPasswordResetEmailFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SendPasswordResetEmailFailure(error),
        stackTrace,
      );
    }
  }

  /// Resets the password for the user with the given [email]
  /// using the provided [token]. Updates the password to
  /// the new [newPassword].
  Future<void> resetPassword({
    required String token,
    required String email,
    required String newPassword,
  }) async {
    try {
      await _authenticationClient.resetPassword(
        token: token,
        email: email,
        newPassword: newPassword,
      );
    } on ResetPasswordFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ResetPasswordFailure(error),
        stackTrace,
      );
    }
  }

  /// Get user profile image public url.
  String getProfileImageUrl({
    required String imageName,
    String? userId,
    TransformOptions? transform,
  }) {
    if (imageName.startsWith(RegExp('^https?://')) ||
        imageName.contains('fake')) {
      return imageName;
    }
    try {
      return _databaseClient.getPublicUrl(
        storageBucket: 'avatars',
        name: imageName,
        path: (name) => '${userId ?? currentUserId}/$name',
        transform: transform,
      );
    } on GetPublicUrlFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(GetPublicUrlFailure(error), stackTrace);
    }
  }
}
