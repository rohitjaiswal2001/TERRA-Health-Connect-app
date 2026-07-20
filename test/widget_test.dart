// Smoke tests for the Apple Health bridge.
//
// These exercise the pure Dart logic that doesn't need the native Terra
// channel — chiefly deep-link parsing, which is the app's entry contract with
// the website.

import 'package:flutter_test/flutter_test.dart';
import 'package:personally/models/connect_request.dart';

void main() {
  group('ConnectRequest.fromUri', () {
    test('parses a custom-scheme connect link', () {
      final uri = Uri.parse(
        'personallyhealth://connect'
        '?token=abc123'
        '&reference_id=member-42'
        '&redirect=https%3A%2F%2Fpersonally.com%2Fdone',
      );

      final request = ConnectRequest.fromUri(uri);

      expect(request, isNotNull);
      expect(request!.token, 'abc123');
      expect(request.referenceId, 'member-42');
      expect(request.redirectUrl, 'https://personally.com/done');
    });

    test('parses an https universal link', () {
      final uri = Uri.parse('https://personally.com/connect?token=xyz');
      final request = ConnectRequest.fromUri(uri);

      expect(request, isNotNull);
      expect(request!.token, 'xyz');
      expect(request.referenceId, isNull);
      expect(request.redirectUrl, isNull);
    });

    test('returns null when there is no token', () {
      final uri = Uri.parse('personallyhealth://connect?reference_id=member-42');
      expect(ConnectRequest.fromUri(uri), isNull);
    });

    test('returns null for an unrelated link', () {
      final uri = Uri.parse('personallyhealth://settings');
      expect(ConnectRequest.fromUri(uri), isNull);
    });
  });
}
