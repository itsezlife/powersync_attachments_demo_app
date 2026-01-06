import 'package:formz/formz.dart';

/// Mixin on [FormzInput] that provides common functionality for form input
/// fields.
///
/// It has:
/// - [validationError] getter that returns a validation error if input is
///  invalid
/// - [errorMessage] getter that returns an error message based on [E]
/// - [validationErrorMessage] function that returns an error message based on
/// [E]
mixin FormzValidationMixin<T, E> on FormzInput<T, E> {
  /// Returns the validation error if the input is invalid.
  E? get validationError => invalid ? error : null;

  /// Returns email error text based on [E].
  String? get errorMessage => validationError == null
      ? null
      : validationErrorMessage(validationError as E);

  /// Email validation errors message
  String validationErrorMessage(E error);
}
