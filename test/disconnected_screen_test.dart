import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:personally/models/connection_phase.dart';
import 'package:personally/providers/connection_provider.dart';
import 'package:personally/services/pairing_service.dart';
import 'package:personally/screens/disconnected_screen.dart';
import 'package:personally/screens/connected_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:personally/screens/welcome_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('ConnectionProvider logout', () {
    test('clears referenceId, pendingRequest, and sets phase to pairing', () async {
      // Mock pairing api returning a valid user ID on redeem.
      final mockPairing = PairingService(
        baseUrl: 'https://example.test/',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({'userId': 'test-member-123'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final provider = ConnectionProvider(pairing: mockPairing);

      // Redeem a code to populate reference ID (paired state).
      await provider.submitPairingCode('K4T9PX');
      expect(provider.referenceId, 'test-member-123');
      expect(provider.isPaired, isTrue);
      expect(provider.phase, ConnectionPhase.welcome);

      // Logout
      provider.logout();

      // Verify state is cleared
      expect(provider.referenceId, isNull);
      expect(provider.isPaired, isFalse);
      expect(provider.phase, ConnectionPhase.pairing);
    });

    test('persists session to SharedPreferences, loads it on bootstrap, and clears it on logout', () async {
      SharedPreferences.setMockInitialValues({
        'personally_token': 'initial-token-xyz',
        'personally_reference_id': 'initial-ref-123',
        'personally_redirect_url': 'https://example.test/return',
      });

      final provider = ConnectionProvider();

      // Bootstrap should load the saved values
      await provider.bootstrap();
      expect(provider.referenceId, 'initial-ref-123');
      expect(provider.isPaired, isTrue);

      // Verify the loaded values in SharedPreferences
      final prefsBefore = await SharedPreferences.getInstance();
      expect(prefsBefore.getString('personally_token'), 'initial-token-xyz');
      expect(prefsBefore.getString('personally_reference_id'), 'initial-ref-123');
      expect(prefsBefore.getString('personally_redirect_url'), 'https://example.test/return');

      // Logout should clear from SharedPreferences
      provider.logout();
      expect(provider.referenceId, isNull);
      expect(provider.isPaired, isFalse);

      // Wait for asynchronous SharedPreferences clear to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final prefsAfter = await SharedPreferences.getInstance();
      expect(prefsAfter.getString('personally_token'), isNull);
      expect(prefsAfter.getString('personally_reference_id'), isNull);
      expect(prefsAfter.getString('personally_redirect_url'), isNull);
    });
  });

  group('DisconnectedScreen widget test', () {
    testWidgets('shows Log out button and tapping it triggers logout', (tester) async {
      final mockPairing = PairingService(
        baseUrl: 'https://example.test/',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({'userId': 'test-member-123'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final provider = ConnectionProvider(pairing: mockPairing);
      await provider.submitPairingCode('K4T9PX');

      // Now we have a session.
      expect(provider.isPaired, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<ConnectionProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: DisconnectedScreen(),
          ),
        ),
      );

      // Verify buttons are rendered
      expect(find.text('Continue to website'), findsOneWidget);
      expect(find.text('Connect again'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);

      // Tap Log out (top right)
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      // Tap Log out in the confirmation dialog
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Log out'),
      ));
      await tester.pumpAndSettle();

      // Verify that logout was called and session is cleared
      expect(provider.isPaired, isFalse);
      expect(provider.phase, ConnectionPhase.pairing);
    });
  });

  group('ConnectedScreen widget test', () {
    testWidgets('shows Log out button and tapping it triggers logout', (tester) async {
      final mockPairing = PairingService(
        baseUrl: 'https://example.test/',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({'userId': 'test-member-123'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final provider = ConnectionProvider(pairing: mockPairing);
      await provider.submitPairingCode('K4T9PX');

      // Now we have a session.
      expect(provider.isPaired, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<ConnectionProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ConnectedScreen(),
          ),
        ),
      );

      // Verify buttons are rendered
      expect(find.text('Continue to website'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);

      // Tap Log out (top right)
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      // Tap Log out in the confirmation dialog
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Log out'),
      ));
      await tester.pumpAndSettle();

      // Verify that logout was called and session is cleared
      expect(provider.isPaired, isFalse);
      expect(provider.phase, ConnectionPhase.pairing);
    });
  });

  group('WelcomeScreen widget test', () {
    testWidgets('shows Not you? link and tapping it triggers logout confirmation dialog', (tester) async {
      final mockPairing = PairingService(
        baseUrl: 'https://example.test/',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({'userId': 'test-member-123'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final provider = ConnectionProvider(pairing: mockPairing);
      await provider.submitPairingCode('K4T9PX');

      expect(provider.isPaired, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<ConnectionProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      // Verify "Not you?" link is visible
      expect(find.text('Not you?'), findsOneWidget);

      // Tap "Not you?"
      await tester.tap(find.text('Not you?'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap Cancel to check it closes dialog without logout
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(provider.isPaired, isTrue);

      // Tap "Not you?" again
      await tester.tap(find.text('Not you?'));
      await tester.pumpAndSettle();

      // Tap "Log out" on the dialog
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Log out'),
      ));
      await tester.pumpAndSettle();

      // Verify logout complete
      expect(provider.isPaired, isFalse);
      expect(provider.phase, ConnectionPhase.pairing);
    });
  });
}
