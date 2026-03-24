import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/isar_service.dart';
import '../../../quran/domain/entities/ayah.dart';
import '../../../quran/domain/entities/surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/repositories/search_repository.dart';

/// Implementation of [SearchRepository] that delegates to [QuranRepository].
///
/// Handles:
/// - Real-time Arabic and transliteration search via the QuranRepository.
/// - Local recent-search history stored in SharedPreferences.
/// - Result filtering by surah / juz / page.
class SearchRepositoryImpl implements SearchRepository {
  static const String _recentSearchesKey = 'recent_searches_v1';
  static const int _maxRecentSearches = 20;

  final QuranRepository _quranRepository;
  final IsarService _isarService;

  SearchRepositoryImpl({
    required QuranRepository quranRepository,
    required IsarService isarService,
  })  : _quranRepository = quranRepository,
        _isarService = isarService;

  @override
  Future<Either<SearchFailure, List<Ayah>>> searchAyahs(
    String query, {
    SearchFilter? filter,
  }) async {
    try {
      if (query.trim().isEmpty) return const Right([]);

      final result = await _quranRepository.searchAyahs(query.trim());
      return result.fold(
        (failure) => Left(SearchFailure(failure.message, failure.error)),
        (ayahs) {
          var filtered = ayahs;

          if (filter != null) {
            if (filter.surahNumber != null) {
              filtered = filtered
                  .where((a) => a.surahNumber == filter.surahNumber)
                  .toList();
            }
            if (filter.juzNumber != null) {
              filtered = filtered
                  .where((a) => a.juz == filter.juzNumber)
                  .toList();
            }
            if (filter.pageNumber != null) {
              filtered = filtered
                  .where((a) => a.page == filter.pageNumber)
                  .toList();
            }
          }

          return Right(filtered);
        },
      );
    } catch (e) {
      debugPrint('SearchRepositoryImpl.searchAyahs error: $e');
      return Left(SearchFailure('Search failed', e));
    }
  }

  @override
  Future<Either<SearchFailure, List<Surah>>> searchSurahs(
    String query,
  ) async {
    try {
      if (query.trim().isEmpty) return const Right([]);

      final result = await _quranRepository.getSurahs();
      return result.fold(
        (failure) => Left(SearchFailure(failure.message, failure.error)),
        (surahs) {
          final q = query.trim().toLowerCase();
          final matches = surahs.where((s) {
            return s.nameArabic.contains(query) ||
                s.nameEnglish.toLowerCase().contains(q) ||
                s.nameTranslation.toLowerCase().contains(q);
          }).toList();
          return Right(matches);
        },
      );
    } catch (e) {
      return Left(SearchFailure('Surah search failed', e));
    }
  }

  @override
  Future<List<String>> getRecentSearches() async {
    try {
      return _isarService.getStringList(_recentSearchesKey);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final recent = _isarService.getStringList(_recentSearchesKey);
      recent.remove(query);
      recent.insert(0, query);
      if (recent.length > _maxRecentSearches) {
        recent.removeRange(_maxRecentSearches, recent.length);
      }
      await _isarService.setStringList(_recentSearchesKey, recent);
    } catch (_) {}
  }

  @override
  Future<void> clearRecentSearches() async {
    try {
      await _isarService.remove(_recentSearchesKey);
    } catch (_) {}
  }
}
