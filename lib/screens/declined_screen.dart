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
      ground: PlGround.cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Center(child: PlLogo.small(color: AppColors.ink)),
          const Spacer(),
          Center(
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.ink, size: 28),
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: AppEyebrow('No rush')),
          const SizedBox(height: 12),
          Text(
            'No problem',
            textAlign: TextAlign.center,
            style: AppType.heading(color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          Text(
            "You can connect Apple Health anytime from Settings when you're "
            "ready. Your formula still works from everything you've already "
            'told us.',
            textAlign: TextAlign.center,
            style: AppType.body(color: AppColors.stone),
          ),
          const Spacer(),
          PlButton(
            label: 'Continue',
            style: PlButtonStyle.solid,
            onPressed: () => context.read<ConnectionProvider>().finish(),
          ),
          const SizedBox(height: 4),
          PlButton(
            label: 'Back',
            style: PlButtonStyle.ghost,
            onPressed: () => context.read<ConnectionProvider>().goToWelcome(),
          ),
        ],
      ),
    );
  }
}
