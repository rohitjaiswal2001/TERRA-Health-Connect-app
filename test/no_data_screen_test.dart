// Smoke test for the "connected but no data" screen: it must render its
// explanation, the exact Settings path, and both recovery actions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:personally/providers/connection_provider.dart';
import 'package:personally/screens/no_data_screen.dart';

void main() {
  testWidgets('NoDataScreen shows the reason, the fix and both actions',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectionProvider>(
        create: (_) => ConnectionProvider(),
        child: const MaterialApp(home: NoDataScreen()),
      ),
    );

    expect(find.text('No data yet'), findsOneWidget);
    // Honest framing: connected, but nothing arrived.
    expect(find.textContaining('no Apple Health data is coming through'),
        findsOneWidget);
    // The one place iOS lets a member change Health read access.
    expect(find.textContaining('Settings › Health › Data Access & Devices'),
        findsOneWidget);
    // Both ways forward.
    expect(find.text('Re-sync'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
  });
}
