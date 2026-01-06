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
      'main': 'Home',
      'menu': 'Menu',
      'other': 'Other',
    });
    return '$_temp0';
  }
}
