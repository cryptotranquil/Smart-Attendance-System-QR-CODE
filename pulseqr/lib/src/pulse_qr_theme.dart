import 'package:flutter/material.dart';

/// Monochrome Neo-Tech palette (see DESIGN.md).
class PulseQrColors {
  PulseQrColors._();

  static const surface = Color(0xFFF9F9FF);
  static const containerLowest = Color(0xFFFFFFFF);
  static const containerLow = Color(0xFFF0F3FF);
  static const container = Color(0xFFE7EEFE);
  static const containerHigh = Color(0xFFE2E8F8);
  static const containerHighest = Color(0xFFDCE2F3);
  static const onSurface = Color(0xFF151C27);
  static const onSurfaceVariant = Color(0xFF4C4546);
  static const outlineVariant = Color(0xFFCFC4C5);
  static const hairline = Color(0xFFE4E7EF);
  static const ink = Color(0xFF000000);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const shadow = Color(0x14151C27);
}

class PulseQrTheme {
  PulseQrTheme._();

  static ThemeData get data => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: PulseQrColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          onPrimary: Colors.white,
          surface: PulseQrColors.surface,
          onSurface: PulseQrColors.onSurface,
          error: PulseQrColors.error,
        ),
      );
}
