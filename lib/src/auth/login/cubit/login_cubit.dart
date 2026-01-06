import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:form_fields/form_fields.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:powersync_client/powersync_client.dart';
import 'package:shared/shared.dart';
import 'package:supabase_authentication_client/supabase_authentication_client.dart';
import 'package:user_repository/user_repository.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(const LoginState.initial());

  final UserRepository _userRepository;

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

  Future<void> onSubmit() async {
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);
    final isFormValid = FormzValid([email, password]).isFormValid;

    final newState = state.copyWith(
      email: email,
      password: password,
      status: isFormValid ? LogInSubmissionStatus.loading : null,
    );

    emit(newState);

    if (!isFormValid) return;

    try {
      await _userRepository.logInWithPassword(
        email: email.value,
        password: password.value,
      );
      final newState = state.copyWith(status: LogInSubmissionStatus.success);
      emit(newState);
    } on Object catch (e, stackTrace) {
      _errorFormatter(e, stackTrace);
    }
  }

  void _errorFormatter(Object e, StackTrace stackTrace) {
    addError(e, stackTrace);
    final status = switch (e) {
      LogInWithPasswordFailure(:final AuthException error) =>
        switch (int.tryParse(error.statusCode ?? '')) {
          HttpStatus.badRequest => LogInSubmissionStatus.invalidCredentials,
          _ => LogInSubmissionStatus.error,
        },
      _ => LogInSubmissionStatus.idle,
    };

    final newState = state.copyWith(
      status: status,
      message: e.toString(),
      error: e.toString(),
    );
    emit(newState);
  }
}
