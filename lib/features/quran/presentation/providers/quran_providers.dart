import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/database_helper.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

/// Provider for the [QuranRepository] implementation.
///
/// Lazily initialises the SQLite database on first access via [DatabaseHelper].
final quranRepositoryProvider = FutureProvider<QuranRepository>((ref) async {
  final db = await DatabaseHelper.instance.quranDatabase;
  return QuranRepositoryImpl(db);
});

// ── Data Providers ────────────────────────────────────────────────────────────

/// Fetches all 114 surahs. Cached automatically by Riverpod.
final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final repoAsync = await ref.watch(quranRepositoryProvider.future);
  final result = await repoAsync.getSurahs();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (surahs) => surahs,
  );
});

/// Fetches ayahs for a specific surah, parameterised by surah number.
final ayahsBySurahProvider = FutureProvider.family<List<Ayah>, int>(
  (ref, surahNumber) async {
    final repo = await ref.watch(quranRepositoryProvider.future);
    final result = await repo.getAyahsBySurah(surahNumber);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (ayahs) => ayahs,
    );
  },
);

/// Fetches a single surah by number.
final surahProvider = FutureProvider.family<Surah, int>(
  (ref, surahNumber) async {
    final repo = await ref.watch(quranRepositoryProvider.future);
    final result = await repo.getSurahByNumber(surahNumber);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (surah) => surah,
    );
  },
);

/// Fetches ayahs for a specific page of the Mushaf.
final ayahsByPageProvider = FutureProvider.family<List<Ayah>, int>(
  (ref, pageNumber) async {
    final repo = await ref.watch(quranRepositoryProvider.future);
    final result = await repo.getAyahsByPage(pageNumber);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (ayahs) => ayahs,
    );
  },
);

/// Fetches ayahs for a specific juz.
final ayahsByJuzProvider = FutureProvider.family<List<Ayah>, int>(
  (ref, juzNumber) async {
    final repo = await ref.watch(quranRepositoryProvider.future);
    final result = await repo.getAyahsByJuz(juzNumber);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (ayahs) => ayahs,
    );
  },
);

/// Searches ayahs by query text (Arabic or transliteration).
final searchAyahsProvider = FutureProvider.family<List<Ayah>, String>(
  (ref, query) async {
    if (query.trim().isEmpty) return [];
    final repo = await ref.watch(quranRepositoryProvider.future);
    final result = await repo.searchAyahs(query);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (ayahs) => ayahs,
    );
  },
);

/// Fetches a random ayah for the daily ayah card, caching it per day.
final dailyAyahProvider = FutureProvider<Ayah>((ref) async {
  final repo = await ref.watch(quranRepositoryProvider.future);
  final result = await repo.getRandomAyah();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (ayah) async {
      await DatabaseHelper.instance.saveDailyAyahId(ayah.id);
      return ayah;
    },
  );
});

// ── Reading Mode ──────────────────────────────────────────────────────────────

/// Tracks the current Quran reading mode (surah list / juz list / page view).
enum QuranViewMode { surahList, juzList, pageView }

final quranViewModeProvider =
    StateProvider<QuranViewMode>((ref) => QuranViewMode.surahList);

// ── Surah Filter ──────────────────────────────────────────────────────────────

/// Filter options for the surah index list.
enum SurahFilter { all, meccan, medinan }

final surahFilterProvider =
    StateProvider<SurahFilter>((ref) => SurahFilter.all);

// ── Reading Position ──────────────────────────────────────────────────────────

/// Value object tracking the user's current reading position.
class ReadingPosition {
  final int surahNumber;
  final int ayahNumber;
  final int page;
  final String surahName;
  final DateTime timestamp;

  const ReadingPosition({
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
    this.surahName = '',
    required this.timestamp,
  });

  ReadingPosition copyWith({
    int? surahNumber,
    int? ayahNumber,
    int? page,
    String? surahName,
    DateTime? timestamp,
  }) {
    return ReadingPosition(
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      page: page ?? this.page,
      surahName: surahName ?? this.surahName,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Notifier for the last-read position with SharedPreferences persistence.
class LastReadNotifier extends StateNotifier<ReadingPosition?> {
  LastReadNotifier() : super(null) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      // Try DB first, then SharedPreferences fallback.
      final row = await DatabaseHelper.instance.getReadingProgress();
      if (row != null) {
        state = ReadingPosition(
          surahNumber: row['surah_number'] as int,
          ayahNumber: row['ayah_number'] as int,
          page: row['page'] as int? ?? 1,
          timestamp: DateTime.tryParse(row['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );
        return;
      }
      // Fallback to SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final surah = prefs.getInt(AppConstants.prefLastReadSurah);
      final ayah = prefs.getInt(AppConstants.prefLastReadAyah);
      final page = prefs.getInt(AppConstants.prefLastReadPage);
      if (surah != null && ayah != null) {
        state = ReadingPosition(
          surahNumber: surah,
          ayahNumber: ayah,
          page: page ?? 1,
          timestamp: DateTime.now(),
        );
      }
    } catch (_) {
      // Silently ignore on first launch.
    }
  }

  /// Saves the current position to DB and SharedPreferences.
  Future<void> save({
    required int surahNumber,
    required int ayahNumber,
    required int page,
    String surahName = '',
  }) async {
    state = ReadingPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
      surahName: surahName,
      timestamp: DateTime.now(),
    );

    // Persist to database.
    await DatabaseHelper.instance.saveReadingProgress(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
    );

    // Also persist to SharedPreferences as fallback.
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(AppConstants.prefLastReadSurah, surahNumber),
      prefs.setInt(AppConstants.prefLastReadAyah, ayahNumber),
      prefs.setInt(AppConstants.prefLastReadPage, page),
    ]);
  }
}

final lastReadPositionProvider =
    StateNotifierProvider<LastReadNotifier, ReadingPosition?>(
  (ref) => LastReadNotifier(),
);

// ── Reader Settings ───────────────────────────────────────────────────────────

/// Font size for Quran text, persisted in preferences.
final quranFontSizeProvider =
    StateNotifierProvider<_FontSizeNotifier, double>(
  (ref) => _FontSizeNotifier(),
);

class _FontSizeNotifier extends StateNotifier<double> {
  _FontSizeNotifier() : super(AppConstants.defaultQuranFontSize) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state =
        prefs.getDouble(AppConstants.prefQuranFontSize) ??
            AppConstants.defaultQuranFontSize;
  }

  Future<void> setSize(double size) async {
    state = size.clamp(
        AppConstants.minFontSize, AppConstants.maxFontSize);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefQuranFontSize, state);
  }
}

/// Whether to show translation alongside Arabic text.
final showTranslationProvider =
    StateNotifierProvider<_ShowTranslationNotifier, bool>(
  (ref) => _ShowTranslationNotifier(),
);

class _ShowTranslationNotifier extends StateNotifier<bool> {
  _ShowTranslationNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppConstants.prefShowTranslation) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefShowTranslation, state);
  }
}

// ── Highlighted Ayah ─────────────────────────────────────────────────────────

/// Tracks which ayah number (within the current surah) is highlighted.
final highlightedAyahProvider = StateProvider<int?>((ref) => null);

// ── Bookmarks ─────────────────────────────────────────────────────────────────

/// Notifier to track and toggle bookmarked ayahs within the session.
final bookmarkedAyahsProvider =
    StateNotifierProvider<_BookmarksNotifier, Set<String>>(
  (ref) => _BookmarksNotifier(),
);

class _BookmarksNotifier extends StateNotifier<Set<String>> {
  _BookmarksNotifier() : super({});

  String _key(int surah, int ayah) => '$surah:$ayah';

  bool isBookmarked(int surahNumber, int ayahNumber) =>
      state.contains(_key(surahNumber, ayahNumber));

  Future<void> toggle({
    required int surahNumber,
    required int ayahNumber,
    required int page,
  }) async {
    final key = _key(surahNumber, ayahNumber);
    if (state.contains(key)) {
      await DatabaseHelper.instance.removeBookmark(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
      state = {...state}..remove(key);
    } else {
      await DatabaseHelper.instance.addBookmark(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        page: page,
      );
      state = {...state, key};
    }
  }
}
