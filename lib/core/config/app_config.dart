/// Environment configuration for the Apple Health bridge.
///
/// Secrets and environment-specific values are injected at build time with
/// `--dart-define` so nothing sensitive is hard-coded into the repo. Example:
///
/// ```
/// flutter run \
///   --dart-define=TERRA_DEV_ID=your-dev-id \
///   --dart-define=DEMO_TOKEN=one-time-token-for-local-testing
/// ```
class AppConfig {
  const AppConfig._();

  /// Terra Developer ID. Safe to ship in the client (it is not a secret key).
  ///
  /// The `defaultValue` lets the app work when launched straight from Xcode
  /// (which does not apply `--dart-define`). A `--dart-define=TERRA_DEV_ID=…`
  /// still overrides it for VS Code / `flutter run` / CI builds.
  static const String terraDevId =
      String.fromEnvironment('TERRA_DEV_ID', defaultValue: 'personally-testing-67P5ZYLGNE');

  /// Terra **secret** API key.
  ///
  /// ⚠️ DEV / TESTING ONLY — this default is a convenience so the "Connect"
  /// button works when running standalone from Xcode. **Clear this default
  /// (set it back to '') before any release/TestFlight build or committing to a
  /// shared repo.** In production the token is minted by the website's backend
  /// and delivered via the deep link, so a store build needs no API key.
  static const String terraApiKey =
      String.fromEnvironment('TERRA_API_KEY',
          defaultValue: '7488ad7117d07b034efda71438dc59b512c7dd1e982b8ed3df138678483a2654');

  /// Fallback reference id used when the website does not supply one via
  /// the deep link. Generates a fresh unique ID for testing so every run creates a new entry.
  static String get defaultReferenceId =>
      String.fromEnvironment('TERRA_REFERENCE_ID',
          defaultValue: 'personally-app-${DateTime.now().millisecondsSinceEpoch}');

  /// Custom URL scheme the website uses to launch this app.
  /// e.g. `personallyhealth://connect?token=...&redirect=...`
  static const String urlScheme = 'personallyhealth';

  /// Public marketing / funnel site. Used as the default redirect target and
  /// for the "Go to personally.com" call to action.
  static const String websiteUrl = 'https://personally-website.vercel.app';

  /// App Store listing — the website falls back to this when the app is not
  /// installed. Kept here so the "not a member" and error paths can deep-link.
  static const String appStoreUrl =
      String.fromEnvironment('APP_STORE_URL', defaultValue: 'https://apps.apple.com/app/id000000000');

  /// Optional one-time auth token for local testing without a live deep link.
  static const String demoToken =
      String.fromEnvironment('DEMO_TOKEN', defaultValue: '');

  /// How many days of Apple Health history a capture pulls, counting back from
  /// today. Single request for fast execution without chunking delays.
  static const int historyDays =
      int.fromEnvironment('HISTORY_DAYS', defaultValue: 30);

  /// Whether the required Terra configuration is present.
  static bool get isConfigured => terraDevId.isNotEmpty;

  /// Whether the app can mint its own token (dev/testing) — true only when a
  /// dev id *and* an API key are configured.
  static bool get canSelfGenerateToken =>
      terraDevId.isNotEmpty && terraApiKey.isNotEmpty;
}
