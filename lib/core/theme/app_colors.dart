import 'package:flutter/material.dart';

/// Islamic-inspired color palette for the Quran App.
///
/// Colors are derived from traditional Islamic art, calligraphy,
/// and mosque architecture motifs.
abstract final class AppColors {
  // ── Primary Palette (Deep Islamic Green) ──
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4C8C4A);
  static const Color primaryDark = Color(0xFF003300);
  static const Color primaryContainer = Color(0xFFC8E6C9);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF002204);

  // ── Secondary Palette (Warm Gold / Amber) ──
  static const Color secondary = Color(0xFFBF8C30);
  static const Color secondaryLight = Color(0xFFF5BC61);
  static const Color secondaryDark = Color(0xFF8B5E00);
  static const Color secondaryContainer = Color(0xFFFFF0C7);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF2A1E00);

  // ── Tertiary (Deep Teal) ──
  static const Color tertiary = Color(0xFF00695C);
  static const Color tertiaryContainer = Color(0xFFB2DFDB);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // ── Surface / Background (Light Theme) ──
  static const Color backgroundLight = Color(0xFFFAF8F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F0E8);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Surface / Background (Dark Theme) ──
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  static const Color cardDark = Color(0xFF252525);

  // ── Text Colors ──
  static const Color textPrimaryLight = Color(0xFF1C1B1F);
  static const Color textSecondaryLight = Color(0xFF49454F);
  static const Color textTertiaryLight = Color(0xFF79747E);
  static const Color textPrimaryDark = Color(0xFFE6E1E5);
  static const Color textSecondaryDark = Color(0xFFC9C5CA);
  static const Color textTertiaryDark = Color(0xFF938F96);

  // ── Quran-specific Colors ──
  static const Color quranPageBackground = Color(0xFFFFF8E7);
  static const Color quranPageBackgroundDark = Color(0xFF2A2520);
  static const Color quranTextColor = Color(0xFF1A1200);
  static const Color quranTextColorDark = Color(0xFFE8DCC8);
  static const Color ayahHighlight = Color(0x331B5E20);
  static const Color ayahHighlightDark = Color(0x334CAF50);
  static const Color sajdahHighlight = Color(0x33BF8C30);
  static const Color hizb = Color(0xFF6D4C41);

  // ── Semantic Colors ──
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF0277BD);

  // ── Prayer Colors ──
  static const Color fajr = Color(0xFF283593);
  static const Color sunrise = Color(0xFFF57F17);
  static const Color dhuhr = Color(0xFFFF8F00);
  static const Color asr = Color(0xFFEF6C00);
  static const Color maghrib = Color(0xFFD84315);
  static const Color isha = Color(0xFF1A237E);

  // ── Dividers & Borders ──
  static const Color dividerLight = Color(0xFFE0DCD4);
  static const Color dividerDark = Color(0xFF3C3C3C);
  static const Color borderLight = Color(0xFFD6D0C4);
  static const Color borderDark = Color(0xFF484848);
}
