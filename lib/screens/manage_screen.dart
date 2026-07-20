import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/terra_scopes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/data_scope_list.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';

/// Screen 04 — Manage connection. Shows exactly what Personally reads and an
/// easy way out. Trust is kept, not just won.
class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlScaffold(
      ground: PlGround.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const PlLogo.small(color: AppColors.ink),
            const SizedBox(height: 32),
            const AppEyebrow('Settings · Data'),
            const SizedBox(height: 16),
            Text('Apple Health', style: AppType.heading(color: AppColors.ink)),
            const SizedBox(height: 12),
            _card(),
            const SizedBox(height: 24),
            // Nothing syncs in the background — this is how a member refreshes.
            PlButton(
              label: 'Capture my data now',
              style: PlButtonStyle.solid,
              onPressed: () => context.read<ConnectionProvider>().resync(),
            ),
            const SizedBox(height: 12),
            _disconnectButton(context),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: 'We never sell your data. ',
                style: AppType.label(color: AppColors.stone),
                children: [
                  TextSpan(
                    text: 'Privacy policy',
                    style: AppType.label(color: AppColors.ink)
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Apple Health',
                  style: AppType.button(color: AppColors.ink).copyWith(fontSize: 15)),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                        color: AppColors.ink, shape: BoxShape.circle),
                  ),
                  Text('CONNECTED',
                      style: AppType.eyebrow(color: AppColors.stone)
                          .copyWith(fontSize: 12, letterSpacing: 0.6)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          DataScopeList(labels: TerraScopes.categoryLabels),
        ],
      ),
    );
  }

  Widget _disconnectButton(BuildContext context) {
    return PlButton(
      label: 'Disconnect Apple Health',
      style: PlButtonStyle.danger,
      onPressed: () => _confirmDisconnect(context),
    );
  }

  /// Brand-styled confirmation — same palette and type as every other surface.
  Future<void> _confirmDisconnect(BuildContext context) async {
    final provider = context.read<ConnectionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Disconnect Apple Health?',
          style: AppType.heading(color: AppColors.ink).copyWith(fontSize: 19),
        ),
        content: Text(
          'Personally will stop receiving your health data, and the copy we '
          'hold will be deleted. You can reconnect anytime.',
          style: AppType.body(color: AppColors.stone),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel',
                style: AppType.button(color: AppColors.stone).copyWith(fontSize: 15)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Disconnect',
                style: AppType.button(color: AppColors.red).copyWith(fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await provider.disconnect();
  }
}
