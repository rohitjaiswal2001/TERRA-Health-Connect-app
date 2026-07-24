import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/pairing_code.dart';

/// A pairing attempt that failed for a reason worth showing the member.
class PairingException implements Exception {
  const PairingException(this.message);

  /// Already phrased for the UI — show it as-is.
  final String message;

  @override
  String toString() => 'PairingException: $message';
}

/// Exchanges a short pairing code for the member's Personally user id.
///
/// This covers the fresh-install case: iOS drops the `ref` parameter when it
/// detours through the App Store, so the app comes up not knowing who it is
/// for. The member types the code shown on the website (or scans the QR) and
/// this call resolves it to the id Terra needs as its `reference_id`.
///
/// `POST {base}/api/wearable-pair  {"code": "K4T9PX"}  →  {"userId": "…"}`
///
/// No authentication: the code *is* the credential. It is single use, expires
/// after 30 minutes, and resolves to an id only — never a session or a token.
class PairingService {
  PairingService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.pairingApiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const String _scope = 'Pairing';
  static const Duration _timeout = Duration(seconds: 20);

  Uri get endpoint => Uri.parse(
        _baseUrl.replaceAll(RegExp(r'/+$'), '') + AppConfig.pairingEndpointPath,
      );

  /// Redeems [code] and returns the Personally user id.
  ///
  /// Throws a [PairingException] with a member-facing message when the code is
  /// malformed, unknown, already used, expired, or the site can't be reached.
  Future<String> redeem(String code) async {
    final normalized = PairingCode.normalize(code);
    if (!PairingCode.isValid(normalized)) {
      throw const PairingException(
        'That code needs all 6 characters. Check it and try again.',
      );
    }

    AppLog.step(_scope, 'POST $endpoint · code=$normalized');
    final sw = Stopwatch()..start();

    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              // Free-tier ngrok otherwise answers with an HTML interstitial.
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'code': normalized}),
          )
          .timeout(_timeout);
    } catch (e) {
      AppLog.fail(_scope, 'request failed — $e');
      throw const PairingException(
        'We couldn’t reach Personally. Check your connection and try again.',
      );
    }

    final body = _decode(response.body);

    if (response.statusCode == 200) {
      final userId = (body?['userId'] as String?)?.trim();
      if (userId != null && userId.isNotEmpty) {
        AppLog.ok(_scope, 'code redeemed → userId=$userId',
            sw.elapsedMilliseconds);
        return userId;
      }
      AppLog.fail(_scope, 'HTTP 200 without a userId — ${response.body}');
      throw const PairingException(
        'Something went wrong on our side. Please try that code again.',
      );
    }

    AppLog.fail(
      _scope,
      'rejected (HTTP ${response.statusCode}) ${response.body}',
    );
    throw PairingException(_messageFor(response.statusCode, body));
  }

  /// The endpoint's error bodies are already written for members, so prefer
  /// them; the fallbacks cover a proxy or tunnel answering instead.
  String _messageFor(int status, Map<String, dynamic>? body) {
    final serverMessage = (body?['error'] as String?)?.trim();
    if (serverMessage != null && serverMessage.isNotEmpty) return serverMessage;

    return switch (status) {
      400 => 'That code doesn’t look right. Check the 6 characters.',
      404 => 'That code is not valid.',
      410 => 'That code has expired or has already been used.',
      _ => 'We couldn’t pair right now. Please try again in a moment.',
    };
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      // Not JSON — usually a tunnel/proxy HTML page rather than the API.
      return null;
    }
  }

  void dispose() => _client.close();
}
