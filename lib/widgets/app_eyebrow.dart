import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// The small uppercase label with a leading dot used above every headline,
/// e.g. "• Your formula, sharper".
class AppEyebrow extends StatelessWidget {
  const AppEyebrow(this.text, {super.key, this.onDark = false, this.dotColor});

  final String text;
  final bool onDark;

  /// Optional accent for the dot (e.g. lime on the connected screen).
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? AppColors.subtleOnDark : AppColors.stone;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 7),
          decoration: BoxDecoration(
            color: dotColor ?? color,
            shape: BoxShape.circle,
          ),
        ),
        Text(text.toUpperCase(), style: AppType.eyebrow(color: color)),
      ],
    );
  }
}
