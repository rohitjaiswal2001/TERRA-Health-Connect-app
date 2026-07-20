/// The distinct stages of the Apple Health bridge flow. The UI router renders
/// exactly one screen per phase, so this enum is the single source of truth for
/// "what is the user looking at right now".
enum ConnectionPhase {
  /// Landing / "why connect" screen. Default state.
  welcome,

  /// SDK is initialising and opening the Terra connection (before the system
  /// HealthKit sheet appears).
  initializing,

  /// Reading Apple Health and pushing it to the Terra webhook.
  syncing,

  /// Done — data is flowing. The single earned "lime" moment.
  connected,

  /// Already connected on a previous launch — show the manage screen.
  manage,

  /// The member skipped or declined. Never block, never nag.
  declined,

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
