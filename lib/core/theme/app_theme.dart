import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// A single dark-leaning [ThemeData] for the whole bridge app. Individual
/// screens paint their own ground (dark / cream / white) via [PlScaffold], so
/// the theme only needs to set brand defaults and text styling.
class AppTheme {
  const AppTheme._();

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lime,
        onPrimary: AppColors.black,
        surface: AppColors.black,
        onSurface: AppColors.cream,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.lime,
      ),
      extensions: const <ThemeExtension<dynamic>>[],
    );
  }

  /// Convenience: the display style at page-header scale.
  static TextStyle get pageTitle => AppType.display();
}
