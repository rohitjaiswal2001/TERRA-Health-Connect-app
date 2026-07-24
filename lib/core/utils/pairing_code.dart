/// Rules for the short pairing code the website shows next to the QR.
///
/// The code is drawn from an unambiguous alphabet (no `0`/`O`, no `1`/`I`/`L`)
/// so it can be read off a screen and typed on a phone without guesswork.
class PairingCode {
  const PairingCode._();

  /// The characters the website draws codes from.
  static const String alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Codes are always this long.
  static const int length = 6;

  static final RegExp _shape = RegExp('^[A-Z0-9]{$length}\$');
  static final RegExp _noise = RegExp('[^A-Z0-9]');

  /// Uppercases and strips spaces/dashes so "k4t9 px" becomes "K4T9PX".
  static String normalize(String raw) =>
      raw.toUpperCase().replaceAll(_noise, '');

  /// Whether [value] is the shape the endpoint accepts (6 alphanumerics).
  /// Deliberately looser than [alphabet] — the server is the authority on
  /// which codes exist, we only reject the obviously malformed.
  static bool isValid(String value) => _shape.hasMatch(value);

  /// Whether a normalized [value] is complete enough to send.
  static bool isComplete(String value) => normalize(value).length == length;
}
