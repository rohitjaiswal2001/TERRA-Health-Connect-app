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
              child: const Icon(Icons.refresh, color: AppColors.ink, size: 28),
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: AppEyebrow('Something went wrong')),
          const SizedBox(height: 12),
          Text(
            'Let’s try that again',
            textAlign: TextAlign.center,
            style: AppType.heading(color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          Text(
            message ?? 'We couldn’t complete the connection. Please try again.',
            textAlign: TextAlign.center,
            style: AppType.body(color: AppColors.stone),
          ),
          const Spacer(),
          PlButton(
            label: 'Try again',
            style: PlButtonStyle.solid,
            onPressed: () => context.read<ConnectionProvider>().retry(),
          ),
          const SizedBox(height: 4),
          PlButton(
            label: 'Back to Personally',
            style: PlButtonStyle.ghost,
            onPressed: () => context.read<ConnectionProvider>().finish(),
          ),
        ],
      ),
    );
  }
}
