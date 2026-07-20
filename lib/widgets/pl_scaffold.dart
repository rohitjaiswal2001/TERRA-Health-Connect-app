import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

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
  });

  final Widget child;
  final PlGround ground;

  /// Center the content vertically (used by the confirmation screens).
  final bool center;

  @override
  Widget build(BuildContext context) {
    final isDark = ground == PlGround.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: center
                ? Center(child: child)
                : SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }

  Color get _background => switch (ground) {
        PlGround.dark => AppColors.black,
        PlGround.cream => AppColors.cream,
        PlGround.white => AppColors.white,
      };
}
