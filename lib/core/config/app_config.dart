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

  /// Terra Developer ID. Safe to ship in the client (it is not a secret key),
  /// but kept as a define so staging/prod can differ.
  static const String terraDevId =
      String.fromEnvironment('TERRA_DEV_ID', defaultValue: '');

  /// Terra **secret** API key.
  ///
  /// ⚠️ DEV / TESTING ONLY. In production the token is minted by the website's
  /// backend and delivered via the deep link — never ship this key in a store
  /// build. When provided (via `--dart-define`) it lets the "Connect" button
  /// self-generate a token so the flow works without a live website link.
  static const String terraApiKey =
      String.fromEnvironment('TERRA_API_KEY', defaultValue: '');

  /// Fallback reference id used only when the website does not supply one via
  /// the deep link. In production the website always passes `reference_id`.
  static const String defaultReferenceId =
      String.fromEnvironment('TERRA_REFERENCE_ID', defaultValue: 'personally-app');

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

  /// Whether the required Terra configuration is present.
  static bool get isConfigured => terraDevId.isNotEmpty;

  /// Whether the app can mint its own token (dev/testing) — true only when a
  /// dev id *and* an API key are configured.
  static bool get canSelfGenerateToken =>
      terraDevId.isNotEmpty && terraApiKey.isNotEmpty;
}
