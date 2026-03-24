import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/isar_service.dart';
import '../../../quran/domain/entities/ayah.dart';
import '../../../quran/domain/entities/surah.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/search_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

/// Provides the [SearchRepository] implementation.
final searchRepositoryProvider = FutureProvider<SearchRepository>((ref) async {
  final quranRepository = await ref.watch(quranRepositoryProvider.future);
  return SearchRepositoryImpl(
    quranRepository: quranRepository,
    isarService: IsarService.instance,
  );
});

// ── Search query state ────────────────────────────────────────────────────────

/// The live search query typed by the user.
final searchQueryProvider = StateProvider<String>((_) => '');

/// The active search filter.
final searchFilterProvider = StateProvider<SearchFilter>(
  (_) => const SearchFilter(),
);

// ── Recent searches ───────────────────────────────────────────────────────────

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  final SearchRepository? _repository;

  RecentSearchesNotifier(SearchRepository repository) : _repository = repository, super([]) {
    _load();
  }

  RecentSearchesNotifier._placeholder() : _repository = null, super([]);

  Future<void> _load() async {
    if (_repository == null) return;
    state = await _repository.getRecentSearches();
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty || _repository == null) return;
    await _repository.saveRecentSearch(query.trim());
    await _load();
  }

  Future<void> clearAll() async {
    await _repository?.clearRecentSearches();
    state = [];
  }

  void remove(String query) {
    state = state.where((q) => q != query).toList();
  }
}

/// Manages recent search history.
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
  (ref) {
    final repo = ref.watch(searchRepositoryProvider).valueOrNull;
    if (repo == null) return RecentSearchesNotifier._placeholder();
    return RecentSearchesNotifier(repo);
  },
);

// ── Debounced search results ──────────────────────────────────────────────────

/// Ayah search results for the current query and filter.
final searchResultsProvider = FutureProvider<List<Ayah>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);

  if (query.trim().isEmpty) return [];

  final repository = await ref.watch(searchRepositoryProvider.future);
  final result = await repository.searchAyahs(
    query,
    filter: filter.hasActiveFilters ? filter : null,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (ayahs) => ayahs,
  );
});

/// Surah search results for the current query.
final surahSearchResultsProvider = FutureProvider<List<Surah>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final repository = await ref.watch(searchRepositoryProvider.future);
  final result = await repository.searchSurahs(query);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (surahs) => surahs,
  );
});

/// Tracks whether the search filter panel is visible.
final showSearchFilterProvider = StateProvider<bool>((_) => false);

/// Tracks the active search scope (ayahs or surahs).
enum SearchScope { ayahs, surahs }

final searchScopeProvider = StateProvider<SearchScope>(
  (_) => SearchScope.ayahs,
);
