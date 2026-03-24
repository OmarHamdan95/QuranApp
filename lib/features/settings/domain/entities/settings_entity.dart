import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Domain entity holding all user-configurable settings.
class AppSettings {
  // ── Appearance ──
  final ThemeMode themeMode;
  final Color accentColor;

  // ── Reading ──
  final double quranFontSize;
  final double translationFontSize;
  final bool showTranslation;
  final String defaultTranslation;
  final QuranReadingMode readingMode;
  final String quranFontStyle; // 'Uthmani' | 'IndoPak' | 'Simple'

  // ── Audio ──
  final int defaultReciterId;
  final String audioQuality; // 'low' | 'medium' | 'high'
  final bool autoPlayNext;

  // ── Prayer ──
  final String calculationMethod;
  final String madhab;
  final bool fajrAdhan;
  final bool dhuhrAdhan;
  final bool asrAdhan;
  final bool maghribAdhan;
  final bool ishaAdhan;

  // ── Notifications ──
  final bool dailyAyahEnabled;
  final TimeOfDay dailyAyahTime;
  final bool morningAdhkarEnabled;
  final bool eveningAdhkarEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentColor = const Color(0xFF1B5E20),
    this.quranFontSize = AppConstants.defaultQuranFontSize,
    this.translationFontSize = AppConstants.defaultTranslationFontSize,
    this.showTranslation = true,
    this.defaultTranslation = 'en',
    this.readingMode = QuranReadingMode.surah,
    this.quranFontStyle = 'Uthmani',
    this.defaultReciterId = AppConstants.defaultReciterId,
    this.audioQuality = 'high',
    this.autoPlayNext = false,
    this.calculationMethod = AppConstants.defaultCalculationMethod,
    this.madhab = AppConstants.defaultMadhab,
    this.fajrAdhan = true,
    this.dhuhrAdhan = true,
    this.asrAdhan = true,
    this.maghribAdhan = true,
    this.ishaAdhan = true,
    this.dailyAyahEnabled = true,
    this.dailyAyahTime = const TimeOfDay(hour: 7, minute: 0),
    this.morningAdhkarEnabled = true,
    this.eveningAdhkarEnabled = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    double? quranFontSize,
    double? translationFontSize,
    bool? showTranslation,
    String? defaultTranslation,
    QuranReadingMode? readingMode,
    String? quranFontStyle,
    int? defaultReciterId,
    String? audioQuality,
    bool? autoPlayNext,
    String? calculationMethod,
    String? madhab,
    bool? fajrAdhan,
    bool? dhuhrAdhan,
    bool? asrAdhan,
    bool? maghribAdhan,
    bool? ishaAdhan,
    bool? dailyAyahEnabled,
    TimeOfDay? dailyAyahTime,
    bool? morningAdhkarEnabled,
    bool? eveningAdhkarEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      quranFontSize: quranFontSize ?? this.quranFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      defaultTranslation: defaultTranslation ?? this.defaultTranslation,
      readingMode: readingMode ?? this.readingMode,
      quranFontStyle: quranFontStyle ?? this.quranFontStyle,
      defaultReciterId: defaultReciterId ?? this.defaultReciterId,
      audioQuality: audioQuality ?? this.audioQuality,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      fajrAdhan: fajrAdhan ?? this.fajrAdhan,
      dhuhrAdhan: dhuhrAdhan ?? this.dhuhrAdhan,
      asrAdhan: asrAdhan ?? this.asrAdhan,
      maghribAdhan: maghribAdhan ?? this.maghribAdhan,
      ishaAdhan: ishaAdhan ?? this.ishaAdhan,
      dailyAyahEnabled: dailyAyahEnabled ?? this.dailyAyahEnabled,
      dailyAyahTime: dailyAyahTime ?? this.dailyAyahTime,
      morningAdhkarEnabled: morningAdhkarEnabled ?? this.morningAdhkarEnabled,
      eveningAdhkarEnabled: eveningAdhkarEnabled ?? this.eveningAdhkarEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          quranFontSize == other.quranFontSize &&
          calculationMethod == other.calculationMethod;

  @override
  int get hashCode =>
      themeMode.hashCode ^ quranFontSize.hashCode ^ calculationMethod.hashCode;
}
