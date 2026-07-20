import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Screen 01 — Welcome / why connect. The trust moment: one benefit, one
/// primary (lime) action, an easy out.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();

    return PlScaffold(
      ground: PlGround.dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const PlLogo.small(),
          const Spacer(),
          const AppEyebrow('Your formula, sharper', onDark: true),
          const SizedBox(height: 16),
          Text('Connect your\nhealth data', style: AppType.display()),
          const SizedBox(height: 16),
          Text(
            'Your Personally formula is built around your real data, not a '
            'guess. Connecting Apple Health lets it keep adapting to you as '
            'your body changes.',
            style: AppType.body(color: AppColors.mutedOnDark),
          ),
          const Spacer(),
          PlButton(
            label: 'Connect Apple Health',
            style: PlButtonStyle.lime,
            onPressed: () => context.read<ConnectionProvider>().connect(),
          ),
          const SizedBox(height: 4),
          PlButton(
            label: 'Not now',
            style: PlButtonStyle.ghost,
            onDark: true,
            onPressed: () => context.read<ConnectionProvider>().skip(),
          ),
          // Nudge only when we genuinely can't open a connection.
          if (!provider.canConnect)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Start on personally.com to build your formula first.',
                textAlign: TextAlign.center,
                style: AppType.label(color: AppColors.subtleOnDark),
              ),
            ),
        ],
      ),
    );
  }
}
