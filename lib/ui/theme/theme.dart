import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'typography.dart';

ThemeData buildPeakTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  final colorScheme = const ColorScheme.dark(
    brightness: Brightness.dark,
    primary: PeakColors.primary,
    onPrimary: PeakColors.primaryForeground,
    primaryContainer: PeakColors.primaryContainer,
    onPrimaryContainer: PeakColors.primaryForeground,
    secondary: PeakColors.secondary,
    onSecondary: PeakColors.secondaryForeground,
    secondaryContainer: PeakColors.secondaryContainer,
    onSecondaryContainer: PeakColors.foreground,
    tertiary: PeakColors.tertiary,
    onTertiary: PeakColors.tertiaryForeground,
    tertiaryContainer: PeakColors.tertiaryContainer,
    onTertiaryContainer: PeakColors.tertiaryForeground,
    error: PeakColors.destructive,
    onError: PeakColors.destructiveForeground,
    surface: PeakColors.surface,
    onSurface: PeakColors.foreground,
    surfaceContainerLowest: PeakColors.surfaceContainerLowest,
    surfaceContainerLow: PeakColors.surfaceContainerLow,
    surfaceContainer: PeakColors.surfaceContainer,
    surfaceContainerHigh: PeakColors.surfaceContainerHigh,
    surfaceContainerHighest: PeakColors.surfaceContainerHighest,
    surfaceDim: PeakColors.surfaceDim,
    surfaceBright: PeakColors.surfaceBright,
    outline: PeakColors.outline,
    outlineVariant: PeakColors.outlineVariant,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: PeakColors.background,
    canvasColor: PeakColors.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: GoogleFonts.lexendTextTheme(base.textTheme).apply(
      bodyColor: PeakColors.foreground,
      displayColor: PeakColors.foreground,
    ),
    primaryTextTheme: GoogleFonts.epilogueTextTheme(base.primaryTextTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: PeakColors.background,
      foregroundColor: PeakColors.foreground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: PeakType.headlineLg(),
    ),
    iconTheme: const IconThemeData(color: PeakColors.foreground),
    dividerTheme: const DividerThemeData(
      color: PeakColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: PeakColors.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: PeakColors.outlineVariant,
          width: 0.5,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PeakColors.surfaceContainerHigh,
      contentTextStyle: PeakType.bodyMd(),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
