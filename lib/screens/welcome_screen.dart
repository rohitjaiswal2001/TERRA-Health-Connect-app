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
          // Confirms which account this app is paired to, and gives a way out
          // if the member paired the wrong one.
          if (provider.isPaired) const _PairedNote(),
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

/// "Paired to your account · Not you?" — reassurance that the code landed,
/// plus a way back to the pairing screen if it was the wrong one.
class _PairedNote extends StatelessWidget {
  const _PairedNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 15,
            color: AppColors.subtleOnDark,
          ),
          const SizedBox(width: 7),
          Text(
            'Paired to your account',
            style: AppType.label(color: AppColors.subtleOnDark),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () => PlScaffold.confirmAndLogout(context),
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Not you?',
              style: AppType.label(color: AppColors.mutedOnDark).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColors.subtleOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
