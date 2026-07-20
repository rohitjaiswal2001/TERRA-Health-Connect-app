import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_colors.dart';

/// The Personally wordmark, tinted to any brand colour via [color]. The SVG
/// uses `currentColor`, so a single asset serves the cream, ink and lime marks.
class PlLogo extends StatelessWidget {
  const PlLogo({super.key, this.width = 104, this.color = AppColors.cream});

  /// Small (in-body) and lead sizes used across the screens.
  const PlLogo.small({super.key, this.color = AppColors.cream}) : width = 88;
  const PlLogo.lead({super.key, this.color = AppColors.cream}) : width = 132;

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/personally_logo.svg',
      width: width,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: 'Personally',
    );
  }
}
