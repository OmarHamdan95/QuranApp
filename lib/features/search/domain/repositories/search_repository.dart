import 'package:dartz/dartz.dart';

import '../../../quran/domain/entities/ayah.dart';
import '../../../quran/domain/entities/surah.dart';

/// Abstract repository for full-text Quran search.
abstract class SearchRepository {
  /// Searches ayahs by Arabic text or translation query.
  Future<Either<SearchFailure, List<Ayah>>> searchAyahs(
    String query, {
    SearchFilter? filter,
  });

  /// Searches surahs by name.
  Future<Either<SearchFailure, List<Surah>>> searchSurahs(String query);

  /// Returns recent search queries (most-recent first, capped at 20).
  Future<List<String>> getRecentSearches();

  /// Adds a query to the recent searches history.
  Future<void> saveRecentSearch(String query);

  /// Clears all recent search history.
  Future<void> clearRecentSearches();
}

/// Optional filter constraints applied to [SearchRepository.searchAyahs].
class SearchFilter {
  /// Limit results to a specific surah number.
  final int? surahNumber;

  /// Limit results to a specific juz number.
  final int? juzNumber;

  /// Limit results to a specific page number.
  final int? pageNumber;

  /// Whether to search within the Arabic text. Defaults to true.
  final bool searchArabic;

  /// Whether to search within the translation text. Defaults to true.
  final bool searchTranslation;

  const SearchFilter({
    this.surahNumber,
    this.juzNumber,
    this.pageNumber,
    this.searchArabic = true,
    this.searchTranslation = true,
  });

  SearchFilter copyWith({
    int? surahNumber,
    int? juzNumber,
    int? pageNumber,
    bool? searchArabic,
    bool? searchTranslation,
  }) {
    return SearchFilter(
      surahNumber: surahNumber ?? this.surahNumber,
      juzNumber: juzNumber ?? this.juzNumber,
      pageNumber: pageNumber ?? this.pageNumber,
      searchArabic: searchArabic ?? this.searchArabic,
      searchTranslation: searchTranslation ?? this.searchTranslation,
    );
  }

  bool get hasActiveFilters =>
      surahNumber != null || juzNumber != null || pageNumber != null;
}

/// Failure type for search operations.
class SearchFailure {
  final String message;
  final Object? error;

  const SearchFailure(this.message, [this.error]);

  @override
  String toString() => 'SearchFailure: $message';
}
