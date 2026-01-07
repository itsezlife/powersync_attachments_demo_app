import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:form_fields/form_fields.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(const SignUpState.initial());

  final UserRepository _userRepository;

  void changePasswordVisibility() =>
      emit(state.copyWith(showPassword: !state.showPassword));

  void onEmailChanged(String newValue) {
    final previousScreenState = state;
    final previousEmailState = previousScreenState.email;
    final shouldValidate = previousEmailState.invalid;
    final newEmailState = shouldValidate
        ? Email.dirty(newValue)
        : Email.pure(newValue);

    final newScreenState = state.copyWith(email: newEmailState);

    emit(newScreenState);
  }

  void onEmailUnfocused() {
    final previousScreenState = state;
    final previousEmailState = previousScreenState.email;
    final previousEmailValue = previousEmailState.value;

    final newEmailState = Email.dirty(previousEmailValue);
    final newScreenState = previousScreenState.copyWith(email: newEmailState);
    emit(newScreenState);
  }

  void onPasswordChanged(String newValue) {
    final previousScreenState = state;
    final previousPasswordState = previousScreenState.password;
    final shouldValidate = previousPasswordState.invalid;
    final newPasswordState = shouldValidate
        ? Password.dirty(newValue)
        : Password.pure(newValue);

    final newScreenState = state.copyWith(password: newPasswordState);

    emit(newScreenState);
  }

  void onPasswordUnfocused() {
    final previousScreenState = state;
    final previousPasswordState = previousScreenState.password;
    final previousPasswordValue = previousPasswordState.value;

    final newPasswordState = Password.dirty(previousPasswordValue);
    final newScreenState = previousScreenState.copyWith(
      password: newPasswordState,
    );
    emit(newScreenState);
  }

  void onFirstNameChanged(String newValue) {
    final previousScreenState = state;
    final previousFirstNameState = previousScreenState.firstName;
    final shouldValidate = previousFirstNameState.invalid;
    final newFirstNameState = shouldValidate
        ? FirstName.dirty(newValue)
        : FirstName.pure(newValue);

    final newScreenState = state.copyWith(firstName: newFirstNameState);

    emit(newScreenState);
  }

  void onFirstNameUnfocused() {
    final previousScreenState = state;
    final previousFirstNameState = previousScreenState.firstName;
    final previousFirstNameValue = previousFirstNameState.value;

    final newFirstNameState = FirstName.dirty(previousFirstNameValue);
    final newScreenState = previousScreenState.copyWith(
      firstName: newFirstNameState,
    );
    emit(newScreenState);
  }

  void onLastNameChanged(String newValue) {
    final previousScreenState = state;
    final previousLastNameState = previousScreenState.lastName;
    final shouldValidate = previousLastNameState.invalid;
    final newLastNameState = shouldValidate
        ? LastName.dirty(newValue)
        : LastName.pure(newValue);

    final newScreenState = state.copyWith(lastName: newLastNameState);

    emit(newScreenState);
  }

  void onLastNameUnfocused() {
    final previousScreenState = state;
    final previousLastNameState = previousScreenState.lastName;
    final previousLastNameValue = previousLastNameState.value;

    final newLastNameState = LastName.dirty(previousLastNameValue);
    final newScreenState = previousScreenState.copyWith(
      lastName: newLastNameState,
    );
    emit(newScreenState);
  }

  void onPhoneNumberChanged(String newValue) {
    final previousScreenState = state;
    final previousPhoneNumberState = previousScreenState.phoneNumber;
    final shouldValidate = previousPhoneNumberState.invalid;
    final newPhoneNumberState = shouldValidate
        ? PhoneNumber.dirty(newValue)
        : PhoneNumber.pure(newValue);

    final newScreenState = state.copyWith(phoneNumber: newPhoneNumberState);

    emit(newScreenState);
  }

  void onPhoneNumberUnfocused() {
    final previousScreenState = state;
    final previousPhoneNumberState = previousScreenState.phoneNumber;
    final previousPhoneNumberValue = previousPhoneNumberState.value;

    final newPhoneNumberState = PhoneNumber.dirty(previousPhoneNumberValue);
    final newScreenState = previousScreenState.copyWith(
      phoneNumber: newPhoneNumberState,
    );
    emit(newScreenState);
  }

  Future<void> onSubmit({File? avatarFile}) async {
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);
    final firstName = FirstName.dirty(state.firstName.value);
    final lastName = LastName.dirty(state.lastName.value);
    final isFormValid = FormzValid([
      email,
      password,
      firstName,
      lastName,
    ]).isFormValid;

    final newState = state.copyWith(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      submissionStatus: isFormValid ? SignUpSubmissionStatus.inProgress : null,
      error: null,
    );

    emit(newState);

    if (!isFormValid) return;

    try {
      await _userRepository.signUpWithPassword(
        email: email.value,
        name: '${firstName.value} ${lastName.value}',
        password: password.value,
      );

      if (isClosed) return;
      emit(state.copyWith(submissionStatus: SignUpSubmissionStatus.success));
    } on Object catch (e, stackTrace) {
      _errorFormatter(e, stackTrace);
    }
  }

  void _errorFormatter(Object e, StackTrace stackTrace) {
    addError(e, stackTrace);

    SignUpSubmissionStatus submissionStatus() => SignUpSubmissionStatus.error;

    final newState = state.copyWith(
      submissionStatus: submissionStatus(),
      error: e.toString(),
    );
    emit(newState);
  }
}
