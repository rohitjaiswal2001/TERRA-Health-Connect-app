import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Shown when Apple Health connected but the first capture brought back nothing
/// from any category.
///
/// iOS never reveals which individual read permissions a member granted, so the
/// app can't say "you declined Heart". What it *can* see is that no data at all
/// arrived — the honest signal that the categories were most likely left off in
/// the consent sheet (or there's simply no recent data on this device). So this
/// screen states that plainly, points to the one place iOS lets them change it,
/// and offers a re-sync — no false "you're connected", no blame.
class NoDataScreen extends StatelessWidget {
  const NoDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlScaffold(
      ground: PlGround.dark,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Center(child: PlLogo.small()),
            const SizedBox(height: 40),
            Center(child: _icon()),
            const SizedBox(height: 24),
            const Center(
              child: AppEyebrow('Apple Health connected', onDark: true),
            ),
            const SizedBox(height: 12),
            Text(
              'No data yet',
              textAlign: TextAlign.center,
              style: AppType.heading(color: AppColors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'The connection is on, but no Apple Health data is coming through. '
              'That usually means the categories were left off when you '
              'connected — or there’s no recent data on this device.',
              textAlign: TextAlign.center,
              style: AppType.body(color: AppColors.mutedOnDark),
            ),
            const SizedBox(height: 22),
            const _EnableSteps(),
            const SizedBox(height: 28),
            PlButton(
              label: 'Re-sync',
              style: PlButtonStyle.solid,
              onDark: true,
              onPressed: () => context.read<ConnectionProvider>().resync(),
            ),
            const SizedBox(height: 4),
            PlButton(
              label: 'Continue anyway',
              style: PlButtonStyle.ghost,
              onDark: true,
              onPressed: () => context.read<ConnectionProvider>().finish(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon() {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.subtleOnDark, width: 2),
      ),
      child: const Icon(
        Icons.monitor_heart_outlined,
        color: AppColors.white,
        size: 30,
      ),
    );
  }
}

/// The exact, ordered path to turn the categories on. iOS offers no deep link
/// into an app's Health permissions, so a member has to walk there themselves —
/// spelling it out is the most honest help we can give. The wording mirrors the
/// disconnected screen so "where the Health toggles live" reads the same
/// everywhere in the app.
class _EnableSteps extends StatelessWidget {
  const _EnableSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Open Settings › Health › Data Access & Devices',
      'Tap Personally',
      'Turn on the categories you want to share',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineDark),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stepNumber(i + 1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppType.body(color: AppColors.cream)
                          .copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepNumber(int n) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$n',
        style: AppType.eyebrow(color: AppColors.black)
            .copyWith(fontSize: 12, letterSpacing: 0),
      ),
    );
  }
}
