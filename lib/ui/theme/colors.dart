import 'package:flutter/material.dart';

/// Midnight Studio — the only theme. Always dark.
/// Mirrors `peak-web/app/globals.css` CSS variables.
class PeakColors {
  PeakColors._();

  // Surface scale
  static const background = Color(0xFF131316); // hsl(240 7% 9%)
  static const foreground = Color(0xFFE3E1E6); // hsl(270 6% 89%)
  static const surface = background;
  static const surfaceDim = background;
  static const surfaceBright = Color(0xFF38383C); // hsl(240 3% 23%)
  static const surfaceContainerLowest = Color(0xFF0E0E11); // hsl(240 11% 6%)
  static const surfaceContainerLow = Color(0xFF1A1A1E); // hsl(240 5% 11%)
  static const surfaceContainer = Color(0xFF1F1F23); // hsl(240 5% 13%)
  static const surfaceContainerHigh = Color(0xFF29292D); // hsl(240 4% 17%)
  static const surfaceContainerHighest = Color(0xFF333337); // hsl(240 3% 21%)

  // Brand — soft gold
  static const primary = Color(0xFFEFC656); // hsl(45 86% 63%)
  static const primaryForeground = Color(0xFF3D2A00); // hsl(42 100% 12%)
  static const primaryContainer = Color(0xFFD4AF37); // hsl(45 60% 53%)

  static const secondary = Color(0xFFC5CCD6); // hsl(213 24% 79%)
  static const secondaryForeground = Color(0xFF252E3D); // hsl(215 24% 19%)
  static const secondaryContainer = Color(0xFF424B5A); // hsl(215 14% 30%)

  static const tertiary = Color(0xFFFFCFA6); // hsl(27 100% 79%)
  static const tertiaryForeground = Color(0xFF4D1C00); // hsl(25 100% 15%)
  static const tertiaryContainer = Color(0xFFEFA85F); // hsl(27 84% 65%)

  static const muted = surfaceContainerHigh;
  static const mutedForeground = Color(0xFFCEBE9C); // hsl(41 26% 75%)

  static const accent = surfaceContainerHigh;
  static const accentForeground = foreground;

  static const destructive = Color(0xFFFFB8AE); // hsl(6 100% 84%)
  static const destructiveForeground = Color(0xFF6B0000); // hsl(357 100% 21%)

  static const outline = Color(0xFF999081); // hsl(41 11% 54%)
  static const outlineVariant = Color(0xFF4B4234); // hsl(41 19% 25%)

  // Aliases used by widgets
  static const border = outlineVariant;
  static const input = surfaceContainerLow;
  static const ring = primary;
}
