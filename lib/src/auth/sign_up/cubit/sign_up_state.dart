part of 'sign_up_cubit.dart';

typedef SingUpErrorMessage = String;

enum SignUpSubmissionStatus {
  idle,
  inProgress,
  success,
  emailAlreadyRegistered,
  networkError,
  error;

  bool get isSuccess => this == SignUpSubmissionStatus.success;
  bool get isLoading => this == SignUpSubmissionStatus.inProgress;
  bool get isEmailRegistered =>
      this == SignUpSubmissionStatus.emailAlreadyRegistered;
  bool get isNetworkError => this == SignUpSubmissionStatus.networkError;
  bool get isError =>
      this == SignUpSubmissionStatus.error ||
      isNetworkError ||
      isEmailRegistered;
}

class SignUpState extends Equatable {
  const SignUpState._({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.submissionStatus,
    required this.showPassword,
    this.error,
  });

  const SignUpState.initial()
    : this._(
        firstName: const FirstName.pure(),
        lastName: const LastName.pure(),
        email: const Email.pure(),
        password: const Password.pure(),
        phoneNumber: const PhoneNumber.pure(),
        avatarUrl: '',
        submissionStatus: SignUpSubmissionStatus.idle,
        showPassword: false,
      );

  final Email email;
  final Password password;
  final FirstName firstName;
  final LastName lastName;
  final PhoneNumber phoneNumber;
  final SignUpSubmissionStatus submissionStatus;
  final Object? error;
  final String? avatarUrl;
  final bool showPassword;

  SignUpState copyWith({
    Email? email,
    Password? password,
    FirstName? firstName,
    LastName? lastName,
    PhoneNumber? phoneNumber,
    String? avatarUrl,
    SignUpSubmissionStatus? submissionStatus,
    bool? showPassword,
    Object? error,
  }) => SignUpState._(
    email: email ?? this.email,
    password: password ?? this.password,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    submissionStatus: submissionStatus ?? this.submissionStatus,
    showPassword: showPassword ?? this.showPassword,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => <Object?>[
    email,
    password,
    firstName,
    lastName,
    phoneNumber,
    avatarUrl,
    submissionStatus,
    showPassword,
    error,
  ];
}

SubmissionStatusMessage? signUpSubmissionStatusMessage(
  AppLocalizations l10n,
  SignUpSubmissionStatus status, {
  Object? error,
}) => switch (status) {
  SignUpSubmissionStatus.emailAlreadyRegistered => SubmissionStatusMessage(
    title: l10n.userWithThisEmailAlreadyExistsTitle,
    description: l10n.userWithThisEmailAlreadyExistsDescription,
  ),
  SignUpSubmissionStatus.error => SubmissionStatusMessage(
    title: l10n.genericErrorTitle,
    description: error != null ? Error.safeToString(error) : null,
  ),
  SignUpSubmissionStatus.networkError => SubmissionStatusMessage(
    title: l10n.networkErrorTitle,
    description: l10n.networkErrorDescription,
  ),
  SignUpSubmissionStatus.idle ||
  SignUpSubmissionStatus.inProgress ||
  SignUpSubmissionStatus.success => null,
};
