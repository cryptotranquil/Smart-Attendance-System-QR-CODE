import 'package:flutter/material.dart';

/// PulseQR redesign — calm, friendly, high-contrast "campus utility" system.
/// Plain language, big type, one confident accent, semantic colors only for status.
class C {
  C._();

  static const bg = Color(0xFFF5F6F8);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const faint = Color(0xFF98A2B3);
  static const hairline = Color(0xFFE4E7EC);

  static const accent = Color(0xFF155EEF); // primary blue used for links/highlights
  static const brand = Color(0xFF101828); // near-black buttons
  static const success = Color(0xFF067647); // green (Approved, on campus)
  static const successSoft = Color(0xFFECFDF3);
  static const warn = Color(0xFFB54708); // amber (With lecturer, late)
  static const warnSoft = Color(0xFFFFFAEB);
  static const danger = Color(0xFFB42318); // red (Below 75%, refused, suspended)
  static const dangerSoft = Color(0xFFFEF3F2);
  static const infoSoft = Color(0xFFEFF4FF);
}

class PulseTheme {
  PulseTheme._();

  static const double radiusCard = 20;
  static const double radiusField = 14;

  static ThemeData get data => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.accent,
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
