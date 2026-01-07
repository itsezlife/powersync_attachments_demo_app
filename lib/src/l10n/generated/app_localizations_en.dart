// ignore_for_file: dart-format

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'English';

  @override
  String get languageEn => 'English';

  @override
  String bottomNavBarTabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'feed': 'Feed',
      'createPost': 'Create Post',
      'profile': 'Profile',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get genericErrorTitle => 'Something went wrong! Try again later.';

  @override
  String get networkErrorTitle => 'Internet connection error!';

  @override
  String get networkErrorDescription =>
      'Check your internet connection and try again.';

  @override
  String get invalidCredentialsTitle => 'Email and/or password are incorrect.';

  @override
  String get userNotFoundTitle => 'User with this email not found!';

  @override
  String get userNotFoundDescription => 'Try to sign up.';

  @override
  String get googleLogInFailureTitle => 'Google login failed!';

  @override
  String get googleLogInFailureDescription => 'Try again later.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get signInButtonLabel => 'Sign in';

  @override
  String get signUpButtonLabel => 'Sign up';

  @override
  String get forgotPasswordButtonLabel => 'Forgot password?';

  @override
  String get signInWithGoogleButtonLabel => 'Sign in with Google';

  @override
  String get signInWithEmailButtonLabel => 'Sign in with Email';

  @override
  String get signUpNewAccountLabel =>
      'Don\'t have an account? <a action=\'CHANGE_AUTH\'>Sign up</a>';

  @override
  String get signInNewAccountLabel =>
      'Already have an account? <a action=\'CHANGE_AUTH\'>Sign in</a>';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get firstNameHint => 'Enter your first name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get lastNameHint => 'Enter your last name';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => 'Enter your phone number';

  @override
  String get avatarLabel => 'Avatar';

  @override
  String get avatarHint => 'Upload your avatar';

  @override
  String get signUpInProgressLabel => 'Signing up...';

  @override
  String get userWithThisEmailAlreadyExistsTitle =>
      'User with this email already exists.';

  @override
  String get userWithThisEmailAlreadyExistsDescription =>
      'Try another email address.';

  @override
  String get logOutLabel => 'Log out';

  @override
  String get logOutConfirmationLabel => 'Are you sure you want to log out?';

  @override
  String get postUploadFailedLabel =>
      'Post upload failed. Please try again later.';

  @override
  String get postCreateFailedLabel =>
      'Post creation failed. Please try again later.';

  @override
  String get createPostHint => 'Write something...';

  @override
  String get createPostButtonLabel => 'Create post';

  @override
  String get addPostPhotosLabel => 'Add photos';

  @override
  String get publishButtonLabel => 'Publish';

  @override
  String get tryAgainLabel => 'Try again';

  @override
  String get genericErrorReloadLabel =>
      'Something went wrong. <b>Tap to reload</b>';

  @override
  String get genericErrorDescription =>
      'Please check your internet connection and try again.';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get noPostsTitle => 'No posts yet';
}
