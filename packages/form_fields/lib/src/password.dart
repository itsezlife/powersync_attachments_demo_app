import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/formz_validation_mixin.dart';
import 'package:formz/formz.dart' show FormzInput;

/// {@template password}
/// Form input for a password. It extends [FormzInput] and uses
/// [PasswordValidationError] for its validation errors.
/// {@endtemplate}
@immutable
class Password extends FormzInput<String, PasswordValidationError>
    with EquatableMixin, FormzValidationMixin {
  /// {@macro password.pure}
  const Password.pure([super.value = '']) : super.pure();

  /// {@macro password.dirty}
  const Password.dirty(super.value) : super.dirty();

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.empty;
    if (value.length < 3) return PasswordValidationError.tooShort;
    if (value.length > 120) return PasswordValidationError.tooLong;
    return null;
  }

  @override
  String validationErrorMessage(PasswordValidationError error) =>
      switch (error) {
        PasswordValidationError.empty =>
          FormFieldsConfig.errorMessages.passwordEmpty,
        PasswordValidationError.tooShort =>
          FormFieldsConfig.errorMessages.passwordTooShort,
        PasswordValidationError.tooLong =>
          FormFieldsConfig.errorMessages.passwordTooLong,
      };

  @override
  List<Object?> get props => [value, pure];
}

/// Validation errors for [Password]. It can be empty, tooShort, or too long.
enum PasswordValidationError {
  /// Empty password.
  empty,

  /// Password is too short, less than 3 characters.
  tooShort,

  /// Password exceeds maximum length, more than 120 characters.
  tooLong,
}
