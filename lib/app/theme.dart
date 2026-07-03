import 'package:flutter/material.dart';

abstract final class JamColors {
  static const ink = Color(0xFF070A14);
  static const elevated = Color(0xFF10141F);
  static const soft = Color(0xFF181D2B);
  static const accent = Color(0xFF3E6ED8);
  static const accentBright = Color(0xFF6E96EC);
  static const muted = Color(0xFF9AA3B8);
}

ThemeData buildJamHorseTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: JamColors.accent,
    brightness: Brightness.dark,
    surface: JamColors.ink,
  ).copyWith(
    primary: JamColors.accent,
    secondary: JamColors.accentBright,
    surface: JamColors.ink,
    surfaceContainer: JamColors.elevated,
    surfaceContainerHigh: JamColors.soft,
    outline: const Color(0xFF2A3140),
  );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: JamColors.ink,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    fontFamily: '.SF Pro Display',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.35),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JamColors.elevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1E2534)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JamColors.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: JamColors.elevated,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    // Pointer cursor on hover for every interactive control. Explicit
    // everywhere because macOS cursor updates have proven unreliable when
    // left to per-widget defaults.
    listTileTheme: const ListTileThemeData(
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xF50C101A),
      indicatorColor: Color(0x333E6ED8),
      height: 72,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: JamColors.accent,
      inactiveTrackColor: Color(0xFF2A3140),
      thumbColor: Colors.white,
      overlayColor: Color(0x223E6ED8),
      trackHeight: 3,
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: JamColors.soft,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: JamColors.soft,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
