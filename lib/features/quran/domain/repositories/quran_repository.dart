import 'package:dartz/dartz.dart';
import '../entities/surah.dart';
import '../entities/ayah.dart';

/// Abstract repository defining the contract for Quran data access.
///
/// Implementations may read from a bundled SQLite database, a remote API,
/// or a combination of both.
abstract class QuranRepository {
  /// Fetches all 114 surahs.
  Future<Either<QuranFailure, List<Surah>>> getSurahs();

  /// Fetches a single surah by its number.
  Future<Either<QuranFailure, Surah>> getSurahByNumber(int surahNumber);

  /// Fetches all ayahs for a given surah.
  Future<Either<QuranFailure, List<Ayah>>> getAyahsBySurah(int surahNumber);

  /// Fetches ayahs for a given page of the Mushaf.
  Future<Either<QuranFailure, List<Ayah>>> getAyahsByPage(int pageNumber);

  /// Fetches ayahs for a given juz.
  Future<Either<QuranFailure, List<Ayah>>> getAyahsByJuz(int juzNumber);

  /// Fetches a single ayah by surah and ayah number.
  Future<Either<QuranFailure, Ayah>> getAyah(int surahNumber, int ayahNumber);

  /// Searches ayahs by text query (Arabic or transliteration).
  Future<Either<QuranFailure, List<Ayah>>> searchAyahs(String query);

  /// Fetches a random ayah (for daily ayah feature).
  Future<Either<QuranFailure, Ayah>> getRandomAyah();

  /// Gets the total number of ayahs for a surah.
  Future<Either<QuranFailure, int>> getAyahCount(int surahNumber);
}

/// Failure type for Quran data operations.
class QuranFailure {
  final String message;
  final Object? error;

  const QuranFailure(this.message, [this.error]);

  @override
  String toString() => 'QuranFailure: $message';
}
