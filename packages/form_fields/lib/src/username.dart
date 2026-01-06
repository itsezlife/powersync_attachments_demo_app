import 'package:equatable/equatable.dart' show EquatableMixin;
import 'package:flutter/foundation.dart' show immutable;
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/formz_validation_mixin.dart';
import 'package:formz/formz.dart' show FormzInput;

/// {@template username}
/// Form input for a username.1
/// {@endtemplate}
@immutable
class Username extends FormzInput<String, UsernameValidationError>
    with EquatableMixin, FormzValidationMixin {
  /// {@macro username.pure}
  const Username.pure([super.value = '']) : super.pure();

  /// {@macro username.dirty}
  const Username.dirty(super.value) : super.dirty();

  /// Regular expression for validating usernames. It matches:
  /// - 3-16 characters
  /// - Only letters, numbers, periods, and underscores
  static final _nameRegex = RegExp(r'^[a-zA-Z0-9_.]{3,16}$');

  @override
  UsernameValidationError? validator(String value) {
    if (value.isEmpty) return UsernameValidationError.empty;
    if (!_nameRegex.hasMatch(value)) return UsernameValidationError.invalid;
    if (value.length < 3) return UsernameValidationError.tooShort;
    if (value.length > 30) return UsernameValidationError.tooLong;
    return null;
  }

  @override
  String validationErrorMessage(UsernameValidationError error) =>
      switch (error) {
        UsernameValidationError.empty =>
          FormFieldsConfig.errorMessages.usernameEmpty,
        UsernameValidationError.invalid =>
          FormFieldsConfig.errorMessages.usernameInvalid,
        UsernameValidationError.tooShort =>
          FormFieldsConfig.errorMessages.usernameTooShort,
        UsernameValidationError.tooLong =>
          FormFieldsConfig.errorMessages.usernameTooLong,
      };

  @override
  List<Object?> get props => [value, pure];
}

/// Validation errors for [Username]. It can be empty, invalid, too short, or
/// too long.
enum UsernameValidationError {
  /// Empty username.
  empty,

  /// Invalid username, not matching the regex.
  invalid,

  /// Too short username, less than 3 characters.
  tooShort,

  /// Too long username, more than 30 characters.
  tooLong,
}
