import 'package:dartz/dartz.dart';

import '../entities/bookmark.dart';

/// Abstract repository defining the contract for bookmark persistence.
abstract class BookmarkRepository {
  /// Returns all bookmarks, sorted by [createdAt] descending.
  Future<Either<BookmarkFailure, List<Bookmark>>> getAllBookmarks();

  /// Returns all bookmarks in the given [folder].
  Future<Either<BookmarkFailure, List<Bookmark>>> getBookmarksByFolder(
    String folder,
  );

  /// Returns only favourite bookmarks.
  Future<Either<BookmarkFailure, List<Bookmark>>> getFavorites();

  /// Returns a bookmark by its [id], or null if not found.
  Future<Either<BookmarkFailure, Bookmark?>> getBookmarkById(String id);

  /// Checks whether a specific ayah is already bookmarked.
  Future<bool> isBookmarked(int surahNumber, int ayahNumber);

  /// Adds a new bookmark. Silently replaces an existing one for the same ayah.
  Future<Either<BookmarkFailure, Bookmark>> addBookmark(Bookmark bookmark);

  /// Updates an existing bookmark (note, colour, folder, favourite flag, etc.).
  Future<Either<BookmarkFailure, Bookmark>> updateBookmark(Bookmark bookmark);

  /// Removes the bookmark with the given [id].
  Future<Either<BookmarkFailure, void>> removeBookmark(String id);

  /// Removes all bookmarks.
  Future<Either<BookmarkFailure, void>> clearAllBookmarks();

  /// Returns a distinct list of all folder names in use.
  Future<Either<BookmarkFailure, List<String>>> getFolderNames();
}

/// Failure type for bookmark operations.
class BookmarkFailure {
  final String message;
  final Object? error;

  const BookmarkFailure(this.message, [this.error]);

  @override
  String toString() => 'BookmarkFailure: $message';
}
