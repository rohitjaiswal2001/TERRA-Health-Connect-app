/// The distinct stages of the Apple Health bridge flow. The UI router renders
/// exactly one screen per phase, so this enum is the single source of truth for
/// "what is the user looking at right now".
enum ConnectionPhase {
  /// Internal starting sentinel, used only while [ConnectionProvider.bootstrap]
  /// decides the opening screen. Because bootstrap runs before `runApp`, the UI
  /// is never built in this phase — the native launch screen covers it.
  launching,

  /// No reference id yet (typically a fresh install, where iOS dropped the
  /// deep link's `ref` on the way through the App Store). The member scans the
  /// QR or types the 6-character pairing code shown on the website.
  pairing,

  /// Landing / "why connect" screen. Default state once we know the member.
  welcome,

  /// SDK is initialising and opening the Terra connection (before the system
  /// HealthKit sheet appears).
  initializing,

  /// Reading Apple Health and pushing it to the Terra webhook.
  syncing,

  /// Done — data is flowing. The single earned "lime" moment.
  connected,

  /// The connection opened but Apple Health returned nothing from any category
  /// — typically the member declined the data types in the consent sheet (iOS
  /// hides which individual reads were granted, so "nothing arrived from
  /// anything" is the one honest signal we get), or there's simply no recent
  /// data on this device. Recoverable: guide them to turn the categories on.
  noData,

  /// Already connected on a previous launch — show the manage screen.
  manage,

  /// The member skipped or declined. Never block, never nag.
  declined,

  /// Apple Health was disconnected — Terra's access is revoked and its cached
  /// copy deleted.
  disconnected,

  /// The app was opened without a member session and isn't connected yet —
  /// route them back to the website funnel.
  notMember,

  /// Something went wrong. Recoverable — offer a retry.
  error,
}

extension ConnectionPhaseX on ConnectionPhase {
  /// Whether the flow is mid-work (spinner state).
  bool get isBusy =>
      this == ConnectionPhase.initializing || this == ConnectionPhase.syncing;
}
