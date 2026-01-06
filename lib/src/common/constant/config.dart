// ignore_for_file: avoid_classes_with_only_static_members

/// Config for app.
abstract final class Config {
  // --- ENVIRONMENT --- //

  /// Environment flavor.
  /// e.g. development, staging, production
  static final EnvironmentFlavor environment = EnvironmentFlavor.from(
    const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development'),
  );

  // --- API --- //

  /// Base url for api.
  /// e.g. https://api.vexus.io
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.domain.tld',
  );

  static const String websiteUrl = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: 'https://example.presentum.dev',
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

  /// --- RECOMMENDATION --- //

  /// Maximum age of recommendations in seconds.
  static const int recommendationMaxAgeSeconds = int.fromEnvironment(
    'RECOMMENDATION_MAX_AGE',
    defaultValue: 60,
  );

  /// Maximum age of recommendation set in seconds.
  static const int recommendationSetExpirationSeconds = int.fromEnvironment(
    'RECOMMENDATION_SET_EXPIRATION',
    defaultValue: 60,
  );
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
