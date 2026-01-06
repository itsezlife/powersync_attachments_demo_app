part of 'login_cubit.dart';

typedef LoginErrorMessage = String;

enum LogInSubmissionStatus {
  idle,
  loading,
  googleAuthInProgress,
  githubAuthInProgress,
  success,
  invalidCredentials,
  userNotFound,
  networkError,
  error,
  googleLogInFailure;

  bool get isSuccess => this == LogInSubmissionStatus.success;
  bool get isLoading => this == LogInSubmissionStatus.loading;
  bool get isGoogleAuthInProgress =>
      this == LogInSubmissionStatus.googleAuthInProgress;
  bool get isGithubAuthInProgress =>
      this == LogInSubmissionStatus.githubAuthInProgress;
  bool get isInvalidCredentials =>
      this == LogInSubmissionStatus.invalidCredentials;
  bool get isNetworkError => this == LogInSubmissionStatus.networkError;
  bool get isUserNotFound => this == LogInSubmissionStatus.userNotFound;
  bool get isError =>
      this == LogInSubmissionStatus.error ||
      isUserNotFound ||
      isNetworkError ||
      isInvalidCredentials;
}

class LoginState extends Equatable {
  const LoginState._({
    required this.status,
    required this.email,
    required this.password,
    this.message,
    this.error,
  });

  const LoginState.initial()
    : this._(
        status: LogInSubmissionStatus.idle,
        email: const Email.pure(),
        password: const Password.pure(),
      );

  final LogInSubmissionStatus status;
  final Email email;
  final Password password;
  final LoginErrorMessage? message;
  final Object? error;

  LoginState copyWith({
    LogInSubmissionStatus? status,
    LoginErrorMessage? message,
    Email? email,
    Password? password,
    Object? error,
  }) => LoginState._(
    status: status ?? this.status,
    message: message ?? this.message,
    email: email ?? this.email,
    password: password ?? this.password,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, message, email, password, error];
}

SubmissionStatusMessage? loginSubmissionStatusMessage(
  AppLocalizations l10n,
  LogInSubmissionStatus status, {
  Object? error,
}) => switch (status) {
  LogInSubmissionStatus.error => SubmissionStatusMessage(
    title: l10n.genericErrorTitle,
    description: error != null ? Error.safeToString(error) : null,
  ),
  LogInSubmissionStatus.networkError => SubmissionStatusMessage(
    title: l10n.networkErrorTitle,
    description: l10n.networkErrorDescription,
  ),
  LogInSubmissionStatus.invalidCredentials => SubmissionStatusMessage(
    title: l10n.invalidCredentialsTitle,
  ),
  LogInSubmissionStatus.userNotFound => SubmissionStatusMessage(
    title: l10n.userNotFoundTitle,
    description: l10n.userNotFoundDescription,
  ),
  LogInSubmissionStatus.googleLogInFailure => SubmissionStatusMessage(
    title: l10n.genericErrorTitle,
  ),
  LogInSubmissionStatus.idle ||
  LogInSubmissionStatus.loading ||
  LogInSubmissionStatus.googleAuthInProgress ||
  LogInSubmissionStatus.githubAuthInProgress ||
  LogInSubmissionStatus.success => null,
};
