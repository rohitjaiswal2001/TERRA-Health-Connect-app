import 'package:flutter/material.dart';

import 'app.dart';
import 'providers/connection_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap *before* the first frame. iOS keeps the native launch screen up
  // until Flutter draws, so deferring runApp means that one native splash — no
  // Flutter replica, nothing device-size-specific — stays on screen while Terra
  // initialises and the cold-start deep link is read. By the time Flutter
  // paints, the destination screen is already chosen, so the app opens straight
  // onto it with no second splash in between.
  final provider = ConnectionProvider();
  try {
    await provider.bootstrap();
  } catch (e, s) {
    // Never let a bootstrap failure strand the app on the launch screen — the
    // provider defaults to a sensible phase, and its own error handling takes
    // over once the UI is up.
    debugPrint('bootstrap failed, launching anyway: $e\n$s');
  }

  runApp(PersonallyApp(provider: provider));
}
