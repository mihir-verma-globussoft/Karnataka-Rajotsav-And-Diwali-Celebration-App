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
  const AppConfig({required this.environment});

  factory AppConfig.fromEnvironment() => AppConfig(
    environment: AppEnvironment.parse(
      const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
    ),
  );

  final AppEnvironment environment;

  bool get isProd => environment == AppEnvironment.prod;
}
