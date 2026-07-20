import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The single lime radial glow used behind the "connected" moment. Scarce by
/// design — only the connected screen paints one.
class Bloom extends StatelessWidget {
  const Bloom({super.key, this.size = 300});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.lime.withValues(alpha: 0.34),
              AppColors.lime.withValues(alpha: 0.06),
              AppColors.lime.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 0.62],
          ),
        ),
      ),
    );
  }
}
