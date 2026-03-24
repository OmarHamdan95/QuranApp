import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';

/// Provider for the [QuranRepository] implementation.
///
/// Must be overridden at app startup once the database is initialized.
final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  throw UnimplementedError(
    'quranRepositoryProvider must be overridden with a concrete implementation '
    'after the database is initialized.',
  );
});

/// Fetches all 114 surahs. Cached automatically by Riverpod.
final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  final result = await repository.getSurahs();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (surahs) => surahs,
  );
});

/// Fetches ayahs for a specific surah, parameterized by surah number.
final ayahsBySurahProvider = FutureProvider.family<List<Ayah>, int>(
  (ref, surahNumber) async {
    final repository = ref.watch(quranRepositoryProvider);
    final result = await repository.getAyahsBySurah(surahNumber);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (ayahs) => ayahs,
    );
  },
);

/// Fetches a single surah by number.
final surahProvider = FutureProvider.family<Surah, int>(
  (ref, surahNumber) async {
    final repository = ref.watch(quranRepositoryProvider);
    final result = await repository.getSurahByNumber(surahNumber);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (surah) => surah,
    );
  },
);

/// Fetches ayahs for a specific page of the Mushaf.
final ayahsByPageProvider = FutureProvider.family<List<Ayah>, int>(
  (ref, pageNumber) async {
    final repository = ref.watch(quranRepositoryProvider);
    final result = await repository.getAyahsByPage(pageNumber);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (ayahs) => ayahs,
    );
  },
);

/// Fetches ayahs for a specific juz.
final ayahsByJuzProvider = FutureProvider.family<List<Ayah>, int>(
  (ref, juzNumber) async {
    final repository = ref.watch(quranRepositoryProvider);
    final result = await repository.getAyahsByJuz(juzNumber);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (ayahs) => ayahs,
    );
  },
);

/// Searches ayahs by query text.
final searchAyahsProvider = FutureProvider.family<List<Ayah>, String>(
  (ref, query) async {
    if (query.trim().isEmpty) return [];
    final repository = ref.watch(quranRepositoryProvider);
    final result = await repository.searchAyahs(query);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (ayahs) => ayahs,
    );
  },
);

/// Fetches a random ayah for the daily ayah card.
final dailyAyahProvider = FutureProvider<Ayah>((ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  final result = await repository.getRandomAyah();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (ayah) => ayah,
  );
});

/// Tracks the current Quran reading mode.
enum QuranViewMode { surahList, juzList, pageView }

final quranViewModeProvider = StateProvider<QuranViewMode>(
  (ref) => QuranViewMode.surahList,
);

/// Tracks the current reading position for "last read" feature.
class ReadingPosition {
  final int surahNumber;
  final int ayahNumber;
  final int page;
  final DateTime timestamp;

  const ReadingPosition({
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
    required this.timestamp,
  });
}

final lastReadPositionProvider = StateProvider<ReadingPosition?>((ref) => null);

/// Font size for Quran text, persisted in preferences.
final quranFontSizeProvider = StateProvider<double>((ref) => 28.0);

/// Whether to show translation alongside Arabic text.
final showTranslationProvider = StateProvider<bool>((ref) => true);
