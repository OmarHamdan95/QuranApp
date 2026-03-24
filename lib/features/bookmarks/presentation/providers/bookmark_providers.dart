import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/isar_service.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

/// Provides the [BookmarkRepository] backed by [IsarService].
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepositoryImpl(IsarService.instance);
});

// ── State Notifier ────────────────────────────────────────────────────────────

/// Manages the full list of bookmarks with CRUD operations.
///
/// All mutations immediately update local state and persist to storage.
class BookmarkListNotifier extends StateNotifier<AsyncValue<List<Bookmark>>> {
  final BookmarkRepository _repository;

  BookmarkListNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllBookmarks();
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      AsyncValue.data,
    );
  }

  /// Refreshes the list from storage.
  Future<void> refresh() => _loadAll();

  /// Adds a new bookmark. No-op if an identical ayah is already bookmarked.
  Future<void> addBookmark(Bookmark bookmark) async {
    final result = await _repository.addBookmark(bookmark);
    result.fold(
      (_) => null,
      (_) => _loadAll(),
    );
  }

  /// Removes the bookmark with the given [id].
  Future<void> removeBookmark(String id) async {
    final result = await _repository.removeBookmark(id);
    result.fold(
      (_) => null,
      (_) => _loadAll(),
    );
  }

  /// Toggles the favourite flag for the bookmark with the given [id].
  Future<void> toggleFavorite(String id) async {
    final current = state.valueOrNull ?? [];
    final bookmark = current.where((b) => b.id == id).firstOrNull;
    if (bookmark == null) return;

    final updated = bookmark.copyWith(isFavorite: !bookmark.isFavorite);
    final result = await _repository.updateBookmark(updated);
    result.fold(
      (_) => null,
      (_) => _loadAll(),
    );
  }

  /// Updates the note on a bookmark.
  Future<void> updateNote(String id, String note) async {
    final current = state.valueOrNull ?? [];
    final bookmark = current.where((b) => b.id == id).firstOrNull;
    if (bookmark == null) return;

    final updated = bookmark.copyWith(note: note);
    final result = await _repository.updateBookmark(updated);
    result.fold(
      (_) => null,
      (_) => _loadAll(),
    );
  }

  /// Moves a bookmark to a different folder.
  Future<void> moveToFolder(String id, String folder) async {
    final current = state.valueOrNull ?? [];
    final bookmark = current.where((b) => b.id == id).firstOrNull;
    if (bookmark == null) return;

    final updated = bookmark.copyWith(folder: folder);
    final result = await _repository.updateBookmark(updated);
    result.fold(
      (_) => null,
      (_) => _loadAll(),
    );
  }

  /// Changes the colour label of a bookmark.
  Future<void> updateColor(String id, BookmarkColor color) async {
    final current = state.valueOrNull ?? [];
    final bookmark = current.where((b) => b.id == id).firstOrNull;
    if (bookmark == null) return;

    final updated = bookmark.copyWith(color: color);
    final result = await _repository.updateBookmark(updated);
    result.fold(
      (_) => null,
      (_) => _loadAll(),
    );
  }

  /// Clears all bookmarks.
  Future<void> clearAll() async {
    final result = await _repository.clearAllBookmarks();
    result.fold(
      (_) => null,
      (_) => state = const AsyncValue.data([]),
    );
  }

  /// Returns true if the given ayah is already bookmarked (synchronous).
  bool isBookmarked(int surahNumber, int ayahNumber) {
    final list = state.valueOrNull ?? [];
    return list.any(
      (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
    );
  }
}

/// Provides the [BookmarkListNotifier] and its state.
final bookmarkListProvider =
    StateNotifierProvider<BookmarkListNotifier, AsyncValue<List<Bookmark>>>(
  (ref) => BookmarkListNotifier(ref.watch(bookmarkRepositoryProvider)),
);

// ── Derived providers ─────────────────────────────────────────────────────────

/// Provides bookmarks for a specific folder.
final bookmarksByFolderProvider =
    Provider.family<List<Bookmark>, String>((ref, folder) {
  final state = ref.watch(bookmarkListProvider);
  final all = state.valueOrNull ?? [];
  if (folder == 'الكل') return all;
  return all.where((b) => b.folder == folder).toList();
});

/// Provides only favourite bookmarks.
final favoritesProvider = Provider<List<Bookmark>>((ref) {
  final state = ref.watch(bookmarkListProvider);
  final all = state.valueOrNull ?? [];
  return all.where((b) => b.isFavorite).toList();
});

/// Provides distinct folder names derived from the current bookmark list.
final folderNamesProvider = Provider<List<String>>((ref) {
  final state = ref.watch(bookmarkListProvider);
  final all = state.valueOrNull ?? [];
  final folders = <String>{'عام'};
  for (final b in all) {
    folders.add(b.folder);
  }
  return folders.toList()..sort();
});

/// Returns true when the given (surahNumber, ayahNumber) pair is bookmarked.
final isBookmarkedProvider = Provider.family<bool, (int, int)>((ref, params) {
  final (surahNumber, ayahNumber) = params;
  final state = ref.watch(bookmarkListProvider);
  final all = state.valueOrNull ?? [];
  return all.any(
    (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
  );
});

/// Provides the bookmark object for a specific ayah, if it exists.
final bookmarkForAyahProvider =
    Provider.family<Bookmark?, (int, int)>((ref, params) {
  final (surahNumber, ayahNumber) = params;
  final state = ref.watch(bookmarkListProvider);
  final all = state.valueOrNull ?? [];
  try {
    return all.firstWhere(
      (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
    );
  } catch (_) {
    return null;
  }
});

/// Provides the count of bookmarks per folder.
final bookmarkCountByFolderProvider =
    Provider.family<int, String>((ref, folder) {
  final state = ref.watch(bookmarkListProvider);
  final all = state.valueOrNull ?? [];
  if (folder == 'الكل') return all.length;
  return all.where((b) => b.folder == folder).length;
});

// ── Currently selected folder for the bookmarks screen ───────────────────────

/// Tracks the active folder tab on the bookmarks screen.
final selectedFolderProvider = StateProvider<String>((ref) => 'الكل');
