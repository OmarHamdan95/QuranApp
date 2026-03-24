import 'package:dartz/dartz.dart';

import '../entities/tafsir.dart';

/// Abstract repository for fetching tafsir content.
abstract class TafsirRepository {
  /// Fetches the tafsir for a specific ayah from the given [source].
  Future<Either<TafsirFailure, Tafsir>> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  });

  /// Fetches tafsir for all ayahs in a surah from the given [source].
  Future<Either<TafsirFailure, List<Tafsir>>> getTafsirBySurah({
    required int surahNumber,
    required TafsirSource source,
  });

  /// Checks whether a tafsir entry is cached locally.
  Future<bool> isCached({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  });
}

/// Failure type for tafsir data operations.
class TafsirFailure {
  final String message;
  final Object? error;

  const TafsirFailure(this.message, [this.error]);

  @override
  String toString() => 'TafsirFailure: $message';
}
