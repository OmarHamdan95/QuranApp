import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../entities/settings_entity.dart';

/// Failure type for settings operations.
class SettingsFailure {
  final String message;
  const SettingsFailure(this.message);
}

/// Abstract repository for persisting and retrieving [AppSettings].
abstract class SettingsRepository {
  /// Load settings from persistent storage.
  Future<Either<SettingsFailure, AppSettings>> loadSettings();

  /// Persist the full settings object.
  Future<Either<SettingsFailure, Unit>> saveSettings(AppSettings settings);

  /// Reset all settings to defaults.
  Future<Either<SettingsFailure, Unit>> resetSettings();

  /// Clear all cached Quran/audio data.
  Future<Either<SettingsFailure, Unit>> clearCache();

  /// Returns the current cache size in bytes.
  Future<Either<SettingsFailure, int>> getCacheSize();
}
