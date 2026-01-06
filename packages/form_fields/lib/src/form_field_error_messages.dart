/// {@template form_field_error_messages}
/// Abstract class that provides error messages for form fields
/// {@endtemplate}
abstract class FormFieldErrorMessages {
  /// {@macro form_field_error_messages}
  const FormFieldErrorMessages();

  /// Email is empty.
  ///
  /// The default is `Email is required`.
  String get emailEmpty;

  /// Email is invalid.
  ///
  /// The default is `Email is invalid`.
  String get emailInvalid;

  /// First name is empty.
  ///
  /// The default is `First name is required`.
  String get firstNameEmpty;

  /// First name is too long.
  ///
  /// The default is `First name can't be longer than 50 characters`.
  String get firstNameTooLong;

  /// Last name is empty.
  ///
  /// The default is `Last name is required`.
  String get lastNameEmpty;

  /// Last name is too long.
  ///
  /// The default is `Last name can't be longer than 50 characters`.
  String get lastNameTooLong;

  /// Full name is empty.
  ///
  /// The default is `Full name is required`.
  String get fullNameEmpty;

  /// Full name is too long.
  ///
  /// The default is `Full name can't be longer than 100 characters`.
  String get fullNameTooLong;

  /// Password is empty.
  ///
  /// The default is `Password is required`.
  String get passwordEmpty;

  /// Password is too short.
  ///
  /// The default is `Password must be at least 3 characters long`.
  String get passwordTooShort;

  /// Password is too long.
  ///
  /// The default is `Password can't be longer than 120 characters`.
  String get passwordTooLong;

  /// Username is empty.
  ///
  /// The default is `Username is required`.
  String get usernameEmpty;

  /// Username is invalid.
  ///
  /// The default is `Username can only contain letters, numbers, periods, `
  /// `and underscores`.
  String get usernameInvalid;

  /// Username is too short.
  ///
  /// The default is `Username must be at least 3 characters long`.
  String get usernameTooShort;

  /// Username is too long.
  ///
  /// The default is `Username can't be longer than 30 characters`.
  String get usernameTooLong;

  /// OTP is empty.
  ///
  /// The default is `OTP is required`.
  String get otpEmpty;

  /// OTP is invalid.
  ///
  /// The default is `OTP is invalid`.
  String get otpInvalid;

  /// OTP is too long.
  ///
  /// The default is `OTP can't be longer than 6 characters`.
  String get otpTooLong;

  /// Phone number is empty.
  ///
  /// The default is `Phone number is required`.
  String get phoneNumberEmpty;

  /// Phone number is invalid.
  ///
  /// The default is `Phone number is invalid`.
  String get phoneNumberInvalid;
}

/// {@template default_form_field_error_messages}
/// Default implementation of [FormFieldErrorMessages].
/// {@endtemplate}
class DefaultFormFieldErrorMessages extends FormFieldErrorMessages {
  /// {@macro default_form_field_error_messages}
  const DefaultFormFieldErrorMessages();

  @override
  String get emailEmpty => 'Email is required';

  @override
  String get emailInvalid => 'Email is invalid';

  @override
  String get firstNameEmpty => 'First name is required';

  @override
  String get firstNameTooLong =>
      "First name can't be longer than 50 characters";

  @override
  String get fullNameEmpty => 'Full name is required';

  @override
  String get fullNameTooLong => "Full name can't be longer than 100 characters";

  @override
  String get passwordEmpty => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 3 characters long';

  @override
  String get usernameEmpty => 'Username is required';

  @override
  String get usernameInvalid => 'Username is invalid';

  @override
  String get usernameTooShort => 'Username must be at least 3 characters long';

  @override
  String get usernameTooLong => "Username can't be longer than 30 characters";

  @override
  String get lastNameEmpty => 'Last name is required';

  @override
  String get lastNameTooLong => "Last name can't be longer than 50 characters";

  @override
  String get passwordTooLong => "Password can't be longer than 120 characters";

  @override
  String get otpEmpty => 'OTP is required';

  @override
  String get otpInvalid => 'OTP is invalid';

  @override
  String get otpTooLong => "OTP can't be longer than 6 characters";

  @override
  String get phoneNumberEmpty => 'Phone number is required';

  @override
  String get phoneNumberInvalid => 'Phone number is invalid';
}
