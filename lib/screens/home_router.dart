import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connection_phase.dart';
import '../providers/connection_provider.dart';
import 'connected_screen.dart';
import 'connecting_screen.dart';
import 'declined_screen.dart';
import 'disconnected_screen.dart';
import 'error_screen.dart';
import 'manage_screen.dart';
import 'not_member_screen.dart';
import 'welcome_screen.dart';

/// Renders exactly one screen for the current [ConnectionPhase]. This is the
/// app's only navigator — the flow is linear and driven entirely by state, so
/// there's no route stack to manage.
class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select<ConnectionProvider, ConnectionPhase>((p) => p.phase);

    final screen = switch (phase) {
      ConnectionPhase.welcome => const WelcomeScreen(),
      ConnectionPhase.initializing => const ConnectingScreen(),
      ConnectionPhase.syncing => const ConnectingScreen(),
      ConnectionPhase.connected => const ConnectedScreen(),
      ConnectionPhase.manage => const ManageScreen(),
      ConnectionPhase.declined => const DeclinedScreen(),
      ConnectionPhase.disconnected => const DisconnectedScreen(),
      ConnectionPhase.notMember => const NotMemberScreen(),
      ConnectionPhase.error => const ErrorScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(phase), child: screen),
    );
  }
}
