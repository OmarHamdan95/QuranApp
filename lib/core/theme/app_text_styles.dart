import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text styles for the Quran App.
///
/// Supports both Arabic (Quran text, UI) and Latin (translations, system text).
/// Uses Amiri family for Quran text and system fonts for UI.
abstract final class AppTextStyles {
  // ─────────────────────────────────────────────
  // Quran Arabic Text Styles
  // ─────────────────────────────────────────────

  /// Main Quran ayah text (Uthmani script).
  static const TextStyle quranAyah = TextStyle(
    fontFamily: 'AmiriQuran',
    fontSize: 28,
    height: 2.0,
    color: AppColors.quranTextColor,
    letterSpacing: 0,
    wordSpacing: 4,
    locale: Locale('ar'),
  );

  /// Larger Quran text for focused reading.
  static const TextStyle quranAyahLarge = TextStyle(
    fontFamily: 'AmiriQuran',
    fontSize: 34,
    height: 2.2,
    color: AppColors.quranTextColor,
    letterSpacing: 0,
    wordSpacing: 4,
    locale: Locale('ar'),
  );

  /// Surah name in Arabic (decorative header).
  static const TextStyle surahNameArabic = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.6,
    color: AppColors.textPrimaryLight,
    locale: Locale('ar'),
  );

  /// Bismillah text style.
  static const TextStyle bismillah = TextStyle(
    fontFamily: 'AmiriQuran',
    fontSize: 32,
    height: 2.0,
    color: AppColors.primary,
    locale: Locale('ar'),
  );

  /// Ayah number displayed in ornament.
  static const TextStyle ayahNumber = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    locale: Locale('ar'),
  );

  // ─────────────────────────────────────────────
  // Arabic UI Text Styles
  // ─────────────────────────────────────────────

  static const TextStyle arabicHeadline = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.5,
    locale: Locale('ar'),
  );

  static const TextStyle arabicBody = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 18,
    height: 1.6,
    locale: Locale('ar'),
  );

  static const TextStyle arabicCaption = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 14,
    height: 1.5,
    locale: Locale('ar'),
  );

  // ─────────────────────────────────────────────
  // Latin / System Text Styles
  // ─────────────────────────────────────────────

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.25,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ─────────────────────────────────────────────
  // Translation / Tafsir Styles
  // ─────────────────────────────────────────────

  static const TextStyle translationText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.7,
    letterSpacing: 0.15,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle tafsirText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.8,
    letterSpacing: 0.15,
  );

  static const TextStyle tafsirArabic = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 17,
    height: 1.8,
    locale: Locale('ar'),
  );
}
