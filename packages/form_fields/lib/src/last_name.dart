import 'package:equatable/equatable.dart' show EquatableMixin;
import 'package:flutter/foundation.dart' show immutable;
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/formz_validation_mixin.dart';
import 'package:formz/formz.dart' show FormzInput;

/// {@template last_name}
/// Form input for a last name. It extends [FormzInput] and uses
/// [LastNameValidationError] for its validation errors.
/// {@endtemplate}
@immutable
class LastName extends FormzInput<String, LastNameValidationError>
    with EquatableMixin, FormzValidationMixin {
  /// {@macro last_name.pure}
  const LastName.pure([super.value = '']) : super.pure();

  /// {@macro last_name.dirty}
  const LastName.dirty(super.value) : super.dirty();

  @override
  LastNameValidationError? validator(String value) {
    if (value.isEmpty) return LastNameValidationError.empty;
    if (value.length > 50) return LastNameValidationError.tooLong;
    return null;
  }

  @override
  String validationErrorMessage(LastNameValidationError error) =>
      switch (error) {
        LastNameValidationError.empty =>
          FormFieldsConfig.errorMessages.lastNameEmpty,
        LastNameValidationError.tooLong =>
          FormFieldsConfig.errorMessages.lastNameTooLong,
      };

  @override
  List<Object?> get props => [value, pure];
}

/// Validation errors for [LastName]. It can be empty or too long.
enum LastNameValidationError {
  /// Empty last name.
  empty,

  /// Last name exceeds maximum length, more than 50 characters.
  tooLong,
}
