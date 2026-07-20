import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Shown while the SDK opens the connection and pushes data to Terra
/// (phases: initializing, syncing). Apple's own HealthKit sheet appears on top
/// of this during the permission step.
class ConnectingScreen extends StatelessWidget {
  const ConnectingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<ConnectionProvider, String>(
      (p) => p.statusLine,
    );

    return PlScaffold(
      ground: PlGround.dark,
      center: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlLogo.small(),
          const SizedBox(height: 40),
          const SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(height: 32),
          const AppEyebrow('Please wait', onDark: true),
          const SizedBox(height: 12),
          Text(
            status.isEmpty ? 'Working…' : status,
            textAlign: TextAlign.center,
            style: AppType.body(color: AppColors.mutedOnDark),
          ),
        ],
      ),
    );
  }
}
