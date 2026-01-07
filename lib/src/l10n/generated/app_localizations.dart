// ignore_for_file: dart-format
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// The label for the bottom navigation bar tab.
  ///
  /// In en, this message translates to:
  /// **'{tab, select, feed{Feed} createPost{Create Post} profile{Profile} other{Other}}'**
  String bottomNavBarTabLabel(String tab);

  /// No description provided for @genericErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong! Try again later.'**
  String get genericErrorTitle;

  /// No description provided for @networkErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Internet connection error!'**
  String get networkErrorTitle;

  /// No description provided for @networkErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get networkErrorDescription;

  /// No description provided for @invalidCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Email and/or password are incorrect.'**
  String get invalidCredentialsTitle;

  /// No description provided for @userNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'User with this email not found!'**
  String get userNotFoundTitle;

  /// No description provided for @userNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Try to sign up.'**
  String get userNotFoundDescription;

  /// No description provided for @googleLogInFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Google login failed!'**
  String get googleLogInFailureTitle;

  /// No description provided for @googleLogInFailureDescription.
  ///
  /// In en, this message translates to:
  /// **'Try again later.'**
  String get googleLogInFailureDescription;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @signInButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButtonLabel;

  /// No description provided for @signUpButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpButtonLabel;

  /// No description provided for @forgotPasswordButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordButtonLabel;

  /// No description provided for @signInWithGoogleButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogleButtonLabel;

  /// No description provided for @signInWithEmailButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get signInWithEmailButtonLabel;

  /// No description provided for @signUpNewAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? <a action=\'CHANGE_AUTH\'>Sign up</a>'**
  String get signUpNewAccountLabel;

  /// No description provided for @signInNewAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? <a action=\'CHANGE_AUTH\'>Sign in</a>'**
  String get signInNewAccountLabel;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get firstNameHint;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get lastNameHint;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneNumberHint;

  /// No description provided for @avatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarLabel;

  /// No description provided for @avatarHint.
  ///
  /// In en, this message translates to:
  /// **'Upload your avatar'**
  String get avatarHint;

  /// No description provided for @signUpInProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Signing up...'**
  String get signUpInProgressLabel;

  /// No description provided for @userWithThisEmailAlreadyExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'User with this email already exists.'**
  String get userWithThisEmailAlreadyExistsTitle;

  /// No description provided for @userWithThisEmailAlreadyExistsDescription.
  ///
  /// In en, this message translates to:
  /// **'Try another email address.'**
  String get userWithThisEmailAlreadyExistsDescription;

  /// No description provided for @logOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOutLabel;

  /// No description provided for @logOutConfirmationLabel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirmationLabel;

  /// No description provided for @postUploadFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Post upload failed. Please try again later.'**
  String get postUploadFailedLabel;

  /// No description provided for @postCreateFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Post creation failed. Please try again later.'**
  String get postCreateFailedLabel;

  /// No description provided for @createPostHint.
  ///
  /// In en, this message translates to:
  /// **'Write something...'**
  String get createPostHint;

  /// No description provided for @createPostButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get createPostButtonLabel;

  /// No description provided for @addPostPhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPostPhotosLabel;

  /// No description provided for @publishButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishButtonLabel;

  /// No description provided for @tryAgainLabel.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainLabel;

  /// No description provided for @genericErrorReloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. <b>Tap to reload</b>'**
  String get genericErrorReloadLabel;

  /// No description provided for @genericErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get genericErrorDescription;

  /// No description provided for @refreshLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLabel;

  /// No description provided for @noPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
