import 'package:equatable/equatable.dart' show EquatableMixin;
import 'package:flutter/foundation.dart' show immutable;
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/formz_validation_mixin.dart';
import 'package:formz/formz.dart' show FormzInput;

/// {@template first_name}
/// Form input for a first name. It extends [FormzInput] and uses
/// [FirstNameValidationError] for its validation errors.
/// {@endtemplate}
@immutable
class FirstName extends FormzInput<String, FirstNameValidationError>
    with EquatableMixin, FormzValidationMixin {
  /// {@macro first_name.pure}
  const FirstName.pure([super.value = '']) : super.pure();

  /// {@macro first_name.dirty}
  const FirstName.dirty(super.value) : super.dirty();

  @override
  FirstNameValidationError? validator(String value) {
    if (value.isEmpty) return FirstNameValidationError.empty;
    if (value.length > 50) return FirstNameValidationError.tooLong;
    return null;
  }

  @override
  String validationErrorMessage(FirstNameValidationError error) =>
      switch (error) {
        FirstNameValidationError.empty =>
          FormFieldsConfig.errorMessages.firstNameEmpty,
        FirstNameValidationError.tooLong =>
          FormFieldsConfig.errorMessages.firstNameTooLong,
      };

  @override
  List<Object?> get props => [value, pure];
}

/// Validation errors for [FirstName]. It can be empty or too long.
enum FirstNameValidationError {
  /// Empty first name.
  empty,

  /// First name exceeds maximum length.
  tooLong,
}
