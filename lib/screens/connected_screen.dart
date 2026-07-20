import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/bloom.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Screen 03 — Connected / syncing. The single earned "lime" moment: a lime
/// check inside a ring, one Bloom glow, reassurance, and the hand-back to the
/// website via "Done".
class ConnectedScreen extends StatelessWidget {
  const ConnectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlScaffold(
      ground: PlGround.dark,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const Padding(padding: EdgeInsets.only(top: 90), child: Bloom()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Center(child: PlLogo.small()),
              const Spacer(),
              _limeCheck(),
              const SizedBox(height: 24),
              const Center(
                child: AppEyebrow(
                  'Apple Health connected',
                  onDark: true,
                  dotColor: AppColors.lime,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You're connected",
                textAlign: TextAlign.center,
                style: AppType.heading(color: AppColors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Your data now flows privately to Personally. We use it to '
                'adapt your formula, and you can disconnect anytime.',
                textAlign: TextAlign.center,
                style: AppType.body(color: AppColors.mutedOnDark),
              ),
              const Spacer(),
              PlButton(
                label: 'Done',
                style: PlButtonStyle.solid,
                onDark: true,
                onPressed: () => context.read<ConnectionProvider>().finish(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _limeCheck() {
    return Center(
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.lime.withValues(alpha: 0.5), width: 2),
        ),
        child: const Icon(Icons.check, color: AppColors.lime, size: 30),
      ),
    );
  }
}
