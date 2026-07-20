import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// The three button treatments from the design system.
enum PlButtonStyle {
  /// The one earned "lime" moment — primary action on a dark ground.
  lime,

  /// Solid dark button (used on light grounds) or inverted cream (on dark).
  solid,

  /// Text-only "Not now" style escape hatch.
  ghost,
}

/// A pill CTA that matches the website buttons: full-width, Archivo 800 label,
/// 999px radius. Handles its own busy state.
class PlButton extends StatelessWidget {
  const PlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PlButtonStyle.solid,
    this.onDark = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PlButtonStyle style;

  /// Whether the button sits on a dark ground (affects the solid/ghost colours).
  final bool onDark;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (style == PlButtonStyle.ghost) return _ghost();

    final (bg, fg) = _colors();
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: busy ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Center(
              child: busy
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                    )
                  : Text(label, style: AppType.button(color: fg)),
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _colors() {
    switch (style) {
      case PlButtonStyle.lime:
        return (AppColors.lime, AppColors.black);
      case PlButtonStyle.solid:
        return onDark
            ? (AppColors.cream, AppColors.black) // inverted on dark
            : (AppColors.black, AppColors.cream);
      case PlButtonStyle.ghost:
        return (AppColors.black, AppColors.cream); // unreachable
    }
  }

  Widget _ghost() {
    final color = onDark ? AppColors.subtleOnDark : AppColors.stone;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: busy ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: AppType.button(color: color).copyWith(fontSize: 15),
          ),
        ),
      ),
    );
  }
}
