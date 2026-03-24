import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

// ─────────────────────────────────────────────────────────────────────────────
// Settings Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the full [AppSettings] state, loading from and persisting to storage.
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.loadSettings();
    result.fold((_) {}, (settings) {
      state = settings;
    });
  }

  Future<void> _persist() async {
    await _repository.saveSettings(state);
  }

  // ── Appearance ──

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void setAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
    _persist();
  }

  // ── Reading ──

  void setQuranFontSize(double size) {
    final clamped = size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
    state = state.copyWith(quranFontSize: clamped);
    _persist();
  }

  void setTranslationFontSize(double size) {
    state = state.copyWith(translationFontSize: size.clamp(12.0, 28.0));
    _persist();
  }

  void setShowTranslation(bool show) {
    state = state.copyWith(showTranslation: show);
    _persist();
  }

  void setDefaultTranslation(String id) {
    state = state.copyWith(defaultTranslation: id);
    _persist();
  }

  void setReadingMode(QuranReadingMode mode) {
    state = state.copyWith(readingMode: mode);
    _persist();
  }

  void setQuranFontStyle(String style) {
    state = state.copyWith(quranFontStyle: style);
    _persist();
  }

  // ── Audio ──

  void setDefaultReciter(int id) {
    state = state.copyWith(defaultReciterId: id);
    _persist();
  }

  void setAudioQuality(String quality) {
    state = state.copyWith(audioQuality: quality);
    _persist();
  }

  void setAutoPlayNext(bool enabled) {
    state = state.copyWith(autoPlayNext: enabled);
    _persist();
  }

  // ── Prayer ──

  void setCalculationMethod(String method) {
    state = state.copyWith(calculationMethod: method);
    _persist();
  }

  void setMadhab(String madhab) {
    state = state.copyWith(madhab: madhab);
    _persist();
  }

  void setPrayerAdhan(String prayerName, bool enabled) {
    state = switch (prayerName) {
      'Fajr' => state.copyWith(fajrAdhan: enabled),
      'Dhuhr' => state.copyWith(dhuhrAdhan: enabled),
      'Asr' => state.copyWith(asrAdhan: enabled),
      'Maghrib' => state.copyWith(maghribAdhan: enabled),
      'Isha' => state.copyWith(ishaAdhan: enabled),
      _ => state,
    };
    _persist();
  }

  bool getPrayerAdhan(String prayerName) {
    return switch (prayerName) {
      'Fajr' => state.fajrAdhan,
      'Dhuhr' => state.dhuhrAdhan,
      'Asr' => state.asrAdhan,
      'Maghrib' => state.maghribAdhan,
      'Isha' => state.ishaAdhan,
      _ => true,
    };
  }

  // ── Notifications ──

  void setDailyAyahEnabled(bool enabled) {
    state = state.copyWith(dailyAyahEnabled: enabled);
    _persist();
  }

  void setDailyAyahTime(TimeOfDay time) {
    state = state.copyWith(dailyAyahTime: time);
    _persist();
  }

  void setMorningAdhkarEnabled(bool enabled) {
    state = state.copyWith(morningAdhkarEnabled: enabled);
    _persist();
  }

  void setEveningAdhkarEnabled(bool enabled) {
    state = state.copyWith(eveningAdhkarEnabled: enabled);
    _persist();
  }

  // ── Data ──

  Future<void> resetSettings() async {
    await _repository.resetSettings();
    state = const AppSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});

// ─────────────────────────────────────────────────────────────────────────────
// Convenience derived providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current theme mode, synced from settings.
final settingsThemeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider).themeMode,
);

/// Cache size as a human-readable string.
final cacheSizeProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  final result = await repo.getCacheSize();
  return result.fold(
    (_) => 'غير معروف',
    (bytes) => _formatBytes(bytes),
  );
});

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
