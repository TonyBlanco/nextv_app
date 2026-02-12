import 'package:flutter/material.dart';

/// NeXTV Brand Color Palette — Teal/Cyan Theme
/// Based on abstract tech wave design with translucent gradients
class NextvColors {
  NextvColors._();

  // ─── PRIMARY ACCENT ───
  /// Cyan accent — primary interactive color
  static const Color accent = Color(0xFF4DA8DA);

  /// Cyan bright — glow effects, highlights
  static const Color accentBright = Color(0xFF73D2DE);

  /// Teal light — secondary accents, active borders
  static const Color accentSoft = Color(0xFF3A7AA3);

  // ─── BACKGROUNDS ───
  /// Dark teal background — main app background
  static const Color background = Color(0xFF0A1828);

  /// Surface — cards, panels, elevated containers
  static const Color surface = Color(0xFF1E3A5F);

  /// Surface secondary — sidebar, menus, secondary panels
  static const Color surfaceSecondary = Color(0xFF2C5480);

  /// Surface darker — for deep containers within dark bg
  static const Color surfaceDark = Color(0xFF0D1F35);

  // ─── TEXT ───
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0C4D8);
  static const Color textDisabled = Color(0xFF5A7A9A);

  // ─── STATUS ───
  static const Color liveIndicator = Colors.redAccent;
  static const Color error = Colors.red;
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Colors.orangeAccent;

  // ─── BORDERS ───
  static const Color borderInactive = Color(0xFF2A4A6A);
  static Color borderActive = accent.withOpacity(0.5);

  // ─── EFFECTS ───
  static List<BoxShadow> focusShadow = [
    BoxShadow(
      color: accent.withOpacity(0.3),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: accentBright.withOpacity(0.2),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static Color overlay = Colors.black.withOpacity(0.7);

  // ─── GRADIENTS ───
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1828), Color(0xFF1E3A5F)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A7AA3), Color(0xFF4DA8DA)],
  );

  // ─── LEGACY ALIAS (for gradual migration) ───
  @Deprecated('Use NextvColors.accent instead')
  static const Color voltGreen = accent;
}
