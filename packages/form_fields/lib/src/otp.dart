import 'package:equatable/equatable.dart' show EquatableMixin;
import 'package:flutter/foundation.dart' show immutable;
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/formz_validation_mixin.dart';
import 'package:formz/formz.dart';

/// {@template otp}
/// Formz input for OTP. It can be empty or invalid.
/// {@endtemplate}
@immutable
class Otp extends FormzInput<String, OtpValidationError>
    with EquatableMixin, FormzValidationMixin {
  /// {@macro otp.pure}
  const Otp.pure([super.value = '']) : super.pure();

  /// {@macro otp.dirty}
  const Otp.dirty(super.value) : super.dirty();

  /// Regex for validating OTP
  /// Accepts formats:
  /// - 123456
  /// - 1234567890
  static final _otpRegex = RegExp(r'^[0-9]+$');

  @override
  OtpValidationError? validator(String value) {
    if (value.isEmpty) return OtpValidationError.empty;
    if (!_otpRegex.hasMatch(value)) return OtpValidationError.invalid;
    if (value.length > 6) return OtpValidationError.tooLong;
    return null;
  }

  @override
  String validationErrorMessage(OtpValidationError error) => switch (error) {
    OtpValidationError.empty => FormFieldsConfig.errorMessages.otpEmpty,
    OtpValidationError.invalid => FormFieldsConfig.errorMessages.otpInvalid,
    OtpValidationError.tooLong => FormFieldsConfig.errorMessages.otpTooLong,
  };

  @override
  List<Object> get props => [pure, value];
}

/// Validation errors for [Otp]. It can be empty, invalid, or too long.
enum OtpValidationError {
  /// Empty OTP.
  empty,

  /// Invalid OTP.
  invalid,

  /// OTP exceeds maximum length, more than 6 characters.
  tooLong,
}
