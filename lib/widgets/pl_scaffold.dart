import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connection_provider.dart';

/// The ground a screen paints on. Mirrors the three screen backgrounds in the
/// design (dark / cream / white).
enum PlGround { dark, cream, white }

/// A brand-consistent page scaffold: sets the background, keeps content within
/// safe areas, and matches the system status-bar icons to the ground.
class PlScaffold extends StatelessWidget {
  const PlScaffold({
    super.key,
    required this.child,
    this.ground = PlGround.dark,
    this.center = false,
    this.showLogout = true,
  });

  final Widget child;
  final PlGround ground;

  /// Center the content vertically (used by the confirmation screens).
  final bool center;

  /// Whether to show the top-right Log out button.
  final bool showLogout;

  @override
  Widget build(BuildContext context) {
    final isDark = ground == PlGround.dark;

    Widget bodyContent = Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: center
          ? Center(child: child)
          : SizedBox(width: double.infinity, child: child),
    );

    if (showLogout) {
      bodyContent = Stack(
        children: [
          bodyContent,
          Positioned(
            top: 8,
            right: 16,
            child: GestureDetector(
              onTap: () => PlScaffold.confirmAndLogout(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Log out',
                  style:
                      AppType.button(
                        color: isDark
                            ? AppColors.subtleOnDark
                            : AppColors.stone,
                      ).copyWith(
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: isDark
                            ? AppColors.subtleOnDark
                            : AppColors.stone,
                      ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(child: bodyContent),
      ),
    );
  }

  /// Show dialog confirming logout with the same design system as ManageScreen.
  static Future<void> confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log out?',
          style: AppType.heading(color: AppColors.white).copyWith(fontSize: 19),
        ),
        content: Text(
          'This will clear your connection reference code. You will need to scan your QR code or enter a new pairing code to log in again.',
          style: AppType.body(color: AppColors.mutedOnDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppType.button(
                color: AppColors.mutedOnDark,
              ).copyWith(fontSize: 15),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Log out',
              style: AppType.button(
                color: AppColors.red,
              ).copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (context.mounted) {
        context.read<ConnectionProvider>().logout();
      }
    }
  }

  Color get _background => switch (ground) {
    PlGround.dark => AppColors.black,
    PlGround.cream => AppColors.cream,
    PlGround.white => AppColors.white,
  };
}
