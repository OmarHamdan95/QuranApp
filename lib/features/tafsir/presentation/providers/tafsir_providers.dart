import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/isar_service.dart';
import '../../data/repositories/tafsir_repository_impl.dart';
import '../../domain/entities/tafsir.dart';
import '../../domain/repositories/tafsir_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

/// Provides the [TafsirRepository] implementation.
final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) {
  return TafsirRepositoryImpl(IsarService.instance);
});

// ── Selected source provider ──────────────────────────────────────────────────

/// Tracks the currently selected tafsir source across the app.
final selectedTafsirSourceProvider = StateProvider<TafsirSource>(
  (_) => TafsirSource.muyassar,
);

/// Tracks the font size used in tafsir reading screens.
final tafsirFontSizeProvider = StateProvider<double>((_) => 17.0);

// ── Data providers ────────────────────────────────────────────────────────────

/// Unique key representing one tafsir request.
class TafsirKey {
  final int surahNumber;
  final int ayahNumber;
  final TafsirSource source;

  const TafsirKey({
    required this.surahNumber,
    required this.ayahNumber,
    required this.source,
  });

  @override
  bool operator ==(Object other) =>
      other is TafsirKey &&
      surahNumber == other.surahNumber &&
      ayahNumber == other.ayahNumber &&
      source == other.source;

  @override
  int get hashCode =>
      Object.hash(surahNumber, ayahNumber, source);
}

/// Fetches the tafsir for a single ayah and source combination.
final tafsirProvider = FutureProvider.family<Tafsir, TafsirKey>(
  (ref, key) async {
    final repository = ref.watch(tafsirRepositoryProvider);
    final result = await repository.getTafsir(
      surahNumber: key.surahNumber,
      ayahNumber: key.ayahNumber,
      source: key.source,
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (tafsir) => tafsir,
    );
  },
);

/// Fetches all tafsir entries for a surah from the selected source.
final tafsirBySurahProvider =
    FutureProvider.family<List<Tafsir>, (int, TafsirSource)>(
  (ref, params) async {
    final (surahNumber, source) = params;
    final repository = ref.watch(tafsirRepositoryProvider);
    final result = await repository.getTafsirBySurah(
      surahNumber: surahNumber,
      source: source,
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (list) => list,
    );
  },
);

/// Provides tafsir for all available sources for a given ayah.
/// Returns a map from source to tafsir text.
final allSourcesTafsirProvider =
    FutureProvider.family<Map<TafsirSource, Tafsir>, (int, int)>(
  (ref, params) async {
    final (surahNumber, ayahNumber) = params;
    final repository = ref.watch(tafsirRepositoryProvider);
    final results = <TafsirSource, Tafsir>{};

    for (final source in TafsirSource.values) {
      final result = await repository.getTafsir(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        source: source,
      );
      result.fold(
        (_) {},
        (tafsir) => results[source] = tafsir,
      );
    }

    return results;
  },
);
