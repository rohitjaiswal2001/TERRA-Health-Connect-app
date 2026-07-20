import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Screen B — Not-yet-a-member. No signup or purchase in the app; purchase
/// stays on the website. Routes the visitor back to the funnel.
class NotMemberScreen extends StatelessWidget {
  const NotMemberScreen({super.key});

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
          const Center(child: AppEyebrow('Members only', onDark: true)),
          const SizedBox(height: 12),
          Text(
            'This app is for members',
            textAlign: TextAlign.center,
            style: AppType.heading(color: AppColors.white),
          ),
          const SizedBox(height: 12),
          Text(
            "The app powers your ongoing formula once you've joined. Start with "
            'your quiz on personally.com and build your formula first.',
            textAlign: TextAlign.center,
            style: AppType.body(color: AppColors.mutedOnDark),
          ),
          const Spacer(),
          PlButton(
            label: 'Go to personally.com',
            style: PlButtonStyle.lime,
            onPressed: () => context.read<ConnectionProvider>().goToFunnel(),
          ),
        ],
      ),
    );
  }
}
