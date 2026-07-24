// Tests for the wearable pairing path: what a scanned QR can contain, and how
// the pairing endpoint's responses reach the member.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personally/core/config/app_config.dart';
import 'package:personally/models/pairing_payload.dart';
import 'package:personally/services/pairing_service.dart';

void main() {
  group('PairingPayload.parse', () {
    test('reads the reference id straight off a connect link', () {
      final payload = PairingPayload.parse(
        'personallyhealth://connect?ref=8582be1f-a59b-4c5a-835b-b6842553d7ce',
      );

      expect(payload?.isResolved, isTrue);
      expect(payload?.referenceId, '8582be1f-a59b-4c5a-835b-b6842553d7ce');
    });

    test('reads a code from a query parameter', () {
      final payload = PairingPayload.parse('https://personally.com/p?code=k4t9px');

      expect(payload?.isResolved, isFalse);
      expect(payload?.code, 'K4T9PX');
    });

    test('reads a code from the last path segment', () {
      final payload = PairingPayload.parse('https://personally.com/pair/K4T9PX');
      expect(payload?.code, 'K4T9PX');
    });

    test('accepts a bare code, normalising case and spacing', () {
      expect(PairingPayload.parse(' k4t9 px ')?.code, 'K4T9PX');
    });

    test('accepts a bare user id', () {
      const id = '8582be1f-a59b-4c5a-835b-b6842553d7ce';
      expect(PairingPayload.parse(id)?.referenceId, id);
    });

    test('rejects anything else', () {
      expect(PairingPayload.parse('https://example.com/hello'), isNull);
      expect(PairingPayload.parse('not-a-code'), isNull);
      expect(PairingPayload.parse(''), isNull);
    });
  });

  group('PairingService.redeem', () {
    PairingService serviceReturning(
      int status,
      Object? body, {
      void Function(http.Request request)? onCall,
    }) {
      return PairingService(
        baseUrl: 'https://example.test/',
        client: MockClient((request) async {
          onCall?.call(request);
          return http.Response(
            body is String ? body : jsonEncode(body),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
    }

    test('returns the user id and posts the normalised code', () async {
      late http.Request seen;
      final service = serviceReturning(
        200,
        {'userId': '8582be1f-a59b-4c5a-835b-b6842553d7ce'},
        onCall: (request) => seen = request,
      );

      final userId = await service.redeem('k4t9-px');

      expect(userId, '8582be1f-a59b-4c5a-835b-b6842553d7ce');
      expect(seen.url.path, AppConfig.pairingEndpointPath);
      expect(jsonDecode(seen.body), {'code': 'K4T9PX'});
      expect(seen.headers['ngrok-skip-browser-warning'], 'true');
    });

    test('never calls out for a malformed code', () async {
      var called = false;
      final service = PairingService(
        baseUrl: 'https://example.test',
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        service.redeem('K4T9'),
        throwsA(isA<PairingException>()),
      );
      expect(called, isFalse);
    });

    test('surfaces the endpoint’s own wording for a used code', () async {
      final service = serviceReturning(
        410,
        {'error': 'That code has already been used'},
      );

      await expectLater(
        service.redeem('K4T9PX'),
        throwsA(
          isA<PairingException>().having(
            (e) => e.message,
            'message',
            'That code has already been used',
          ),
        ),
      );
    });

    test('falls back to its own wording when the body is not JSON', () async {
      // What free-tier ngrok serves instead of the API.
      final service = serviceReturning(404, '<html>interstitial</html>');

      await expectLater(
        service.redeem('K4T9PX'),
        throwsA(
          isA<PairingException>()
              .having((e) => e.message, 'message', contains('not valid')),
        ),
      );
    });

    test('turns a network failure into a member-facing message', () async {
      final service = PairingService(
        baseUrl: 'https://example.test',
        client: MockClient((_) async => throw const SocketFailure()),
      );

      await expectLater(
        service.redeem('K4T9PX'),
        throwsA(
          isA<PairingException>()
              .having((e) => e.message, 'message', contains('couldn’t reach')),
        ),
      );
    });
  });
}

/// Stand-in for a dropped connection.
class SocketFailure implements Exception {
  const SocketFailure();
}
