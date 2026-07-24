import 'package:flutter/foundation.dart';

/// Lightweight step logger for tracing the connect flow.
///
/// Every line is prefixed with `PERSONALLY` so you can filter the (very noisy)
/// Xcode console down to just this app's trace — type `PERSONALLY` into the
/// console's filter box and you'll see only these steps, in order.
///
/// Icons: ▶️ step started · ✅ step succeeded · ⚠️ recoverable · ❌ failed.
class AppLog {
  const AppLog._();

  static const String _tag = 'PERSONALLY';

  /// The active reference ID (member ID), if known. Included in every log line.
  static String? referenceId;

  /// Masking helper for internal logs, but the reference ID itself is printed.
  static void step(String scope, String message) => _write('▶️', scope, message);

  /// A step finished successfully. Pass [ms] to show how long it took.
  static void ok(String scope, String message, [int? ms]) =>
      _write('✅', scope, ms == null ? message : '$message  (${ms}ms)');

  /// Something non-fatal happened (skipped, empty, retried).
  static void warn(String scope, String message) => _write('⚠️', scope, message);

  /// A step failed.
  static void fail(String scope, String message) => _write('❌', scope, message);

  static void _write(String icon, String scope, String message) {
    if (!kDebugMode) return;
    final refPart = referenceId != null ? ' [ref=$referenceId]' : '';
    debugPrint('$icon $_tag$refPart · $scope › $message');
  }

  /// Masks a secret so traces never leak a full token or key.
  static String mask(String? secret) {
    if (secret == null || secret.isEmpty) return '<empty>';
    final head = secret.substring(0, secret.length.clamp(0, 6));
    return '$head…(${secret.length} chars)';
  }
}
