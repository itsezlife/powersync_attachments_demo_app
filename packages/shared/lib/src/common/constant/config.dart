import 'dart:math' as math;

import 'package:env/env.dart';
import 'package:flutter/foundation.dart';

/// Debug property used to invert the platform for testing.
bool debugReversePlatform = false;

/// Config for app.
abstract final class Config {
  // --- ENVIRONMENT --- //

  /// Environment flavor.
  /// e.g. development, staging, production
  static final EnvironmentFlavor environment = EnvironmentFlavor.from(
    const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development'),
  );

  /// Get environment variable.
  static String getEnv(Env env) => switch (env) {
    Env.supabaseUrl => switch (environment) {
      EnvironmentFlavor.development => EnvDev.supabaseUrl,
      EnvironmentFlavor.production => EnvProd.supabaseUrl,
      EnvironmentFlavor.staging => EnvProd.supabaseUrl,
    },
    Env.powerSyncUrl => switch (environment) {
      EnvironmentFlavor.development => EnvDev.powersyncUrl,
      EnvironmentFlavor.production => EnvProd.powersyncUrl,
      EnvironmentFlavor.staging => EnvProd.powersyncUrl,
    },
    Env.supabaseAnonKey => switch (environment) {
      EnvironmentFlavor.development => EnvDev.supabaseAnonKey,
      EnvironmentFlavor.production => EnvProd.supabaseAnonKey,
      EnvironmentFlavor.staging => EnvProd.supabaseAnonKey,
    },
  };

  /// A set of [TargetPlatform]s that for desktop devices.
  static const Set<TargetPlatform> desktop = <TargetPlatform>{
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.windows,
  };

  /// A set of [TargetPlatform]s that for mobile devices.
  static const Set<TargetPlatform> mobile = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.fuchsia,
    TargetPlatform.iOS,
  };

  /// Whether the current device is a `mobile`.
  static bool get isMobile => mobile.contains(defaultTargetPlatform);

  /// Whether the current device is a `desktop`.
  static bool get isDesktop => desktop.contains(defaultTargetPlatform);

  /// Whether the platform applies to the Cupertino design system.
  ///
  /// If [debugReversePlatform] is true, the platform will be inverted.
  /// For example, on iOS, the app will be displayed as Android and vice versa.
  static bool get isCupertino {
    final isApple = [
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ].contains(defaultTargetPlatform);
    return kDebugMode && debugReversePlatform ? !isApple : isApple;
  }

  /// Whether the platform applies to the Material design system.
  ///
  /// If [debugReversePlatform] is true, the platform will be inverted.
  /// For example, on Android, the app will be displayed as iOS and vice versa.
  static bool get isMaterial {
    final isAndroidOrWindows = [
      TargetPlatform.android,
      TargetPlatform.windows,
    ].contains(defaultTargetPlatform);
    return kDebugMode && debugReversePlatform
        ? !isAndroidOrWindows
        : isAndroidOrWindows;
  }

  /// Path to the application documents directory.
  static late String appDocsPath;

  // --- API --- //

  /// Base url for api.
  /// e.g. https://api.vexus.io
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.domain.tld',
  );

  /// Website url.
  static const String websiteUrl = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: 'https://example.domain.tld',
  );

  // --- AUTHENTICATION --- //

  /// Minimum length of password.
  /// e.g. 8
  static const int passwordMinLength = int.fromEnvironment(
    'PASSWORD_MIN_LENGTH',
    defaultValue: 8,
  );

  /// Maximum length of password.
  /// e.g. 32
  static const int passwordMaxLength = int.fromEnvironment(
    'PASSWORD_MAX_LENGTH',
    defaultValue: 32,
  );

  // --- LAYOUT --- //

  /// Maximum screen layout width for screen with list view.
  static const int maxScreenLayoutWidth = int.fromEnvironment(
    'MAX_LAYOUT_WIDTH',
    defaultValue: 768,
  );

  /// --- CURRENCY --- //

  /// Currency symbol.
  static const currencySymbol = r'$';

  // This alphabet uses `A-Za-z0-9_-` symbols. The genetic algorithm helped
  // optimize the gzip compression for this alphabet.
  static const _alphabet =
      'ModuleSymbhasOwnPr-0123456789ABCDEFGHNRVfgctiUvz_KqYTJkLxpZXIjQW';

  /// Generates a random String id
  /// Adopted from: https://github.com/ai/nanoid/blob/main/non-secure/index.js
  static String randomId({int size = 21}) {
    final id = StringBuffer();
    for (var i = 0; i < size; i++) {
      id.write(_alphabet[(math.Random().nextDouble() * 64).floor() | 0]);
    }
    return id.toString();
  }
}

/// Environment flavor.
/// e.g. development, staging, production
enum EnvironmentFlavor {
  /// Development
  development('development'),

  /// Staging
  staging('staging'),

  /// Production
  production('production');

  const EnvironmentFlavor(this.value);

  factory EnvironmentFlavor.from(String? value) => switch (value
      ?.trim()
      .toLowerCase()) {
    'development' || 'debug' || 'develop' || 'dev' => development,
    'staging' || 'profile' || 'stage' || 'stg' => staging,
    'production' || 'release' || 'prod' || 'prd' => production,
    _ =>
      const bool.fromEnvironment('dart.vm.product') ? production : development,
  };

  /// development, staging, production
  final String value;

  /// Whether the environment is development.
  bool get isDevelopment => this == development;

  /// Whether the environment is staging.
  bool get isStaging => this == staging;

  /// Whether the environment is production.
  bool get isProduction => this == production;
}
