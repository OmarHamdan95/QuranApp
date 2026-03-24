import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/reciter.dart';
import '../../domain/repositories/audio_repository.dart';
import '../models/reciter_model.dart';

/// Implementation of [AudioRepository].
///
/// - URL generation follows QuranicAudio.com conventions for full-surah files
///   and EveryAyah.com conventions for per-ayah files.
/// - Downloads are cached in the app's documents directory under
///   `audio/<reciterId>/<surah>.mp3`.
/// - Progress is reported through the [onProgress] callback during downloads.
class AudioRepositoryImpl implements AudioRepository {
  @override
  Future<Either<AudioFailure, List<Reciter>>> getReciters() async {
    try {
      // For MVP return the hardcoded popular reciters.
      // In production, this would be fetched from a remote API.
      return const Right(ReciterModel.popularReciters);
    } catch (e) {
      return Left(AudioFailure('Failed to load reciters', e));
    }
  }

  // ── URL generation ─────────────────────────────────────────────────────────

  @override
  String getAudioUrl(Reciter reciter, int surahNumber) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    return '${reciter.baseUrl}/$surahStr.mp3';
  }

  @override
  String getAyahAudioUrl(Reciter reciter, int surahNumber, int ayahNumber) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final ayahStr = ayahNumber.toString().padLeft(3, '0');

    // Prefer EveryAyah.com per-ayah audio when an ID is available.
    if (reciter.everyAyahId != null && reciter.everyAyahId!.isNotEmpty) {
      return 'https://everyayah.com/data/${reciter.everyAyahId}/$surahStr$ayahStr.mp3';
    }

    // Fall back to base-URL pattern used by some QuranicAudio reciters.
    return '${reciter.baseUrl}/$surahStr$ayahStr.mp3';
  }

  /// Generates a list of per-ayah URLs for an entire surah.
  ///
  /// [ayahCount] must be the correct number of ayahs for the given surah.
  List<String> getSurahAyahUrls(
    Reciter reciter,
    int surahNumber,
    int ayahCount,
  ) {
    return List.generate(
      ayahCount,
      (i) => getAyahAudioUrl(reciter, surahNumber, i + 1),
    );
  }

  // ── Download management ────────────────────────────────────────────────────

  @override
  Future<Either<AudioFailure, String>> downloadSurah(
    Reciter reciter,
    int surahNumber, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await _getAudioDirectory(reciter.id);
      final filePath = _getFilePath(dir, surahNumber);

      if (await File(filePath).exists()) {
        onProgress?.call(1.0);
        return Right(filePath);
      }

      final url = getAudioUrl(reciter, surahNumber);
      final httpClient = HttpClient();

      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        httpClient.close();
        return Left(
          AudioFailure('Download failed with status ${response.statusCode}'),
        );
      }

      final contentLength = response.contentLength;
      final file = File(filePath);
      final sink = file.openWrite();
      int bytesReceived = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (contentLength > 0) {
          onProgress?.call(bytesReceived / contentLength);
        }
      }

      await sink.close();
      httpClient.close();
      onProgress?.call(1.0);

      return Right(filePath);
    } catch (e) {
      return Left(AudioFailure('Download failed', e));
    }
  }

  @override
  Future<bool> isSurahDownloaded(int reciterId, int surahNumber) async {
    try {
      final dir = await _getAudioDirectory(reciterId);
      final filePath = _getFilePath(dir, surahNumber);
      return File(filePath).exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<AudioFailure, void>> deleteDownloadedSurah(
    int reciterId,
    int surahNumber,
  ) async {
    try {
      final dir = await _getAudioDirectory(reciterId);
      final filePath = _getFilePath(dir, surahNumber);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure('Delete failed', e));
    }
  }

  @override
  Future<String?> getLocalAudioPath(int reciterId, int surahNumber) async {
    try {
      final dir = await _getAudioDirectory(reciterId);
      final filePath = _getFilePath(dir, surahNumber);
      if (await File(filePath).exists()) {
        return filePath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the total size in bytes of all cached audio for [reciterId].
  Future<int> getTotalCacheSize(int reciterId) async {
    try {
      final dir = Directory(
        path.join((await getApplicationDocumentsDirectory()).path, 'audio',
            reciterId.toString()),
      );
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Returns the list of surah numbers downloaded for [reciterId].
  Future<List<int>> getDownloadedSurahNumbers(int reciterId) async {
    try {
      final dir = Directory(
        path.join((await getApplicationDocumentsDirectory()).path, 'audio',
            reciterId.toString()),
      );
      if (!await dir.exists()) return [];
      final List<int> numbers = [];
      await for (final entity in dir.list()) {
        if (entity is File) {
          final name = path.basenameWithoutExtension(entity.path);
          final number = int.tryParse(name);
          if (number != null) numbers.add(number);
        }
      }
      numbers.sort();
      return numbers;
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<String> _getAudioDirectory(int reciterId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(
      path.join(appDir.path, 'audio', reciterId.toString()),
    );
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  String _getFilePath(String dirPath, int surahNumber) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    return path.join(dirPath, '$surahStr.mp3');
  }
}
