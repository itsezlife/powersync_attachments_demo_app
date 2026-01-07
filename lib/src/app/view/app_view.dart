import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:powersync_attachments_example/src/app/router/router_state_mixin.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

class AppView extends StatefulWidget {
  const AppView({required this.user, super.key});

  final User user;

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> with RouterStateMixin {
  @override
  User get user => widget.user;

  late final ThemeData _theme;
  late final ThemeData _darkTheme;

  @override
  void initState() {
    super.initState();
    _theme = ThemeData.light();
    _darkTheme = ThemeData.dark();
  }

  final Key builderKey = GlobalKey(); // Disable recreate widget tree

  @override
  Widget build(BuildContext context) {
    const themeMode = ThemeMode.system;

    return MaterialApp.router(
      title: 'PowerSync Attachments',
      debugShowCheckedModeBanner: !Config.environment.isProduction,

      // Router
      routerConfig: router.config,

      // Localizations
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: defaultLocale,

      // Theme
      theme: _theme,
      themeMode: themeMode,
      darkTheme: _darkTheme,

      // Builder
      builder: (context, child) => MediaQuery(
        key: builderKey,
        data: MediaQuery.of(context).copyWith(
          platformBrightness: themeMode == ThemeMode.system
              ? SchedulerBinding.instance.platformDispatcher.platformBrightness
              : themeMode == ThemeMode.light
              ? Brightness.light
              : Brightness.dark,
          textScaler: TextScaler.linear(
            context.textScaleFactor(maxTextScaleFactor: 1.1),
          ),
        ),
        child: child!,
      ),
    );
  }
}
