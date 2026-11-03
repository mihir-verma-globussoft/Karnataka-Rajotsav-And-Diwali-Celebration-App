/// Deployment environment, selected at build time with
/// `--dart-define=APP_ENV=dev|staging|prod` (defaults to `dev`).
enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment parse(String value) => AppEnvironment.values.firstWhere(
    (e) => e.name == value,
    orElse: () => AppEnvironment.dev,
  );
}

/// Immutable build-time configuration. Never put secrets here: values passed
/// with `--dart-define` are readable from the compiled app.
class AppConfig {
  const AppConfig({
    required this.environment,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.googleWebClientId = '',
    this.googleIosClientId = '',
    this.privacyPolicyUrl = '',
  });

  factory AppConfig.fromEnvironment() => AppConfig(
    environment: AppEnvironment.parse(
      const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
    ),
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    googleWebClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    googleIosClientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    privacyPolicyUrl: const String.fromEnvironment('PRIVACY_POLICY_URL'),
  );

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleIosClientId;
  final String privacyPolicyUrl;

  bool get isProd => environment == AppEnvironment.prod;

  bool get hasSupabase =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  bool get hasGoogleAuth => googleWebClientId.isNotEmpty;
}
