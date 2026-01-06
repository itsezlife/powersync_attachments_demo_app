import 'package:equatable/equatable.dart' show EquatableMixin;
import 'package:flutter/foundation.dart' show immutable;
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/formz_validation_mixin.dart';
import 'package:formz/formz.dart';

/// {@template email}
/// Formz input for email. It can be empty or invalid.
/// {@endtemplate}
@immutable
class Email extends FormzInput<String, EmailValidationError>
    with EquatableMixin, FormzValidationMixin {
  /// {@macro email.pure}
  const Email.pure([super.value = '']) : super.pure();

  /// {@macro email.dirty}
  const Email.dirty(super.value) : super.dirty();

  /// Regular expression for validating email addresses. It matches:
  /// 1. Local part (before @):
  ///    - One or more sequences of word chars and hyphens followed by dots
  ///      (e.g. "user.name" or "first.last")
  ///    - OR a single letter
  ///    - OR 2+ word chars/hyphens (e.g. "username")
  /// 2. Followed by @
  /// 3. Domain part (after @):
  ///    - Either an IP address (0-255.0-255.0-255.0-255)
  ///    - OR one or more sequences of letters/word chars/hyphens + dot,
  ///      ending in 2-4 letters (e.g. "example.com" or "my-domain.co.uk")
  static final _emailRegex = RegExp(
    r'^(([\w-]+\.)+[\w-]+|([a-zA-Z]|[\w-]{2,}))@((([0-1]?'
    r'[0-9]{1,2}|25[0-5]|2[0-4][0-9])\.([0-1]?[0-9]{1,2}|25[0-5]|2[0-4][0-9])\.'
    r'([0-1]?[0-9]{1,2}|25[0-5]|2[0-4][0-9])\.([0-1]?[0-9]{1,2}|25[0-5]|2[0-4][0-9])'
    r')|([a-zA-Z]+[\w-]+\.)+[a-zA-Z]{2,4})$',
  );

  @override
  EmailValidationError? validator(String value) {
    if (value.isEmpty) return EmailValidationError.empty;
    if (!_emailRegex.hasMatch(value)) return EmailValidationError.invalid;
    return null;
  }

  @override
  String validationErrorMessage(EmailValidationError error) => switch (error) {
    EmailValidationError.empty => FormFieldsConfig.errorMessages.emailEmpty,
    EmailValidationError.invalid => FormFieldsConfig.errorMessages.emailInvalid,
  };

  @override
  List<Object> get props => [pure, value];
}

/// Validation errors for [Email]. It can be empty or invalid.
enum EmailValidationError {
  /// Empty email.
  empty,

  /// Invalid email.
  invalid,
}
