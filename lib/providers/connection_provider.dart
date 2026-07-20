import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
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
  })  : _terra = terra ?? TerraService(),
        _auth = auth ?? TerraAuthService(),
        _deepLinks = deepLinks ?? DeepLinkService(),
        _redirects = redirects ?? const RedirectService();

  final TerraService _terra;
  final TerraAuthService _auth;
  final DeepLinkService _deepLinks;
  final RedirectService _redirects;

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
    await _terra.init(AppConfig.terraDevId, AppConfig.defaultReferenceId);

    // Already connected from a previous session? Jump straight to manage.
    if (await _terra.isConnected()) {
      _grantedScopes = await _terra.grantedPermissions();
      _setPhase(ConnectionPhase.manage);
    }

    // A demo token lets you exercise the flow locally without a real link.
    if (AppConfig.demoToken.isNotEmpty && _phase != ConnectionPhase.manage) {
      _pendingRequest = ConnectRequest(token: AppConfig.demoToken);
      notifyListeners();
    }

    await _deepLinks.start(_onConnectRequest);
  }

  /// A connect link arrived from the website.
  void _onConnectRequest(ConnectRequest request) {
    _pendingRequest = request;
    _errorMessage = null;
    // A fresh session always lands the member on the welcome/consent screen,
    // even if they were previously on manage.
    _setPhase(ConnectionPhase.welcome);
    // Auto-start so the tap on the website flows straight through.
    connect();
  }

  // ---- Intents (called by the UI) ------------------------------------------

  /// Run the full connect → Apple Health permission → sync flow.
  Future<void> connect() async {
    try {
      _setPhase(ConnectionPhase.initializing, status: 'Opening a secure connection…');

      // Bind Terra to the member's reference id (from the link when present).
      final refId = _pendingRequest?.referenceId ?? AppConfig.defaultReferenceId;
      await _terra.init(AppConfig.terraDevId, refId);

      // Resolve a Terra auth token: the website's link takes priority; failing
      // that, mint one in-app if a dev API key is configured.
      final token = await _resolveToken();
      if (token == null) {
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
      _setPhase(ConnectionPhase.syncing, status: 'Syncing your health data…');
      await _terra.syncAll();
      _grantedScopes = await _terra.grantedPermissions();

      _setPhase(ConnectionPhase.connected);
    } catch (e) {
      debugPrint('ConnectionProvider.connect failed — $e');
      _fail('Something went wrong while connecting. Please try again.');
    }
  }

  /// The token used to open the connection, or `null` if none can be obtained.
  Future<String?> _resolveToken() async {
    final linked = _pendingRequest?.token;
    if (linked != null && linked.isNotEmpty) return linked;
    // Dev/testing fallback (no-op unless TERRA_API_KEY is set).
    return _auth.generateToken();
  }

  /// The member chose "Not now" / skipped the consent.
  void skip() => _setPhase(ConnectionPhase.declined);

  /// Retry after an error — re-runs the connect flow.
  Future<void> retry() => connect();

  /// Finish: hand the member back to the website (from the connected/declined
  /// screens). Falls back to the configured site if no redirect was supplied.
  Future<void> finish() async {
    await _redirects.returnToWebsite(redirectUrl: _pendingRequest?.redirectUrl);
  }

  /// "Go to personally.com" from the not-a-member screen.
  Future<void> goToFunnel() => _redirects.openFunnel();

  // ---- Helpers --------------------------------------------------------------

  void _setPhase(ConnectionPhase phase, {String status = ''}) {
    _phase = phase;
    _statusLine = status;
    if (phase != ConnectionPhase.error) _errorMessage = null;
    notifyListeners();
  }

  void _fail(String message) {
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
