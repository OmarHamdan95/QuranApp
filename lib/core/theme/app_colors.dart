import 'package:flutter/material.dart';

/// Modern Islamic-inspired color palette for the Quran App.
///
/// Built around deep teal/emerald tones with warm gold accents,
/// drawing from the rich visual traditions of Islamic architecture,
/// geometric art, and illuminated manuscripts.
abstract final class AppColors {
  // ── Primary Palette (Deep Teal / Emerald) ──
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF4DA8A8);
  static const Color primaryDark = Color(0xFF064E50);
  static const Color primaryContainer = Color(0xFFD0F0EE);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF002021);

  // ── Secondary Palette (Warm Gold / Amber) ──
  static const Color secondary = Color(0xFFC49A2A);
  static const Color secondaryLight = Color(0xFFE8C460);
  static const Color secondaryDark = Color(0xFF8B6D14);
  static const Color secondaryContainer = Color(0xFFFFF3D4);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF2C2000);

  // ── Tertiary (Deep Indigo / Midnight Blue) ──
  static const Color tertiary = Color(0xFF3D5A80);
  static const Color tertiaryContainer = Color(0xFFD6E4F0);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // ── Surface / Background (Light Theme) ──
  static const Color backgroundLight = Color(0xFFF9F7F4);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF2EDE5);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Surface / Background (Dark Theme) ──
  static const Color backgroundDark = Color(0xFF0F1116);
  static const Color surfaceDark = Color(0xFF181A20);
  static const Color surfaceVariantDark = Color(0xFF23262F);
  static const Color cardDark = Color(0xFF1E2028);

  // ── Text Colors ──
  static const Color textPrimaryLight = Color(0xFF1A1C1E);
  static const Color textSecondaryLight = Color(0xFF4A4E54);
  static const Color textTertiaryLight = Color(0xFF7C8089);
  static const Color textPrimaryDark = Color(0xFFEAE8E4);
  static const Color textSecondaryDark = Color(0xFFB8B5B0);
  static const Color textTertiaryDark = Color(0xFF83807A);

  // ── Quran-specific Colors ──
  static const Color quranPageBackground = Color(0xFFFFF9EE);
  static const Color quranPageBackgroundDark = Color(0xFF1E1B16);
  static const Color quranTextColor = Color(0xFF2C2008);
  static const Color quranTextColorDark = Color(0xFFE8DCC8);
  static const Color ayahHighlight = Color(0x200D7377);
  static const Color ayahHighlightDark = Color(0x304DA8A8);
  static const Color sajdahHighlight = Color(0x28C49A2A);
  static const Color hizb = Color(0xFF7B5E3B);

  // ── Semantic Colors ──
  static const Color success = Color(0xFF2D9A5C);
  static const Color error = Color(0xFFD63B3B);
  static const Color warning = Color(0xFFE8A317);
  static const Color info = Color(0xFF2C7AB8);

  // ── Prayer Colors ──
  static const Color fajr = Color(0xFF2C3E6E);
  static const Color sunrise = Color(0xFFE89B20);
  static const Color dhuhr = Color(0xFFD4881A);
  static const Color asr = Color(0xFFC06B12);
  static const Color maghrib = Color(0xFFC44422);
  static const Color isha = Color(0xFF1B2754);

  // ── Dividers & Borders ──
  static const Color dividerLight = Color(0xFFE4DFD6);
  static const Color dividerDark = Color(0xFF2E3038);
  static const Color borderLight = Color(0xFFD4CFC5);
  static const Color borderDark = Color(0xFF3A3D47);

  // ── Material 3 Color Schemes ──

  /// Light [ColorScheme] built from the primary teal seed.
  static ColorScheme get lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        error: error,
        onError: Color(0xFFFFFFFF),
        surface: surfaceLight,
        onSurface: textPrimaryLight,
        surfaceContainerHighest: surfaceVariantLight,
        onSurfaceVariant: textSecondaryLight,
        outline: borderLight,
        outlineVariant: dividerLight,
        inverseSurface: Color(0xFF2F3036),
        onInverseSurface: Color(0xFFF1F0EC),
        inversePrimary: primaryLight,
        shadow: Color(0x29000000),
        scrim: Color(0xFF000000),
        surfaceTint: primary,
      );

  /// Dark [ColorScheme] built from the primary teal seed.
  static ColorScheme get darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: primaryLight,
        onPrimary: primaryDark,
        primaryContainer: Color(0xFF0A3D3F),
        onPrimaryContainer: primaryContainer,
        secondary: secondaryLight,
        onSecondary: secondaryDark,
        secondaryContainer: Color(0xFF4A3810),
        onSecondaryContainer: secondaryContainer,
        tertiary: tertiaryContainer,
        onTertiary: tertiary,
        tertiaryContainer: Color(0xFF263548),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        surfaceContainerHighest: surfaceVariantDark,
        onSurfaceVariant: textSecondaryDark,
        outline: borderDark,
        outlineVariant: dividerDark,
        inverseSurface: Color(0xFFE4E2DE),
        onInverseSurface: Color(0xFF1A1C1E),
        inversePrimary: primary,
        shadow: Color(0x52000000),
        scrim: Color(0xFF000000),
        surfaceTint: primaryLight,
      );
}
