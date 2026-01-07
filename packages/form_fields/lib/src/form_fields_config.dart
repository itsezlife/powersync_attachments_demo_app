import 'package:form_fields/form_fields.dart';

/// Global configuration for form fields
class FormFieldsConfig {
  /// {@macro form_fields_config}
  factory FormFieldsConfig() => _instance ??= const FormFieldsConfig._();

  const FormFieldsConfig._();

  static FormFieldsConfig? _instance;

  /// Default error messages
  static FormFieldErrorMessages errorMessages =
      const DefaultFormFieldErrorMessages();

  /// Configure form fields with custom error messages
  static void configure({FormFieldErrorMessages? errorMessages}) {
    if (errorMessages != null) {
      FormFieldsConfig.errorMessages = errorMessages;
    }
  }

  /// Dispose the form fields config.
  void dispose() {
    _instance = null;
  }
}
