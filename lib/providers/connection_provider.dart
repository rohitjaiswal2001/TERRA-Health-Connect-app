import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';
import '../models/connect_request.dart';
import '../models/connection_phase.dart';
import '../services/deep_link_service.dart';
import '../services/redirect_service.dart';
import '../services/terra_auth_service.dart';
import '../services/terra_service.dart';

/// Orchestrates the whole Apple Health bridge flow and exposes it to the UI.
///
/// The screens are dumb: they read [phase] to decide what to show and call the
/// intent methods ([connect], [skip], [finish], [retry]) in response to taps.
/// All Terra / deep-link / redirect wiring is hidden behind the services.
class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider({
    TerraService? terra,
    TerraAuthService? auth,
    DeepLinkService? deepLinks,
    RedirectService? redirects,
  }) : _terra = terra ?? TerraService(),
       _auth = auth ?? TerraAuthService(),
       _deepLinks = deepLinks ?? DeepLinkService(),
       _redirects = redirects ?? const RedirectService();

  final TerraService _terra;
  final TerraAuthService _auth;
  final DeepLinkService _deepLinks;
  final RedirectService _redirects;

  /// Log prefix — filter the Xcode console by `PERSONALLY` to follow the flow.
  static const String _scope = 'Flow';

  // ---- Observable state -----------------------------------------------------

  ConnectionPhase _phase = ConnectionPhase.welcome;
  ConnectionPhase get phase => _phase;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Human-readable line shown under the spinner while working.
  String _statusLine = '';
  String get statusLine => _statusLine;

  Set<String> _grantedScopes = <String>{};
  Set<String> get grantedScopes => _grantedScopes;

  /// True once a member session (a deep-link auth token) is available.
  bool get hasSession => _pendingRequest != null;

  /// Whether tapping "Connect" can actually open a connection — either because
  /// the website handed us a token, or because a dev API key lets us mint one.
  bool get canConnect => hasSession || AppConfig.canSelfGenerateToken;

  ConnectRequest? _pendingRequest;

  // ---- Lifecycle ------------------------------------------------------------

  /// Boot the provider: initialise Terra, wire up deep links, and decide the
  /// opening screen. Safe to call once from `main`/app init.
  Future<void> bootstrap() async {
    AppLog.step(_scope, '=== BOOTSTRAP START ===');
    AppLog.step(
      _scope,
      'config → devId=${AppLog.mask(AppConfig.terraDevId)}, '
      'apiKey=${AppConfig.terraApiKey.isEmpty ? "<none>" : "set"}, '
      'canSelfGenerateToken=${AppConfig.canSelfGenerateToken}',
    );

    await _terra.init(AppConfig.terraDevId, AppConfig.defaultReferenceId);

    // Already connected from a previous session? Jump straight to manage.
    if (await _terra.isConnected()) {
      _grantedScopes = await _terra.grantedPermissions();
      AppLog.ok(_scope, 'already connected → showing MANAGE screen');
      _setPhase(ConnectionPhase.manage);
    }

    // A demo token lets you exercise the flow locally without a real link.
    if (AppConfig.demoToken.isNotEmpty && _phase != ConnectionPhase.manage) {
      AppLog.step(_scope, 'DEMO_TOKEN present — pre-loading a session');
      _pendingRequest = ConnectRequest(token: AppConfig.demoToken);
      notifyListeners();
    }

    AppLog.step(
      _scope,
      'listening for deep links (${AppConfig.urlScheme}://connect)',
    );
    await _deepLinks.start(_onConnectRequest);
    AppLog.ok(_scope, '=== BOOTSTRAP DONE === phase=${_phase.name}');
  }

  /// A connect link arrived from the website.
  void _onConnectRequest(ConnectRequest request) {
    AppLog.ok(_scope, 'deep link received → $request');
    _pendingRequest = request;
    _errorMessage = null;
    // A fresh session always lands the member on the welcome/consent screen,
    // even if they were previously on manage.
    _setPhase(ConnectionPhase.welcome);
    // Auto-start so the tap on the website flows straight through.
    AppLog.step(_scope, 'auto-starting connect from deep link');
    connect();
  }

  // ---- Intents (called by the UI) ------------------------------------------

  /// Run the full connect → Apple Health permission → sync flow.
  Future<void> connect() async {
    final sw = Stopwatch()..start();
    AppLog.step(_scope, '=== CONNECT START ===');
    try {
      _setPhase(
        ConnectionPhase.initializing,
        status: 'Opening a secure connection…',
      );

      // Bind Terra to the member's reference id (from the link when present).
      final refId =
          _pendingRequest?.referenceId ?? AppConfig.defaultReferenceId;
      await _terra.init(AppConfig.terraDevId, refId);

      // Resolve a Terra auth token: the website's link takes priority; failing
      // that, mint one in-app if a dev API key is configured.
      final token = await _resolveToken();
      if (token == null) {
        AppLog.fail(_scope, 'no token available → redirecting to the website');
        // Nothing to connect with — send them to the website to start.
        _setPhase(ConnectionPhase.welcome);
        await _redirects.openFunnel();
        return;
      }

      // This opens Apple Health and shows the native HealthKit consent sheet.
      final connected = await _terra.connect(token);
      if (!connected) {
        _fail('We couldn’t connect to Apple Health. Please try again.');
        return;
      }

      // Read Apple Health and push it straight to the Terra webhook.
      _setPhase(
        ConnectionPhase.syncing,
        status: 'Capturing your health history…',
      );
      await _terra.syncAll(onProgress: _onSyncProgress);
      _grantedScopes = await _terra.grantedPermissions();

      _setPhase(ConnectionPhase.connected);
      AppLog.ok(_scope, '=== CONNECT COMPLETE ===', sw.elapsedMilliseconds);
    } catch (e) {
      AppLog.fail(_scope, 'connect threw — $e');
      _fail('Something went wrong while connecting. Please try again.');
    }
  }

  /// The token used to open the connection, or `null` if none can be obtained.
  Future<String?> _resolveToken() async {
    AppLog.step(_scope, 'STEP 2b · resolving an auth token');

    final linked = _pendingRequest?.token;
    if (linked != null && linked.isNotEmpty) {
      AppLog.ok(_scope, 'STEP 2b · using token from deep link / DEMO_TOKEN');
      return linked;
    }

    // Dev/testing fallback (no-op unless TERRA_API_KEY is set).
    AppLog.step(_scope, 'STEP 2b · no linked token — trying to self-generate');
    return _auth.generateToken();
  }

  /// The member chose "Not now" / skipped the consent.
  void skip() => _setPhase(ConnectionPhase.declined);

  /// Return to the main welcome screen — e.g. from the "No problem" (declined)
  /// or connected screens, so the member can start the connect flow again.
  void goToWelcome() {
    _errorMessage = null;
    _statusLine = '';
    _setPhase(ConnectionPhase.welcome);
  }

  /// Retry after an error (or a stalled attempt) — re-runs the connect flow.
  Future<void> retry() => connect();

  /// Disconnect Apple Health: revoke Terra's access and delete its cached copy
  /// of the member's data.
  ///
  /// iOS does not let an app revoke its own HealthKit permission, so this stops
  /// data reaching Terra — the part we control. The member turns the Health
  /// toggles off themselves in Settings › Health › Data Access & Devices, which
  /// the confirmation screen tells them.
  Future<void> disconnect() async {
    final sw = Stopwatch()..start();
    AppLog.step(_scope, '=== DISCONNECT START ===');
    _setPhase(
      ConnectionPhase.initializing,
      status: 'Disconnecting Apple Health…',
    );

    try {
      final userId = await _terra.currentUserId();

      if (userId == null) {
        // Nothing registered on Terra's side — already effectively disconnected.
        AppLog.warn(_scope, 'no Terra user id — already disconnected');
      } else {
        final revoked = await _auth.deauthenticate(userId);
        if (!revoked) {
          _fail('We couldn’t disconnect right now. Please try again.');
          return;
        }
      }

      // Drop any local session so a later connect starts clean.
      _pendingRequest = null;
      _grantedScopes = <String>{};

      _setPhase(ConnectionPhase.disconnected);
      AppLog.ok(_scope, '=== DISCONNECT COMPLETE ===', sw.elapsedMilliseconds);
    } catch (e) {
      AppLog.fail(_scope, 'disconnect threw — $e');
      _fail('Something went wrong while disconnecting.');
    }
  }

  /// Capture the member's Apple Health history again, on demand.
  ///
  /// This is the manual replacement for background syncing: nothing is observed
  /// or uploaded while the app is closed, so the member taps to refresh and
  /// every capture re-sends the full history window.
  Future<void> resync() async {
    final sw = Stopwatch()..start();
    AppLog.step(_scope, '=== MANUAL RESYNC START ===');
    try {
      _setPhase(
        ConnectionPhase.syncing,
        status: 'Capturing your health history…',
      );
      await _terra.syncAll(onProgress: _onSyncProgress);
      _grantedScopes = await _terra.grantedPermissions();
      _setPhase(ConnectionPhase.connected);
      AppLog.ok(
        _scope,
        '=== MANUAL RESYNC COMPLETE ===',
        sw.elapsedMilliseconds,
      );
    } catch (e) {
      AppLog.fail(_scope, 'resync threw — $e');
      _fail('We couldn’t capture your data. Please try again.');
    }
  }

  /// Surfaces per-chunk sync progress (e.g. `daily · 2024  (3/25)`) to the UI.
  void _onSyncProgress(String message) {
    _statusLine = message;
    notifyListeners();
  }

  /// Finish: hand the member back to the website (from the connected/declined
  /// screens). Falls back to the configured site if no redirect was supplied.
  Future<void> finish() async {
    await _redirects.returnToWebsite(redirectUrl: _pendingRequest?.redirectUrl);
  }

  /// "Go to personally.com" from the not-a-member screen.
  Future<void> goToFunnel() => _redirects.openFunnel();

  // ---- Helpers --------------------------------------------------------------

  void _setPhase(ConnectionPhase phase, {String status = ''}) {
    AppLog.step(
      _scope,
      'screen → ${phase.name.toUpperCase()}'
      '${status.isEmpty ? "" : "  ($status)"}',
    );
    _phase = phase;
    _statusLine = status;
    if (phase != ConnectionPhase.error) _errorMessage = null;
    notifyListeners();
  }

  void _fail(String message) {
    AppLog.fail(_scope, 'screen → ERROR: $message');
    _phase = ConnectionPhase.error;
    _errorMessage = message;
    _statusLine = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _deepLinks.dispose();
    super.dispose();
  }
}
