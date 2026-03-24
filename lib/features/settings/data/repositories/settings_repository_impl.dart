import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/settings_model.dart';

/// SharedPreferences-backed implementation of [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<Either<SettingsFailure, AppSettings>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsModel.load(prefs);
      return Right(settings);
    } catch (e) {
      debugPrint('SettingsRepository.loadSettings error: $e');
      return const Right(AppSettings()); // Fallback to defaults
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await SettingsModel.save(settings, prefs);
      return const Right(unit);
    } catch (e) {
      debugPrint('SettingsRepository.saveSettings error: $e');
      return Left(SettingsFailure('Failed to save settings: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return const Right(unit);
    } catch (e) {
      return Left(SettingsFailure('Failed to reset settings: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        tempDir.createSync();
      }

      // Also clear app documents cache subfolder if it exists.
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }

      return const Right(unit);
    } catch (e) {
      debugPrint('SettingsRepository.clearCache error: $e');
      return Left(SettingsFailure('Failed to clear cache: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, int>> getCacheSize() async {
    try {
      int totalSize = 0;

      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        totalSize += await _dirSize(tempDir);
      }

      return Right(totalSize);
    } catch (e) {
      debugPrint('SettingsRepository.getCacheSize error: $e');
      return const Right(0);
    }
  }

  Future<int> _dirSize(Directory dir) async {
    int total = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }
}
