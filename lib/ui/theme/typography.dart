import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Type scale — mirrors `peak-web/tailwind.config.ts` `fontSize`.
class PeakType {
  PeakType._();

  static TextStyle headlineXl({Color? color, double height = 1.2}) =>
      GoogleFonts.epilogue(
        fontSize: 36,
        height: height,
        letterSpacing: -0.02 * 36,
        fontWeight: FontWeight.w700,
        color: color ?? PeakColors.foreground,
      );

  static TextStyle headlineLg({Color? color}) => GoogleFonts.epilogue(
        fontSize: 26,
        height: 32 / 26,
        fontWeight: FontWeight.w600,
        color: color ?? PeakColors.foreground,
      );

  static TextStyle bodyLg({Color? color}) => GoogleFonts.lexend(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w400,
        color: color ?? PeakColors.foreground,
      );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.lexend(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
        color: color ?? PeakColors.foreground,
      );

  static TextStyle labelMd({Color? color}) => GoogleFonts.lexend(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w500,
        color: color ?? PeakColors.foreground,
      );

  static TextStyle overline({Color? color}) => GoogleFonts.lexend(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.6,
        color: color ?? PeakColors.mutedForeground,
      );

  static TextStyle numericDisplay({Color? color}) => GoogleFonts.epilogue(
        fontSize: 44,
        height: 1,
        letterSpacing: 0.02 * 44,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? PeakColors.foreground,
      );

  static TextStyle numericXl({Color? color}) => GoogleFonts.epilogue(
        fontSize: 60,
        height: 1,
        letterSpacing: 0.02 * 60,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? PeakColors.foreground,
      );

  /// Tabular-numerics variant of any text style.
  static TextStyle tabular(TextStyle base) => base.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle buttonLabel({Color? color}) => GoogleFonts.lexend(
        fontSize: 17,
        height: 22 / 17,
        fontWeight: FontWeight.w600,
        color: color ?? PeakColors.foreground,
      );
}
