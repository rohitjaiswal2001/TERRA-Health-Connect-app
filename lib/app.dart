import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/connection_provider.dart';
import 'screens/home_router.dart';

/// Root widget. Hosts the single [ConnectionProvider], already bootstrapped in
/// `main` before the first frame, so the app's very first screen is the real
/// destination rather than a loading placeholder.
class PersonallyApp extends StatelessWidget {
  const PersonallyApp({super.key, required this.provider});

  final ConnectionProvider provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConnectionProvider>.value(
      value: provider,
      child: MaterialApp(
        title: 'Personally',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const HomeRouter(),
      ),
    );
  }
}
