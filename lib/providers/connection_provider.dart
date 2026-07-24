import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/pairing_code.dart';
import '../models/connect_request.dart';
import '../models/connection_phase.dart';
import '../models/pairing_payload.dart';
import '../services/deep_link_service.dart';
import '../services/pairing_service.dart';
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
    PairingService? pairing,
  }) : _terra = terra ?? TerraService(),
       _auth = auth ?? TerraAuthService(),
       _deepLinks = deepLinks ?? DeepLinkService(),
       _redirects = redirects ?? const RedirectService(),
       _pairingApi = pairing ?? PairingService();

  final TerraService _terra;
  final TerraAuthService _auth;
  final DeepLinkService _deepLinks;
  final RedirectService _redirects;
  final PairingService _pairingApi;

  /// Log prefix — filter the Xcode console by `PERSONALLY` to follow the flow.
  static const String _scope = 'Flow';

  /// How long each Terra call during launch may take before we give up and
  /// carry on. This is the only thing standing between the native splash and a
  /// dead network: without it a hung `initSDK` would hold the splash forever.
  static const Duration _probeTimeout = Duration(seconds: 6);

  // ---- Observable state -----------------------------------------------------

  /// Starts at [ConnectionPhase.launching], the sentinel bootstrap replaces
  /// with the real opening screen. Since bootstrap completes before `runApp`,
  /// the UI's first frame is that real screen — this value is never rendered.
  ConnectionPhase _phase = ConnectionPhase.launching;
  ConnectionPhase get phase => _phase;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Human-readable line shown under the spinner while working.
  String _statusLine = '';
  String get statusLine => _statusLine;

  Set<String> _grantedScopes = <String>{};
  Set<String> get grantedScopes => _grantedScopes;

  /// True once we know which member this is — from a deep link, a redeemed
  /// pairing code, or a demo token.
  bool get hasSession => _pendingRequest != null;

  /// Whether tapping "Connect" can actually open a connection — either because
  /// the website handed us a token, or because a dev API key lets us mint one.
  bool get canConnect => hasSession || AppConfig.canSelfGenerateToken;

  ConnectRequest? _pendingRequest;

  // ---- Pairing state --------------------------------------------------------

  /// The member's Personally user id, once known. Terra's `reference_id`.
  String? get referenceId => _pendingRequest?.referenceId;

  /// Whether the app knows which Personally account it is connecting.
  bool get isPaired => referenceId != null;

  /// True while a pairing code is being exchanged for a user id.
  bool _isPairing = false;
  bool get isPairing => _isPairing;

  /// Why the last pairing attempt failed — already phrased for the member.
  String? _pairingError;
  String? get pairingError => _pairingError;

  // ---- Lifecycle ------------------------------------------------------------

  /// Decide the opening screen and wire up deep links. Runs before the first
  /// frame (from `main`), so the native launch screen covers it — keep it as
  /// short as it can be, and never let a slow network stretch it unbounded.
  Future<void> bootstrap() async {
    AppLog.step(_scope, '=== BOOTSTRAP START ===');
    AppLog.step(
      _scope,
      'config → devId=${AppLog.mask(AppConfig.terraDevId)}, '
      'apiKey=${AppConfig.terraApiKey.isEmpty ? "<none>" : "set"}, '
      'canSelfGenerateToken=${AppConfig.canSelfGenerateToken}',
    );

    // Local test seeds — a fixed id and/or a hand-generated token — that stand
    // in for a real link. Neither touches the network or picks a screen.
    if (AppConfig.referenceIdOverride.isNotEmpty) {
      AppLog.step(_scope, 'TERRA_REFERENCE_ID set — running as a paired member');
      _pendingRequest = const ConnectRequest(
        referenceId: AppConfig.referenceIdOverride,
      );
    }
    if (AppConfig.demoToken.isNotEmpty) {
      AppLog.step(_scope, 'DEMO_TOKEN present — pre-loading a session');
      _pendingRequest = (_pendingRequest ?? const ConnectRequest())
          .copyWith(token: AppConfig.demoToken);
    }

    // Read the cold-start link first: it's a fast, local OS read, and when the
    // website launched us with a ref/token it alone decides the screen. So the
    // common funnel flow reaches its screen without waiting on Terra at all.
    AppLog.step(
      _scope,
      'listening for deep links (${AppConfig.urlScheme}://connect?ref=…)',
    );
    await _deepLinks.start(_onConnectRequest);

    if (_phase != ConnectionPhase.launching) {
      AppLog.ok(_scope, '=== BOOTSTRAP DONE === the deep link chose '
          '${_phase.name.toUpperCase()}');
      return;
    }

    // A direct open, with no link. This is the only case that needs Terra — to
    // tell a returning, already-connected member (→ manage) apart from someone
    // who still has to pair. The probe is time-boxed so a dead network can't
    // hold the splash: on timeout we treat it as "not connected" and move on.
    final connected = await _probeExistingConnection();

    // Without a reference id — typically a fresh install, where iOS dropped the
    // link's `ref` on the detour through the App Store — that means pairing.
    _setPhase(switch ((connected, hasSession)) {
      (true, _) => ConnectionPhase.manage,
      (false, true) => ConnectionPhase.welcome,
      (false, false) => ConnectionPhase.pairing,
    });

    AppLog.ok(_scope, '=== BOOTSTRAP DONE === phase=${_phase.name}');
  }

  /// Ask Terra whether Apple Health is already connected, with every call
  /// capped at [_probeTimeout]. Any timeout or failure resolves to `false` —
  /// the safe default, since it just routes the member to pair rather than
  /// wrongly assuming a connection.
  Future<bool> _probeExistingConnection() async {
    final initOk = await _terra
        .init(AppConfig.terraDevId, referenceId ?? AppConfig.bootstrapReferenceId)
        .timeout(
      _probeTimeout,
      onTimeout: () {
        AppLog.warn(_scope, 'Terra init timed out '
            '(${_probeTimeout.inSeconds}s) — assuming not connected');
        return false;
      },
    );
    if (!initOk) return false;

    final connected = await _terra.isConnected().timeout(
      _probeTimeout,
      onTimeout: () {
        AppLog.warn(_scope, 'connection probe timed out — assuming not connected');
        return false;
      },
    );
    if (!connected) return false;

    _grantedScopes = await _terra.grantedPermissions().timeout(
      _probeTimeout,
      onTimeout: () {
        AppLog.warn(_scope, 'permissions read timed out — showing manage anyway');
        return <String>{};
      },
    );
    AppLog.ok(_scope, 'an Apple Health connection already exists');
    return true;
  }

  /// A connect link arrived from the website.
  void _onConnectRequest(ConnectRequest request) {
    AppLog.ok(_scope, 'deep link received → $request');
    _pendingRequest = request;
    _errorMessage = null;
    _pairingError = null;
    // A fresh session always lands the member on the welcome/consent screen,
    // even if they were previously on manage or pairing.
    _setPhase(ConnectionPhase.welcome);

    // A backend-minted token means the member already consented on the website,
    // so flow straight through. A `ref`-only link is just an identification —
    // the member still gives consent here, on the welcome screen.
    final token = request.token;
    if (token != null && token.isNotEmpty) {
      AppLog.step(_scope, 'auto-starting connect from deep link');
      connect();
    }
  }

  // ---- Intents (called by the UI) ------------------------------------------

  /// Run the full connect → Apple Health permission → sync flow.
  Future<void> connect() async {
    final sw = Stopwatch()..start();
    AppLog.step(_scope, '=== CONNECT START ===');

    // Never connect as an invented member: without a real reference id the
    // data would land on a Terra user that maps to no Personally account.
    final refId = referenceId;
    if (refId == null) {
      AppLog.fail(_scope, 'no reference id → back to PAIRING');
      goToPairing();
      return;
    }

    try {
      _setPhase(
        ConnectionPhase.initializing,
        status: 'Opening a secure connection…',
      );

      // Bind Terra to the member's reference id.
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
      final outcome = await _terra.syncAll(onProgress: _onSyncProgress);
      _grantedScopes = await _terra.grantedPermissions();

      // The connection opened, but if not one category returned any data the
      // member almost certainly declined the types in the consent sheet — send
      // them to the "no data" screen to turn them on rather than a hollow
      // "you're connected" they'd rightly distrust.
      _setPhase(
        outcome.anyData ? ConnectionPhase.connected : ConnectionPhase.noData,
      );
      AppLog.ok(
        _scope,
        '=== CONNECT COMPLETE === $outcome → ${_phase.name}',
        sw.elapsedMilliseconds,
      );
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

  // ---- Pairing intents ------------------------------------------------------

  /// Redeem a code the member typed in. On success they land on the welcome
  /// screen with their reference id known.
  Future<void> submitPairingCode(String code) async {
    final normalized = PairingCode.normalize(code);
    if (!PairingCode.isValid(normalized)) {
      _failPairing('Enter all 6 characters shown on the website.');
      return;
    }
    await _redeemCode(normalized);
  }

  /// Handle a scanned QR code. The website's QR may carry the connect link
  /// itself (reference id included — nothing to redeem) or a pairing code.
  Future<void> submitScannedCode(String rawValue) async {
    final payload = PairingPayload.parse(rawValue);
    if (payload == null) {
      AppLog.warn(_scope, 'scanned value is not a Personally code');
      _failPairing('That QR code isn’t a Personally pairing code.');
      return;
    }

    AppLog.ok(_scope, 'scanned → $payload');
    final reference = payload.referenceId;
    if (reference != null) {
      // The QR was the connect link — we already have what we need.
      _completePairing(reference, via: 'QR link');
      return;
    }

    await _redeemCode(payload.code!);
  }

  /// Send the member back to the pairing screen (e.g. "not your account?").
  void goToPairing() {
    _pairingError = null;
    _setPhase(ConnectionPhase.pairing);
  }

  /// Clear a pairing error as soon as the member starts editing the code.
  void clearPairingError() {
    if (_pairingError == null) return;
    _pairingError = null;
    notifyListeners();
  }

  Future<void> _redeemCode(String code) async {
    if (_isPairing) return;

    _isPairing = true;
    _pairingError = null;
    notifyListeners();

    try {
      final userId = await _pairingApi.redeem(code);
      _completePairing(userId, via: 'pairing code');
    } on PairingException catch (e) {
      _failPairing(e.message);
    } catch (e) {
      AppLog.fail(_scope, 'pairing threw — $e');
      _failPairing('We couldn’t pair right now. Please try again.');
    } finally {
      _isPairing = false;
      notifyListeners();
    }
  }

  /// We know who the member is — keep any token/redirect we already had and
  /// move on to the consent screen.
  void _completePairing(String userId, {required String via}) {
    AppLog.ok(_scope, 'paired via $via → referenceId=$userId');
    _pendingRequest = (_pendingRequest ?? const ConnectRequest())
        .copyWith(referenceId: userId);
    _pairingError = null;
    _errorMessage = null;
    _setPhase(ConnectionPhase.welcome);
  }

  void _failPairing(String message) {
    AppLog.fail(_scope, 'pairing failed — $message');
    _pairingError = message;
    notifyListeners();
  }

  // ---- Connect intents ------------------------------------------------------

  /// The member chose "Not now" / skipped the consent.
  void skip() => _setPhase(ConnectionPhase.declined);

  /// Return to the main welcome screen — e.g. from the "No problem" (declined)
  /// or connected screens, so the member can start the connect flow again.
  /// Falls back to pairing when we still don't know which account this is.
  void goToWelcome() {
    _errorMessage = null;
    _statusLine = '';
    _setPhase(hasSession ? ConnectionPhase.welcome : ConnectionPhase.pairing);
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

      // Drop the auth token so a later connect starts clean, but keep the
      // reference id — it's still the same member, and their pairing code was
      // single-use, so making them pair again would strand them.
      _pendingRequest = _pendingRequest?.referenceId == null
          ? null
          : ConnectRequest(
              referenceId: _pendingRequest!.referenceId,
              redirectUrl: _pendingRequest!.redirectUrl,
            );
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
      final outcome = await _terra.syncAll(onProgress: _onSyncProgress);
      _grantedScopes = await _terra.grantedPermissions();
      // A re-sync that still brings back nothing keeps them on the "no data"
      // screen; the moment anything flows, they graduate to connected.
      _setPhase(
        outcome.anyData ? ConnectionPhase.connected : ConnectionPhase.noData,
      );
      AppLog.ok(
        _scope,
        '=== MANUAL RESYNC COMPLETE === $outcome → ${_phase.name}',
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
    _pairingApi.dispose();
    super.dispose();
  }
}
