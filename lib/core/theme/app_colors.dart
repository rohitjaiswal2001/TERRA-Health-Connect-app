import 'package:flutter/material.dart';

/// Personally brand palette, lifted directly from the website / design system.
///
/// Rule of the brand: **lime is scarce.** It only ever appears as black text on
/// a lime fill, on a dark ground, and only one lime signal per screen — it marks
/// the primary action and the single "connected" moment, nothing else.
class AppColors {
  const AppColors._();

  static const Color black = Color(0xFF050505);
  static const Color lime = Color(0xFFD7FF3F);
  static const Color cream = Color(0xFFF4F0E7);
  static const Color white = Color(0xFFFFFDF7);
  static const Color stone = Color(0xFF6F685E);
  static const Color ink = Color(0xFF141310);

  /// Muted text on dark grounds (matches the website's `#b7b2a6`).
  static const Color mutedOnDark = Color(0xFFB7B2A6);

  /// Eyebrow / caption text on dark grounds.
  static const Color subtleOnDark = Color(0xFF8F887B);

  /// Hairline dividers.
  static const Color lineLight = Color(0xFFE7E1D5);
  static const Color lineDark = Color(0x1FFFFFFF);
}
