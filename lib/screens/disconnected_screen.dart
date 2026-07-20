import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Disconnected confirmation — the mirror of the "No problem" screen.
///
/// Same design system as every other screen: cream ground, ink mark, eyebrow,
/// heading, body, one solid CTA and one ghost. No lime — this isn't a moment to
/// celebrate, and lime is reserved for the primary action and the connected
/// moment only.
///
/// It is deliberately honest about the one thing we *can't* do: iOS won't let an
/// app switch its own Health permissions off, so we tell the member where to.
class DisconnectedScreen extends StatelessWidget {
  const DisconnectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlScaffold(
      ground: PlGround.dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Center(child: PlLogo.small()),
          const Spacer(),
          Center(
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.subtleOnDark, width: 2),
              ),
              child: const Icon(
                Icons.link_off,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: AppEyebrow('Apple Health disconnected', onDark: true),
          ),
          const SizedBox(height: 12),
          Text(
            'You’re disconnected',
            textAlign: TextAlign.center,
            style: AppType.heading(color: AppColors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Personally no longer receives your health data, and the copy we '
            'held has been deleted. You can reconnect anytime.',
            textAlign: TextAlign.center,
            style: AppType.body(color: AppColors.mutedOnDark),
          ),
          const SizedBox(height: 16),
          Text(
            'To also switch off Apple Health access, go to Settings › Health › '
            'Data Access & Devices › Personally.',
            textAlign: TextAlign.center,
            style: AppType.label(color: AppColors.subtleOnDark),
          ),
          const Spacer(),
          PlButton(
            label: 'Continue to website',
            style: PlButtonStyle.solid,
            onDark: true,
            onPressed: () => context.read<ConnectionProvider>().finish(),
          ),
          const SizedBox(height: 12),
          PlButton(
            label: 'Connect again',
            style: PlButtonStyle.lime,
            onDark: true,
            onPressed: () => context.read<ConnectionProvider>().connect(),
          ),
        ],
      ),
    );
  }
}
