/// {@template env}
/// Environment variables for the application.
/// {@endtemplate}
enum Env {
  /// Supabase URL.
  supabaseUrl('SUPABASE_URL'),

  /// PowerSync URL.
  powerSyncUrl('POWERSYNC_URL'),

  /// Supabase anonymous key.
  supabaseAnonKey('SUPABASE_ANON_KEY');

  const Env(this.value);

  /// Value of the environment variable.
  final String value;
}
