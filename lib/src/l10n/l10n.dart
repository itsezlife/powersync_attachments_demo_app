import 'package:flutter/widgets.dart';
import 'package:powersync_attachments_example/src/l10n/generated/app_localizations.dart';

export 'generated/app_localizations.dart';

const defaultLocale = Locale('en');

extension Localization on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  bool isSupportedLocale(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);

  static const List<Locale> supportedLocales =
      AppLocalizations.supportedLocales;
}
