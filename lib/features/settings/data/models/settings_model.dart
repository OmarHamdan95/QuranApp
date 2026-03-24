import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/settings_entity.dart';

/// Persistence keys for settings.
abstract final class _Keys {
  static const themeMode = 'theme_mode';
  static const accentColor = 'accent_color';
  static const quranFontSize = 'quran_font_size';
  static const translationFontSize = 'translation_font_size';
  static const showTranslation = 'show_translation';
  static const defaultTranslation = 'default_translation';
  static const readingMode = 'reading_mode';
  static const quranFontStyle = 'quran_font_style';
  static const defaultReciterId = 'default_reciter_id';
  static const audioQuality = 'audio_quality';
  static const autoPlayNext = 'auto_play_next';
  static const calculationMethod = 'calculation_method';
  static const madhab = 'madhab';
  static const fajrAdhan = 'fajr_adhan';
  static const dhuhrAdhan = 'dhuhr_adhan';
  static const asrAdhan = 'asr_adhan';
  static const maghribAdhan = 'maghrib_adhan';
  static const ishaAdhan = 'isha_adhan';
  static const dailyAyahEnabled = 'daily_ayah_enabled';
  static const dailyAyahHour = 'daily_ayah_hour';
  static const dailyAyahMinute = 'daily_ayah_minute';
  static const morningAdhkarEnabled = 'morning_adhkar_enabled';
  static const eveningAdhkarEnabled = 'evening_adhkar_enabled';
}

/// [SharedPreferences]-backed model for [AppSettings] persistence.
class SettingsModel {
  /// Serialize [AppSettings] to SharedPreferences.
  static Future<void> save(AppSettings settings, SharedPreferences prefs) async {
    await prefs.setInt(_Keys.themeMode, settings.themeMode.index);
    // ignore: deprecated_member_use
    await prefs.setInt(_Keys.accentColor, settings.accentColor.value);
    await prefs.setDouble(_Keys.quranFontSize, settings.quranFontSize);
    await prefs.setDouble(_Keys.translationFontSize, settings.translationFontSize);
    await prefs.setBool(_Keys.showTranslation, settings.showTranslation);
    await prefs.setString(_Keys.defaultTranslation, settings.defaultTranslation);
    await prefs.setInt(_Keys.readingMode, settings.readingMode.index);
    await prefs.setString(_Keys.quranFontStyle, settings.quranFontStyle);
    await prefs.setInt(_Keys.defaultReciterId, settings.defaultReciterId);
    await prefs.setString(_Keys.audioQuality, settings.audioQuality);
    await prefs.setBool(_Keys.autoPlayNext, settings.autoPlayNext);
    await prefs.setString(_Keys.calculationMethod, settings.calculationMethod);
    await prefs.setString(_Keys.madhab, settings.madhab);
    await prefs.setBool(_Keys.fajrAdhan, settings.fajrAdhan);
    await prefs.setBool(_Keys.dhuhrAdhan, settings.dhuhrAdhan);
    await prefs.setBool(_Keys.asrAdhan, settings.asrAdhan);
    await prefs.setBool(_Keys.maghribAdhan, settings.maghribAdhan);
    await prefs.setBool(_Keys.ishaAdhan, settings.ishaAdhan);
    await prefs.setBool(_Keys.dailyAyahEnabled, settings.dailyAyahEnabled);
    await prefs.setInt(_Keys.dailyAyahHour, settings.dailyAyahTime.hour);
    await prefs.setInt(_Keys.dailyAyahMinute, settings.dailyAyahTime.minute);
    await prefs.setBool(_Keys.morningAdhkarEnabled, settings.morningAdhkarEnabled);
    await prefs.setBool(_Keys.eveningAdhkarEnabled, settings.eveningAdhkarEnabled);
  }

  /// Deserialize [AppSettings] from SharedPreferences, falling back to defaults.
  static AppSettings load(SharedPreferences prefs) {
    final colorValue = prefs.getInt(_Keys.accentColor);
    final readingModeIndex = prefs.getInt(_Keys.readingMode) ?? QuranReadingMode.surah.index;
    final themeModeIndex = prefs.getInt(_Keys.themeMode) ?? ThemeMode.system.index;

    return AppSettings(
      themeMode: ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)],
      accentColor: colorValue != null ? Color(colorValue) : const Color(0xFF1B5E20),
      quranFontSize: prefs.getDouble(_Keys.quranFontSize) ?? AppConstants.defaultQuranFontSize,
      translationFontSize:
          prefs.getDouble(_Keys.translationFontSize) ?? AppConstants.defaultTranslationFontSize,
      showTranslation: prefs.getBool(_Keys.showTranslation) ?? true,
      defaultTranslation: prefs.getString(_Keys.defaultTranslation) ?? 'en',
      readingMode: QuranReadingMode.values[readingModeIndex.clamp(0, QuranReadingMode.values.length - 1)],
      quranFontStyle: prefs.getString(_Keys.quranFontStyle) ?? 'Uthmani',
      defaultReciterId:
          prefs.getInt(_Keys.defaultReciterId) ?? AppConstants.defaultReciterId,
      audioQuality: prefs.getString(_Keys.audioQuality) ?? 'high',
      autoPlayNext: prefs.getBool(_Keys.autoPlayNext) ?? false,
      calculationMethod:
          prefs.getString(_Keys.calculationMethod) ?? AppConstants.defaultCalculationMethod,
      madhab: prefs.getString(_Keys.madhab) ?? AppConstants.defaultMadhab,
      fajrAdhan: prefs.getBool(_Keys.fajrAdhan) ?? true,
      dhuhrAdhan: prefs.getBool(_Keys.dhuhrAdhan) ?? true,
      asrAdhan: prefs.getBool(_Keys.asrAdhan) ?? true,
      maghribAdhan: prefs.getBool(_Keys.maghribAdhan) ?? true,
      ishaAdhan: prefs.getBool(_Keys.ishaAdhan) ?? true,
      dailyAyahEnabled: prefs.getBool(_Keys.dailyAyahEnabled) ?? true,
      dailyAyahTime: TimeOfDay(
        hour: prefs.getInt(_Keys.dailyAyahHour) ?? 7,
        minute: prefs.getInt(_Keys.dailyAyahMinute) ?? 0,
      ),
      morningAdhkarEnabled: prefs.getBool(_Keys.morningAdhkarEnabled) ?? true,
      eveningAdhkarEnabled: prefs.getBool(_Keys.eveningAdhkarEnabled) ?? true,
    );
  }
}
