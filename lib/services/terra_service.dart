import 'package:terra_flutter_bridge/terra_flutter_bridge.dart';
import 'package:terra_flutter_bridge/models/enums.dart';
import 'package:terra_flutter_bridge/models/responses.dart';

import '../core/config/app_config.dart';
import '../core/constants/terra_scopes.dart';
import '../core/utils/app_logger.dart';

/// One Terra "read this date range and push it to the webhook" call.
typedef _Fetch = Future<DataMessage?> Function(DateTime start, DateTime end);

/// Thin, testable wrapper around the `terra_flutter_bridge` SDK.
///
/// Everything Terra-specific lives here so the rest of the app talks in plain
/// Dart (`connect`, `syncAll`, `isConnected`) and never touches the raw bridge.
/// This app only ever uses the **Apple Health** connection.
///
/// Every step logs through [AppLog] — filter the Xcode console by `PERSONALLY`
/// to see just this trace and spot exactly where a run stalls.
class TerraService {
  TerraService({this._connection = Connection.appleHealth});

  /// This bridge only ever speaks to Apple Health.
  final Connection _connection;

  static const String _scope = 'Terra';

  /// Initialise the SDK. Call once per app launch (and again if the reference
  /// id changes, e.g. a different member opens the app).
  Future<bool> init(String devId, String referenceId) async {
    AppLog.step(_scope, 'STEP 1 · initTerra — devId=${AppLog.mask(devId)} '
        'referenceId=$referenceId');

    if (devId.isEmpty) {
      // An empty dev id is the classic cause of a 400 from /auth/initSDK.
      AppLog.fail(_scope, 'STEP 1 · devId is EMPTY — Terra will reject with 400. '
          'Check TERRA_DEV_ID / AppConfig.terraDevId.');
      return false;
    }

    final sw = Stopwatch()..start();
    try {
      final SuccessMessage? result = await TerraFlutter.initTerra(devId, referenceId);
      final ok = result?.success ?? false;
      if (ok) {
        AppLog.ok(_scope, 'STEP 1 · initTerra done', sw.elapsedMilliseconds);
      } else {
        AppLog.fail(_scope, 'STEP 1 · initTerra failed — ${result?.error ?? "no reason given"}');
      }
      return ok;
    } catch (e) {
      AppLog.fail(_scope, 'STEP 1 · initTerra threw — $e');
      return false;
    }
  }

  /// Open the Apple Health connection using the single-use [token] issued by
  /// the backend. **This is where the native HealthKit consent sheet appears** —
  /// if the trace stops here, the sheet is waiting for the member to respond.
  Future<bool> connect(String token) async {
    AppLog.step(_scope, 'STEP 3 · initConnection(appleHealth) — '
        'token=${AppLog.mask(token)}, ${TerraScopes.all.length} scopes requested');
    AppLog.step(_scope, 'STEP 3 · ⏳ Apple Health permission sheet should appear now…');

    final sw = Stopwatch()..start();
    try {
      final SuccessMessage? result = await TerraFlutter.initConnection(
        _connection,
        token,
        // schedulerOn — Android only; iOS uses setUpBackgroundDelivery instead.
        false,
        TerraScopes.all,
      );
      final ok = result?.success ?? false;
      if (ok) {
        AppLog.ok(_scope, 'STEP 3 · connection opened', sw.elapsedMilliseconds);
      } else {
        AppLog.fail(_scope, 'STEP 3 · connection refused — ${result?.error ?? "no reason given"}');
      }
      return ok;
    } catch (e) {
      AppLog.fail(_scope, 'STEP 3 · initConnection threw — $e');
      return false;
    }
  }

  /// True if a live connection already exists (a Terra user id is present).
  Future<bool> isConnected() async {
    AppLog.step(_scope, 'STEP 2 · checking for an existing connection (getUserId)');
    try {
      final UserId? result = await TerraFlutter.getUserId(_connection);
      final id = result?.userId;
      final connected = id != null && id.isNotEmpty;
      AppLog.ok(_scope, 'STEP 2 · existing connection: '
          '${connected ? "YES (userId=${AppLog.mask(id)})" : "no"}');
      return connected;
    } catch (e) {
      AppLog.warn(_scope, 'STEP 2 · getUserId failed (treating as not connected) — $e');
      return false;
    }
  }

  /// The Terra user id backing the current Apple Health connection, or `null`
  /// when there isn't one. Needed to deauthenticate on disconnect.
  Future<String?> currentUserId() async {
    try {
      final UserId? result = await TerraFlutter.getUserId(_connection);
      final id = result?.userId;
      return (id != null && id.isNotEmpty) ? id : null;
    } catch (e) {
      AppLog.warn(_scope, 'currentUserId failed — $e');
      return null;
    }
  }

  /// The set of Apple Health permissions the member actually granted.
  Future<Set<String>> grantedPermissions() async {
    try {
      final granted = await TerraFlutter.getGivenPermissions();
      AppLog.ok(_scope, 'granted permissions: ${granted.length} → ${granted.join(", ")}');
      return granted;
    } catch (e) {
      AppLog.warn(_scope, 'getGivenPermissions failed — $e');
      return <String>{};
    }
  }

  /// Capture Apple Health history, from [AppConfig.historyDays] days ago up to now,
  /// and push it straight to the Terra webhook in a single quick call.
  Future<void> syncAll({void Function(String message)? onProgress}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: AppConfig.historyDays));

    AppLog.step(_scope, 'STEP 4 · capturing Apple Health data (${_day(start)} → ${_day(end)})');

    onProgress?.call('Capturing health data…');

    final types = <String, _Fetch>{
      'daily': (s, e) => TerraFlutter.getDaily(_connection, s, e, toWebhook: true),
      'activity': (s, e) => TerraFlutter.getActivity(_connection, s, e, toWebhook: true),
      'sleep': (s, e) => TerraFlutter.getSleep(_connection, s, e, toWebhook: true),
      'body': (s, e) => TerraFlutter.getBody(_connection, s, e, toWebhook: true),
      'menstruation': (s, e) =>
          TerraFlutter.getMenstruation(_connection, s, e, toWebhook: true),
    };

    final sw = Stopwatch()..start();
    var sent = 0;

    final results = await Future.wait(
      types.entries.map((entry) async {
        try {
          final result = await entry.value(start, end);
          if (result?.success ?? false) {
            AppLog.ok(_scope, 'STEP 4 · ${entry.key} sent to webhook');
            return true;
          } else {
            AppLog.warn(_scope, 'STEP 4 · ${entry.key} no data (${result?.error ?? "empty"})');
            return false;
          }
        } catch (e) {
          AppLog.warn(_scope, 'STEP 4 · ${entry.key} failed — $e');
          return false;
        }
      }),
    );

    sent = results.where((r) => r).length;
    AppLog.ok(_scope, 'STEP 4 · capture complete in ${sw.elapsedMilliseconds}ms ($sent/${types.length} types pushed)');
  }

  static String _day(DateTime d) => d.toIso8601String().split('T').first;
}
