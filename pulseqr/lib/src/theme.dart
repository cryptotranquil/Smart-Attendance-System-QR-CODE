import 'package:flutter/material.dart';

/// Smart Attendance System — DARK theme: calm, friendly, high-contrast
/// "campus utility" system on deep navy. Plain language, big type, one
/// confident accent, semantic colors only for status.
/// All screens read colors from here, so this palette IS the theme —
/// status foregrounds are brightened and their "soft" backgrounds darkened
/// in pairs so pills/banners stay readable on dark surfaces.
class C {
  C._();

  static const bg = Color(0xFF0B1220); // deep navy scaffold background
  static const card = Color(0xFF141F36); // raised surfaces on bg
  static const ink = Color(0xFFF2F5FA); // primary text
  static const muted = Color(0xFFA7B1C4); // secondary text
  static const faint = Color(0xFF71809A); // labels, placeholders, disabled
  static const hairline = Color(0xFF253350); // card borders, dividers

  static const accent = Color(0xFF6EA8FF); // bright blue: links/highlights on dark
  static const brand = Color(0xFF2E6BE6); // primary buttons, hero cards, logo (white text on top)
  static const success = Color(0xFF47CD89); // green (Approved, on campus)
  static const successSoft = Color(0xFF0F2E1F);
  static const warn = Color(0xFFFDB022); // amber (With lecturer, late)
  static const warnSoft = Color(0xFF33270E);
  static const danger = Color(0xFFF97066); // red (Below 75%, refused, suspended)
  static const dangerSoft = Color(0xFF381E1B);
  static const infoSoft = Color(0xFF182C52);
}

class SmartAttendanceTheme {
  SmartAttendanceTheme._();

  static const double radiusCard = 20;
  static const double radiusField = 14;

  static ThemeData get data => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.accent,
          brightness: Brightness.dark,
          primary: C.brand,
          surface: C.card,
          onSurface: C.ink,
        ),
        textTheme: const TextTheme().apply(
          bodyColor: C.ink,
          displayColor: C.ink,
        ),
      );
}
