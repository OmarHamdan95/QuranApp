import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/reciter.dart';
import '../../domain/repositories/audio_repository.dart';
import '../models/reciter_model.dart';

/// Implementation of [AudioRepository] that manages audio URL generation
/// and local file caching for offline playback.
class AudioRepositoryImpl implements AudioRepository {
  @override
  Future<Either<AudioFailure, List<Reciter>>> getReciters() async {
    try {
      // For MVP, return the hardcoded popular reciters.
      // In production, this would fetch from an API.
      return const Right(ReciterModel.popularReciters);
    } catch (e) {
      return Left(AudioFailure('Failed to load reciters', e));
    }
  }

  @override
  String getAudioUrl(Reciter reciter, int surahNumber) {
    // Audio files are named as 3-digit zero-padded numbers: 001.mp3, 002.mp3, etc.
    final surahStr = surahNumber.toString().padLeft(3, '0');
    return '${reciter.baseUrl}/$surahStr.mp3';
  }

  @override
  String getAyahAudioUrl(Reciter reciter, int surahNumber, int ayahNumber) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final ayahStr = ayahNumber.toString().padLeft(3, '0');
    return '${reciter.baseUrl}/$surahStr$ayahStr.mp3';
  }

  @override
  Future<Either<AudioFailure, String>> downloadSurah(
    Reciter reciter,
    int surahNumber,
  ) async {
    try {
      final dir = await _getAudioDirectory(reciter.id);
      final filePath = _getFilePath(dir, surahNumber);

      // Check if already downloaded
      if (await File(filePath).exists()) {
        return Right(filePath);
      }

      // Download the file
      final url = getAudioUrl(reciter, surahNumber);
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        return Left(AudioFailure(
          'Download failed with status ${response.statusCode}',
        ));
      }

      final file = File(filePath);
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();
      httpClient.close();

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
    final dir = await _getAudioDirectory(reciterId);
    final filePath = _getFilePath(dir, surahNumber);
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
  }

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
