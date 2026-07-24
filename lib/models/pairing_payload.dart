import '../core/utils/pairing_code.dart';

/// What a scanned QR code (or a typed string) turned out to be.
///
/// The website's QR can carry either of two things, so the app accepts both:
///
/// * the connect link itself — `personallyhealth://connect?ref=<user_id>` —
///   which already contains the reference id and needs no API call;
/// * a pairing code (bare, or as `?code=` / a trailing path segment), which
///   still has to be exchanged for the reference id.
class PairingPayload {
  const PairingPayload.reference(this.referenceId) : code = null;

  const PairingPayload.pairingCode(this.code) : referenceId = null;

  /// A Personally user id, ready to use as Terra's `reference_id`.
  final String? referenceId;

  /// A short pairing code that still needs redeeming.
  final String? code;

  /// True when the reference id is already known — no network call needed.
  bool get isResolved => referenceId != null;

  /// Reads [raw] (a scanned barcode value, or pasted text) and works out which
  /// of the two it is. Returns `null` when it is neither.
  static PairingPayload? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null && (uri.hasScheme || uri.hasAuthority)) {
      return _fromUri(uri);
    }

    return _fromBareValue(value);
  }

  static PairingPayload? _fromUri(Uri uri) {
    final params = uri.queryParameters;

    final reference = _firstOf(params, const [
      'ref',
      'reference_id',
      'referenceId',
      'user_id',
      'userId',
    ]);
    if (reference != null) return PairingPayload.reference(reference);

    final linkedCode = _firstOf(params, const [
      'code',
      'pairing_code',
      'pair',
    ]);
    if (linkedCode != null) {
      final normalized = PairingCode.normalize(linkedCode);
      if (PairingCode.isValid(normalized)) {
        return PairingPayload.pairingCode(normalized);
      }
    }

    // `https://personally.com/pair/K4T9PX` — the code as the last segment.
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final normalized = PairingCode.normalize(segments.last);
      if (PairingCode.isValid(normalized)) {
        return PairingPayload.pairingCode(normalized);
      }
    }

    return null;
  }

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static PairingPayload? _fromBareValue(String value) {
    // A raw user id printed straight into the QR.
    if (_uuid.hasMatch(value)) return PairingPayload.reference(value);

    final normalized = PairingCode.normalize(value);
    if (PairingCode.isValid(normalized)) {
      return PairingPayload.pairingCode(normalized);
    }

    return null;
  }

  static String? _firstOf(Map<String, String> params, List<String> keys) {
    for (final key in keys) {
      final value = params[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  String toString() => isResolved
      ? 'PairingPayload(referenceId: $referenceId)'
      : 'PairingPayload(code: $code)';
}
