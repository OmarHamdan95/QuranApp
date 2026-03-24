import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/isar_service.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../models/bookmark_model.dart';

/// SharedPreferences-backed implementation of [BookmarkRepository].
///
/// All bookmarks are stored as a JSON-encoded list under [_storageKey].
/// Reads and writes are performed synchronously against the in-memory
/// [SharedPreferences] cache; persistence is handled by the platform layer.
class BookmarkRepositoryImpl implements BookmarkRepository {
  static const String _storageKey = 'bookmarks_v1';

  final IsarService _isarService;

  BookmarkRepositoryImpl(this._isarService);

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Loads all bookmarks from storage.
  List<BookmarkModel> _loadAll() {
    try {
      final list = _isarService.getStringList(_storageKey);
      return list
          .map((json) =>
              BookmarkModel.fromMap(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('BookmarkRepositoryImpl._loadAll error: $e');
      return [];
    }
  }

  /// Persists the full list of bookmarks to storage.
  Future<void> _saveAll(List<BookmarkModel> bookmarks) async {
    final encoded = bookmarks.map((b) => b.toJson()).toList();
    await _isarService.setStringList(_storageKey, encoded);
  }

  // ── BookmarkRepository interface ──────────────────────────────────────────

  @override
  Future<Either<BookmarkFailure, List<Bookmark>>> getAllBookmarks() async {
    try {
      final bookmarks = _loadAll()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(bookmarks);
    } catch (e) {
      return Left(BookmarkFailure('Failed to load bookmarks', e));
    }
  }

  @override
  Future<Either<BookmarkFailure, List<Bookmark>>> getBookmarksByFolder(
    String folder,
  ) async {
    try {
      final all = _loadAll();
      final filtered = all
          .where((b) => b.folder == folder)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(filtered);
    } catch (e) {
      return Left(BookmarkFailure('Failed to load bookmarks for folder: $folder', e));
    }
  }

  @override
  Future<Either<BookmarkFailure, List<Bookmark>>> getFavorites() async {
    try {
      final favorites = _loadAll()
          .where((b) => b.isFavorite)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(favorites);
    } catch (e) {
      return Left(BookmarkFailure('Failed to load favorites', e));
    }
  }

  @override
  Future<Either<BookmarkFailure, Bookmark?>> getBookmarkById(String id) async {
    try {
      final all = _loadAll();
      final match = all.where((b) => b.id == id).firstOrNull;
      return Right(match);
    } catch (e) {
      return Left(BookmarkFailure('Failed to find bookmark: $id', e));
    }
  }

  @override
  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    try {
      final all = _loadAll();
      return all.any(
        (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<BookmarkFailure, Bookmark>> addBookmark(
    Bookmark bookmark,
  ) async {
    try {
      final all = _loadAll();
      // Replace if an entry for the same ayah already exists.
      all.removeWhere(
        (b) =>
            b.surahNumber == bookmark.surahNumber &&
            b.ayahNumber == bookmark.ayahNumber,
      );
      final model = BookmarkModel.fromEntity(bookmark);
      all.insert(0, model);
      await _saveAll(all);
      return Right(model);
    } catch (e) {
      return Left(BookmarkFailure('Failed to add bookmark', e));
    }
  }

  @override
  Future<Either<BookmarkFailure, Bookmark>> updateBookmark(
    Bookmark bookmark,
  ) async {
    try {
      final all = _loadAll();
      final index = all.indexWhere((b) => b.id == bookmark.id);
      if (index == -1) {
        return Left(BookmarkFailure('Bookmark not found: ${bookmark.id}'));
      }
      final updated = BookmarkModel.fromEntity(bookmark);
      all[index] = updated;
      await _saveAll(all);
      return Right(updated);
    } catch (e) {
      return Left(BookmarkFailure('Failed to update bookmark', e));
    }
  }

  @override
  Future<Either<BookmarkFailure, void>> removeBookmark(String id) async {
    try {
      final all = _loadAll()..removeWhere((b) => b.id == id);
      await _saveAll(all);
      return const Right(null);
    } catch (e) {
      return Left(BookmarkFailure('Failed to remove bookmark', e));
    }
  }

  @override
  Future<Either<BookmarkFailure, void>> clearAllBookmarks() async {
    try {
      await _isarService.remove(_storageKey);
      return const Right(null);
    } catch (e) {
      return Left(BookmarkFailure('Failed to clear bookmarks', e));
    }
  }

  @override
  Future<Either<BookmarkFailure, List<String>>> getFolderNames() async {
    try {
      final all = _loadAll();
      final folders = <String>{'عام'};
      for (final b in all) {
        folders.add(b.folder);
      }
      return Right(folders.toList()..sort());
    } catch (e) {
      return Left(BookmarkFailure('Failed to load folder names', e));
    }
  }
}
