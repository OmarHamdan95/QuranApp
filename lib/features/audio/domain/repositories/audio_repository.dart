import 'package:dartz/dartz.dart';
import '../entities/reciter.dart';

/// Abstract repository for audio playback operations.
abstract class AudioRepository {
  /// Fetches the list of available reciters.
  Future<Either<AudioFailure, List<Reciter>>> getReciters();

  /// Gets the audio URL for a specific surah and reciter.
  String getAudioUrl(Reciter reciter, int surahNumber);

  /// Gets the audio URL for a specific ayah.
  String getAyahAudioUrl(Reciter reciter, int surahNumber, int ayahNumber);

  /// Downloads a surah audio file for offline playback.
  Future<Either<AudioFailure, String>> downloadSurah(
    Reciter reciter,
    int surahNumber,
  );

  /// Checks if a surah audio file is downloaded.
  Future<bool> isSurahDownloaded(int reciterId, int surahNumber);

  /// Deletes a downloaded surah audio file.
  Future<Either<AudioFailure, void>> deleteDownloadedSurah(
    int reciterId,
    int surahNumber,
  );

  /// Gets the local file path for a downloaded surah.
  Future<String?> getLocalAudioPath(int reciterId, int surahNumber);
}

class AudioFailure {
  final String message;
  final Object? error;

  const AudioFailure(this.message, [this.error]);

  @override
  String toString() => 'AudioFailure: $message';
}
