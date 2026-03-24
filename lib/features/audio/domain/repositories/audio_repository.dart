import 'package:dartz/dartz.dart';
import '../entities/reciter.dart';

/// Abstract repository for audio playback and download operations.
abstract class AudioRepository {
  /// Fetches the list of available reciters.
  Future<Either<AudioFailure, List<Reciter>>> getReciters();

  /// Gets the full-surah audio URL for a specific reciter.
  /// Pattern: [baseUrl]/[3-digit-surah].mp3
  String getAudioUrl(Reciter reciter, int surahNumber);

  /// Gets the per-ayah audio URL for a specific ayah.
  /// Uses EveryAyah.com when [Reciter.everyAyahId] is set.
  String getAyahAudioUrl(Reciter reciter, int surahNumber, int ayahNumber);

  /// Downloads a full-surah audio file for offline playback.
  ///
  /// [onProgress] is called with a value between 0.0 and 1.0.
  Future<Either<AudioFailure, String>> downloadSurah(
    Reciter reciter,
    int surahNumber, {
    void Function(double progress)? onProgress,
  });

  /// Returns true if the surah audio file is already stored locally.
  Future<bool> isSurahDownloaded(int reciterId, int surahNumber);

  /// Deletes a downloaded surah audio file from local storage.
  Future<Either<AudioFailure, void>> deleteDownloadedSurah(
    int reciterId,
    int surahNumber,
  );

  /// Returns the local file path if the surah is downloaded, otherwise null.
  Future<String?> getLocalAudioPath(int reciterId, int surahNumber);
}

/// Represents an error from the audio domain layer.
class AudioFailure {
  final String message;
  final Object? error;

  const AudioFailure(this.message, [this.error]);

  @override
  String toString() => 'AudioFailure: $message';
}
