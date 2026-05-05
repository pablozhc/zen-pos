import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography — Inter for admin/web, system SF Pro for iOS POS
class AppTypography {
  static TextStyle get _inter => GoogleFonts.inter();

  // Display
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 96, fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 72, fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 48, fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()]);

  // Headlines
  static TextStyle get h1 =>
      GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700);
  static TextStyle get h2 =>
      GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700);
  static TextStyle get h3 =>
      GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600);
  static TextStyle get h4 =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600);

  // Body
  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400);
  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400);

  // Labels
  static TextStyle get labelLarge =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600);
  static TextStyle get labelMedium =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500);
  static TextStyle get labelSmall =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 0.4);

  // Caption
  static TextStyle get caption =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle get captionEmphasis =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);

  // Mono (prices)
  static TextStyle get monoLarge => GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle get monoMedium => GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()]);

  // iOS POS — system font (SF Pro on Apple devices)
  static const TextStyle iosLargeTitle = TextStyle(
      fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.37);
  static const TextStyle iosTitle1 = TextStyle(
      fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 0.36);
  static const TextStyle iosTitle2 = TextStyle(
      fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.35);
  static const TextStyle iosTitle3 = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.38);
  static const TextStyle iosHeadline = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41);
  static const TextStyle iosBody = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.41);
  static const TextStyle iosCallout = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.32);
  static const TextStyle iosSubheadline = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.24);
  static const TextStyle iosFootnote = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: -0.08);
  static const TextStyle iosCaption1 = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0);
  static const TextStyle iosCaption2 = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.07);
}
