import 'package:flutter/foundation.dart';
import 'package:terra_flutter_bridge/terra_flutter_bridge.dart';
import 'package:terra_flutter_bridge/models/enums.dart';
import 'package:terra_flutter_bridge/models/responses.dart';

import '../core/constants/terra_scopes.dart';

/// Thin, testable wrapper around the `terra_flutter_bridge` SDK.
///
/// Everything Terra-specific lives here so the rest of the app talks in plain
/// Dart (`connect`, `sync`, `isConnected`) and never touches the raw bridge.
/// This app only ever uses the **Apple Health** connection.
class TerraService {
  TerraService({this._connection = Connection.appleHealth});

  /// This bridge only ever speaks to Apple Health.
  final Connection _connection;

  static const Duration _historyWindow = Duration(days: 30);

  /// Initialise the SDK. Call once per app launch (and again if the reference
  /// id changes, e.g. a different member opens the app).
  Future<void> init(String devId, String referenceId) async {
    await TerraFlutter.initTerra(devId, referenceId);
  }

  /// Open the Apple Health connection using the single-use [token] issued by
  /// the backend. This triggers the native HealthKit permission sheet.
  ///
  /// Returns `true` when the connection succeeds.
  Future<bool> connect(String token) async {
    final SuccessMessage? result = await TerraFlutter.initConnection(
      _connection,
      token,
      // schedulerOn — Android only; iOS uses setUpBackgroundDelivery instead.
      false,
      TerraScopes.all,
    );
    return result?.success ?? false;
  }

  /// True if a live connection already exists (a Terra user id is present).
  Future<bool> isConnected() async {
    try {
      final UserId? userId = await TerraFlutter.getUserId(_connection);
      return userId?.userId != null && userId!.userId!.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// The set of Apple Health permissions the member actually granted.
  Future<Set<String>> grantedPermissions() async {
    try {
      return await TerraFlutter.getGivenPermissions();
    } catch (_) {
      return <String>{};
    }
  }

  /// Push the last [_historyWindow] of every relevant data type straight to the
  /// Terra webhook. Each call is independent — one failing type must not abort
  /// the rest — so failures are collected and reported, not thrown.
  Future<void> syncAll() async {
    final end = DateTime.now();
    final start = end.subtract(_historyWindow);

    final tasks = <String, Future<DataMessage?> Function()>{
      'daily': () => TerraFlutter.getDaily(_connection, start, end, toWebhook: true),
      'activity': () => TerraFlutter.getActivity(_connection, start, end, toWebhook: true),
      'sleep': () => TerraFlutter.getSleep(_connection, start, end, toWebhook: true),
      'body': () => TerraFlutter.getBody(_connection, start, end, toWebhook: true),
      'menstruation': () =>
          TerraFlutter.getMenstruation(_connection, start, end, toWebhook: true),
    };

    for (final entry in tasks.entries) {
      try {
        await entry.value();
      } catch (e) {
        // A missing data type (e.g. no cycle data) is expected, not fatal.
        debugPrint('Terra sync: "${entry.key}" skipped — $e');
      }
    }
  }
}
