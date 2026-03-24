import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bookmark.dart';

/// In-memory bookmark state notifier.
/// In production, this will be backed by Isar.
class BookmarkListNotifier extends StateNotifier<List<Bookmark>> {
  BookmarkListNotifier() : super([]);

  void addBookmark(Bookmark bookmark) {
    // Prevent duplicates.
    if (state.any((b) => b.surahNumber == bookmark.surahNumber && b.ayahNumber == bookmark.ayahNumber)) {
      return;
    }
    state = [...state, bookmark];
  }

  void removeBookmark(String id) {
    state = state.where((b) => b.id != id).toList();
  }

  void toggleFavorite(String id) {
    state = state.map((b) {
      if (b.id == id) {
        return Bookmark(
          id: b.id,
          surahNumber: b.surahNumber,
          ayahNumber: b.ayahNumber,
          surahName: b.surahName,
          ayahText: b.ayahText,
          page: b.page,
          createdAt: b.createdAt,
          note: b.note,
          isFavorite: !b.isFavorite,
          color: b.color,
        );
      }
      return b;
    }).toList();
  }

  void updateNote(String id, String note) {
    state = state.map((b) {
      if (b.id == id) {
        return Bookmark(
          id: b.id,
          surahNumber: b.surahNumber,
          ayahNumber: b.ayahNumber,
          surahName: b.surahName,
          ayahText: b.ayahText,
          page: b.page,
          createdAt: b.createdAt,
          note: note,
          isFavorite: b.isFavorite,
          color: b.color,
        );
      }
      return b;
    }).toList();
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    return state.any(
      (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
    );
  }
}

final bookmarkListProvider =
    StateNotifierProvider<BookmarkListNotifier, List<Bookmark>>((ref) {
  return BookmarkListNotifier();
});

/// Derived provider: only favorite bookmarks.
final favoritesProvider = Provider<List<Bookmark>>((ref) {
  final bookmarks = ref.watch(bookmarkListProvider);
  return bookmarks.where((b) => b.isFavorite).toList();
});

/// Derived provider: check if specific ayah is bookmarked.
final isBookmarkedProvider = Provider.family<bool, (int, int)>((ref, params) {
  final (surahNumber, ayahNumber) = params;
  final bookmarks = ref.watch(bookmarkListProvider);
  return bookmarks.any(
    (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
  );
});
