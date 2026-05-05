import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = false; // Light mode default (admin)

  // ── Primary brand (Indigo) ──
  static const Color primary = Color(0xFF5856D6);
  static const Color primaryDark = Color(0xFF4240C4);
  static const Color primaryLight = Color(0xFF7B79E8);

  static const Color gradientStart = Color(0xFF5856D6);
  static const Color gradientEnd = Color(0xFF4240C4);

  // ── Admin warm backgrounds ──
  static Color get background =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get backgroundSecondary =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFAF8F5);
  static Color get backgroundTertiary =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF3F0EB);

  // ── Card & surface ──
  static Color get cardBackground =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
  static Color get cardBackgroundLight =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF9F9FB);
  static Color get cardShadow =>
      isDark ? const Color(0x33000000) : const Color(0x0A000000);

  // ── Text ──
  static Color get textPrimary =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);
  static Color get textSecondary =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
  static Color get textTertiary =>
      isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93);
  static const Color textOnPrimary = Colors.white;

  // ── iOS status colors ──
  static const Color statusActive = Color(0xFFE8445A);
  static const Color statusFree = Color(0xFF34C759);
  static const Color statusReserved = Color(0xFFFF9500);
  static const Color statusPending = Color(0xFFFFCC00);

  // ── Semantic ──
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // ── Borders ──
  static Color get border =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFEDE9E3);
  static Color get divider =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFE0DCD5);

  // ── iOS-specific ──
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosGray = Color(0xFF8E8E93);
  static const Color iosGray2 = Color(0xFFAEAEB2);
  static const Color iosGray6 = Color(0xFFF2F2F7);

  // ── Overlay ──
  static Color get overlayLight =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0x08000000);
  static Color get overlayDark =>
      isDark ? const Color(0x33000000) : const Color(0x14000000);
}
