import 'package:equatable/equatable.dart' show EquatableMixin;
import 'package:flutter/foundation.dart' show immutable;
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/formz_validation_mixin.dart';
import 'package:formz/formz.dart' show FormzInput;

/// {@template phone_number}
/// Form input for a phone number. It extends [FormzInput] and uses
/// [PhoneNumberValidationError] for its validation errors.
/// {@endtemplate}
@immutable
class PhoneNumber extends FormzInput<String, PhoneNumberValidationError>
    with EquatableMixin, FormzValidationMixin {
  /// {@macro phone_number.pure}
  const PhoneNumber.pure([super.value = '']) : super.pure();

  /// {@macro phone_number.dirty}
  const PhoneNumber.dirty(super.value) : super.dirty();

  /// Regex for validating phone numbers
  /// Accepts formats:
  /// - +1234567890
  /// - 1234567890
  /// - 123-456-7890
  /// - (123) 456-7890
  /// - +1 (123) 456-7890
  static final _phoneRegex = RegExp(
    r'^\+?\d{0,3}?[- ]?\(?(?:\d{3})\)?[- ]?\d{3}[- ]?\d{4}$',
  );

  @override
  PhoneNumberValidationError? validator(String value) {
    if (value.isEmpty) return PhoneNumberValidationError.empty;
    if (!_phoneRegex.hasMatch(value)) return PhoneNumberValidationError.invalid;
    return null;
  }

  @override
  String validationErrorMessage(PhoneNumberValidationError error) =>
      switch (error) {
        PhoneNumberValidationError.empty =>
          FormFieldsConfig.errorMessages.phoneNumberEmpty,
        PhoneNumberValidationError.invalid =>
          FormFieldsConfig.errorMessages.phoneNumberInvalid,
      };

  @override
  List<Object?> get props => [value, pure];
}

/// Validation errors for [PhoneNumber]. It can be empty or invalid.
enum PhoneNumberValidationError {
  /// Empty phone number.
  empty,

  /// Invalid phone number format.
  invalid,
}
