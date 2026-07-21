import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Recoverable failure. Offers a retry and an escape back to the website.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.select<ConnectionProvider, String?>((p) => p.errorMessage);

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
              child: const Icon(Icons.refresh, color: AppColors.white, size: 28),
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: AppEyebrow('Something went wrong', onDark: true)),
          const SizedBox(height: 12),
          Text(
            'Let’s try that again',
            textAlign: TextAlign.center,
            style: AppType.heading(color: AppColors.white),
          ),
          const SizedBox(height: 12),
          Text(
            message ?? 'We couldn’t complete the connection. Please try again.',
            textAlign: TextAlign.center,
            style: AppType.body(color: AppColors.mutedOnDark),
          ),
          const Spacer(),
          PlButton(
            label: 'Try again',
            style: PlButtonStyle.solid,
            onDark: true,
            onPressed: () => context.read<ConnectionProvider>().retry(),
          ),
          const SizedBox(height: 12),
          PlButton(
            label: 'Back to home',
            style: PlButtonStyle.ghost,
            onDark: true,
            onPressed: () => context.read<ConnectionProvider>().goToWelcome(),
          ),
        ],
      ),
    );
  }
}
