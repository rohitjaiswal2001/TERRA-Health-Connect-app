import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/connection_provider.dart';
import 'screens/home_router.dart';

/// Root widget. Owns the single [ConnectionProvider] and bootstraps it (Terra
/// init + deep-link listener) as soon as the tree is mounted.
class PersonallyApp extends StatelessWidget {
  const PersonallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConnectionProvider()..bootstrap(),
      child: MaterialApp(
        title: 'Personally',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const HomeRouter(),
      ),
    );
  }
}
