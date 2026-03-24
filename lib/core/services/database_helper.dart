import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// Singleton helper responsible for initialising and providing access to
/// both the bundled Quran database and the user-data database.
///
/// Usage:
/// ```dart
/// final db = await DatabaseHelper.instance.quranDatabase;
/// ```
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _quranDb;
  Database? _userDb;

  // ── Quran Database ────────────────────────────────────────────────────────

  /// Returns the Quran SQLite [Database], initialising it on the first call.
  ///
  /// On first run the bundled asset (`assets/data/quran.db`) is copied to the
  /// device's documents directory so sqflite can open it.
  Future<Database> get quranDatabase async {
    if (_quranDb != null) return _quranDb!;
    _quranDb = await _openQuranDatabase();
    return _quranDb!;
  }

  Future<Database> _openQuranDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, AppConstants.quranDbName);

    // Copy from assets if not already present.
    if (!File(dbPath).existsSync()) {
      await _copyAssetToFile(AppConstants.quranDbAssetPath, dbPath);
    }

    return openDatabase(
      dbPath,
      readOnly: true,
      version: 1,
    );
  }

  /// Copies a Flutter asset to [destinationPath] on the device.
  Future<void> _copyAssetToFile(
      String assetPath, String destinationPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await File(destinationPath).writeAsBytes(bytes, flush: true);
  }

  // ── User Database ─────────────────────────────────────────────────────────

  /// Returns the user-data SQLite [Database], initialising it on first call.
  ///
  /// This database stores bookmarks, reading progress, hifz data, etc.
  Future<Database> get userDatabase async {
    if (_userDb != null) return _userDb!;
    _userDb = await _openUserDatabase();
    return _userDb!;
  }

  Future<Database> _openUserDatabase() async {
    final dbsDir = await getDatabasesPath();
    final dbPath = p.join(dbsDir, '${AppConstants.userDbName}.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createUserTables,
      onUpgrade: _onUserDbUpgrade,
    );
  }

  Future<void> _createUserTables(Database db, int version) async {
    final batch = db.batch();

    // ── Reading Progress ──────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS reading_progress (
        id          INTEGER PRIMARY KEY,
        surah_number INTEGER NOT NULL,
        ayah_number  INTEGER NOT NULL,
        page         INTEGER NOT NULL DEFAULT 1,
        updated_at   TEXT    NOT NULL
      )
    ''');

    // ── Bookmarks ─────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number  INTEGER NOT NULL,
        page         INTEGER NOT NULL DEFAULT 1,
        note         TEXT,
        created_at   TEXT    NOT NULL,
        UNIQUE(surah_number, ayah_number)
      )
    ''');

    // ── Favorites ─────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number  INTEGER NOT NULL,
        created_at   TEXT    NOT NULL,
        UNIQUE(surah_number, ayah_number)
      )
    ''');

    // ── Hifz Progress ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS hifz_progress (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number  INTEGER NOT NULL,
        memorized    INTEGER NOT NULL DEFAULT 0,
        review_count INTEGER NOT NULL DEFAULT 0,
        last_review  TEXT,
        UNIQUE(surah_number, ayah_number)
      )
    ''');

    // ── Daily Ayah Cache ──────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS daily_ayah_cache (
        id         INTEGER PRIMARY KEY,
        ayah_id    INTEGER NOT NULL,
        date       TEXT    NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _onUserDbUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Reserved for future migrations.
  }

  // ── Reading Progress Helpers ──────────────────────────────────────────────

  /// Saves the current reading position (upsert).
  Future<void> saveReadingProgress({
    required int surahNumber,
    required int ayahNumber,
    required int page,
  }) async {
    final db = await userDatabase;
    await db.insert(
      'reading_progress',
      {
        'id': 1, // single-row table
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
        'page': page,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the last saved reading position, or null if none exists.
  Future<Map<String, dynamic>?> getReadingProgress() async {
    final db = await userDatabase;
    final rows = await db.query(
      'reading_progress',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  // ── Bookmark Helpers ──────────────────────────────────────────────────────

  /// Adds a bookmark, ignoring if it already exists.
  Future<void> addBookmark({
    required int surahNumber,
    required int ayahNumber,
    required int page,
    String? note,
  }) async {
    final db = await userDatabase;
    await db.insert(
      'bookmarks',
      {
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
        'page': page,
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Removes a bookmark.
  Future<void> removeBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final db = await userDatabase;
    await db.delete(
      'bookmarks',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
    );
  }

  /// Returns all bookmarks ordered by creation date (newest first).
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final db = await userDatabase;
    return db.query('bookmarks', orderBy: 'created_at DESC');
  }

  /// Returns whether a given ayah is bookmarked.
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final db = await userDatabase;
    final rows = await db.query(
      'bookmarks',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ── Daily Ayah Cache ──────────────────────────────────────────────────────

  /// Returns today's cached ayah ID, or null if none is cached.
  Future<int?> getDailyAyahId() async {
    final db = await userDatabase;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.query(
      'daily_ayah_cache',
      where: 'date = ?',
      whereArgs: [today],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['ayah_id'] as int?;
  }

  /// Caches the daily ayah ID for today.
  Future<void> saveDailyAyahId(int ayahId) async {
    final db = await userDatabase;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.insert(
      'daily_ayah_cache',
      {'id': 1, 'ayah_id': ayahId, 'date': today},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Closes both databases. Call only on app disposal.
  Future<void> closeAll() async {
    await _quranDb?.close();
    await _userDb?.close();
    _quranDb = null;
    _userDb = null;
  }
}
