import 'package:flutter/material.dart';

abstract final class JamColors {
  static const ink = Color(0xFF000000);
  static const elevated = Color(0xFF121212);
  static const soft = Color(0xFF242424);
  static const softHover = Color(0xFF2A2A2A);
  static const accent = Color(0xFF1ED760);
  static const accentBright = Color(0xFF1FDF64);
  static const muted = Color(0xFFB3B3B3);
  static const subtle = Color(0xFF727272);
  static const divider = Color(0xFF2A2A2A);
}

ThemeData buildJamHorseTheme() {
  const scheme = ColorScheme.dark(
    primary: JamColors.accent,
    onPrimary: Colors.black,
    secondary: JamColors.accentBright,
    surface: JamColors.elevated,
    onSurface: Colors.white,
    outline: JamColors.divider,
  );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: JamColors.ink,
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
    fontFamily: 'Segoe UI Variable',
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        height: 0.98,
        fontWeight: FontWeight.w900,
        letterSpacing: -3,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.35),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35),
      bodySmall: TextStyle(fontSize: 12, height: 1.3),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JamColors.soft,
      hintStyle: const TextStyle(
        color: JamColors.muted,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: const WidgetStatePropertyAll(JamColors.soft),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? Colors.white.withValues(alpha: 0.05)
            : null,
      ),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      hintStyle: const WidgetStatePropertyAll(
        TextStyle(color: JamColors.muted, fontSize: 16),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18),
      ),
    ),
    cardTheme: CardThemeData(
      color: JamColors.elevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: JamColors.divider,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: JamColors.soft,
      selectedColor: Colors.white,
      disabledColor: JamColors.soft,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: JamColors.accent,
        foregroundColor: Colors.black,
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        enabledMouseCursor: SystemMouseCursors.click,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: JamColors.subtle),
        shape: const StadiumBorder(),
        enabledMouseCursor: SystemMouseCursors.click,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: JamColors.muted,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        enabledMouseCursor: SystemMouseCursors.click,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: JamColors.muted,
      textColor: Colors.white,
      mouseCursor: WidgetStateMouseCursor.clickable,
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: JamColors.muted,
        hoverColor: Colors.white10,
        highlightColor: Colors.white12,
        enabledMouseCursor: SystemMouseCursors.click,
      ),
    ),
    // Spotify's phone tab bar: plain glyphs that light up white when
    // selected, no indicator pill.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xF5000000),
      indicatorColor: Colors.transparent,
      height: 64,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : JamColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 26,
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : JamColors.muted,
        ),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Colors.white,
      inactiveTrackColor: Color(0xFF4D4D4D),
      thumbColor: Colors.white,
      overlayColor: Color(0x221ED760),
      trackHeight: 4,
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2E77D0),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
    ),
  );
}

class SpotifyPanel extends StatelessWidget {
  const SpotifyPanel({required this.child, super.key, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Material instead of ColoredBox so descendant ListTiles and InkWells
    // paint their ink on the panel rather than warning in debug builds.
    return Material(
      color: color ?? JamColors.elevated,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
