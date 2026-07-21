import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Screen A — Permission declined / skipped. Never block, never nag: the member
/// can connect later from the website, and their formula still works.
class DeclinedScreen extends StatelessWidget {
  const DeclinedScreen({super.key});

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
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: AppEyebrow('No rush', onDark: true)),
          const SizedBox(height: 12),
          Text(
            'No problem',
            textAlign: TextAlign.center,
            style: AppType.heading(color: AppColors.white),
          ),
          const SizedBox(height: 12),
          Text(
            "You can connect Apple Health anytime from Settings when you're "
            "ready. Your formula still works from everything you've already "
            'told us.',
            textAlign: TextAlign.center,
            style: AppType.body(color: AppColors.mutedOnDark),
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
            label: 'Back',
            style: PlButtonStyle.ghost,
            onDark: true,
            onPressed: () => context.read<ConnectionProvider>().goToWelcome(),
          ),
        ],
      ),
    );
  }
}
