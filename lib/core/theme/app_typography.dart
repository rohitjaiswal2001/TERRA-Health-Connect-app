import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The three-family type system from the website, backed by **bundled** fonts
/// (see `assets/fonts` + `pubspec.yaml`) so nothing is fetched at runtime:
///
/// * **Archivo Black** — the Black (w900) weight of Archivo, for display.
/// * **Archivo** (700/900) — section headings, buttons, labels ("structure").
/// * **Instrument Sans** — body copy ("read").
class AppType {
  const AppType._();

  static const String _archivo = 'Archivo';
  static const String _instrument = 'InstrumentSans';

  /// Big display headline — Archivo Black.
  static TextStyle display({Color color = AppColors.white}) => TextStyle(
        fontFamily: _archivo,
        fontWeight: FontWeight.w900,
        fontSize: 31,
        height: 1.04,
        letterSpacing: -0.6,
        color: color,
      );

  /// Structural heading — Archivo 900.
  static TextStyle heading({Color color = AppColors.ink}) => TextStyle(
        fontFamily: _archivo,
        fontWeight: FontWeight.w900,
        fontSize: 22,
        height: 1.08,
        letterSpacing: -0.2,
        color: color,
      );

  /// Uppercase eyebrow label — Archivo 900, wide tracking.
  static TextStyle eyebrow({Color color = AppColors.stone}) => TextStyle(
        fontFamily: _archivo,
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 1.3,
        color: color,
      );

  /// Body copy — Instrument Sans.
  static TextStyle body({Color color = AppColors.stone}) => TextStyle(
        fontFamily: _instrument,
        fontWeight: FontWeight.w400,
        fontSize: 15,
        height: 1.5,
        color: color,
      );

  /// Button / CTA label — Archivo 800.
  static TextStyle button({Color color = AppColors.cream}) => TextStyle(
        fontFamily: _archivo,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: color,
      );

  /// Small structural label used for statuses and fine print.
  static TextStyle label({Color color = AppColors.stone}) => TextStyle(
        fontFamily: _archivo,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: color,
      );
}
