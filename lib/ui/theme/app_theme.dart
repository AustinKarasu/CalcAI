import 'package:flutter/material.dart';

import '../../core/models/calculator_mode.dart';

class AppTheme {
  static ThemeData build(AppThemeMode mode) {
    final palette = switch (mode) {
      AppThemeMode.dark => const _Palette(
          background: Color(0xFF0E1117),
          surface: Color(0xFF171C25),
          primary: Color(0xFF7CE7FF),
          secondary: Color(0xFFFF7BD5),
          text: Colors.white,
          muted: Color(0xFF8892A7),
        ),
      AppThemeMode.neon => const _Palette(
          background: Color(0xFF090B11),
          surface: Color(0xFF141826),
          primary: Color(0xFF5EE7FF),
          secondary: Color(0xFFD61AFF),
          text: Colors.white,
          muted: Color(0xFF7C87A3),
        ),
      AppThemeMode.glass => const _Palette(
          background: Color(0xFF0A1020),
          surface: Color(0xFF1A2236),
          primary: Color(0xFF8CF7E2),
          secondary: Color(0xFFF4B6FF),
          text: Colors.white,
          muted: Color(0xFF96A3BF),
        ),
      AppThemeMode.sunset => const _Palette(
          background: Color(0xFF160B0A),
          surface: Color(0xFF251414),
          primary: Color(0xFFFFB454),
          secondary: Color(0xFFFF6B6B),
          text: Colors.white,
          muted: Color(0xFFB8917A),
        ),
      AppThemeMode.forest => const _Palette(
          background: Color(0xFF08110E),
          surface: Color(0xFF13201A),
          primary: Color(0xFF67F0B5),
          secondary: Color(0xFF2EC27E),
          text: Colors.white,
          muted: Color(0xFF86A894),
        ),
      AppThemeMode.mono => const _Palette(
          background: Color(0xFF0A0A0A),
          surface: Color(0xFF181818),
          primary: Color(0xFFF3F3F3),
          secondary: Color(0xFF8F8F8F),
          text: Colors.white,
          muted: Color(0xFF707070),
        ),
    };

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        secondary: palette.secondary,
        surface: palette.surface,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
        ),
        headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ).apply(
        bodyColor: palette.text,
        displayColor: palette.text,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        selectedColor: palette.secondary.withValues(alpha: 0.22),
        disabledColor: palette.surface,
        side: BorderSide(color: palette.muted.withValues(alpha: 0.18)),
        labelStyle: TextStyle(color: palette.text.withValues(alpha: 0.88)),
      ),
    );
  }
}

class _Palette {
  const _Palette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.text,
    required this.muted,
  });

  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color text;
  final Color muted;
}
