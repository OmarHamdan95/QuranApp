import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../models/ayah_model.dart';
import '../models/surah_model.dart';

/// Implementation of [QuranRepository] backed by a bundled SQLite database.
///
/// The database file is copied from assets on first launch and accessed
/// read-only thereafter.
class QuranRepositoryImpl implements QuranRepository {
  final Database _database;

  QuranRepositoryImpl(this._database);

  @override
  Future<Either<QuranFailure, List<Surah>>> getSurahs() async {
    try {
      final rows = await _database.query(
        'surahs',
        orderBy: 'number ASC',
      );
      final surahs = rows.map((row) => SurahModel.fromMap(row)).toList();
      return Right(surahs);
    } catch (e) {
      return Left(QuranFailure('Failed to load surahs', e));
    }
  }

  @override
  Future<Either<QuranFailure, Surah>> getSurahByNumber(int surahNumber) async {
    try {
      final rows = await _database.query(
        'surahs',
        where: 'number = ?',
        whereArgs: [surahNumber],
        limit: 1,
      );
      if (rows.isEmpty) {
        return Left(QuranFailure('Surah $surahNumber not found'));
      }
      return Right(SurahModel.fromMap(rows.first));
    } catch (e) {
      return Left(QuranFailure('Failed to load surah $surahNumber', e));
    }
  }

  @override
  Future<Either<QuranFailure, List<Ayah>>> getAyahsBySurah(int surahNumber) async {
    try {
      final rows = await _database.query(
        'ayahs',
        where: 'surah_number = ?',
        whereArgs: [surahNumber],
        orderBy: 'ayah_number ASC',
      );
      final ayahs = rows.map((row) => AyahModel.fromMap(row)).toList();
      return Right(ayahs);
    } catch (e) {
      return Left(QuranFailure('Failed to load ayahs for surah $surahNumber', e));
    }
  }

  @override
  Future<Either<QuranFailure, List<Ayah>>> getAyahsByPage(int pageNumber) async {
    try {
      final rows = await _database.query(
        'ayahs',
        where: 'page = ?',
        whereArgs: [pageNumber],
        orderBy: 'id ASC',
      );
      final ayahs = rows.map((row) => AyahModel.fromMap(row)).toList();
      return Right(ayahs);
    } catch (e) {
      return Left(QuranFailure('Failed to load ayahs for page $pageNumber', e));
    }
  }

  @override
  Future<Either<QuranFailure, List<Ayah>>> getAyahsByJuz(int juzNumber) async {
    try {
      final rows = await _database.query(
        'ayahs',
        where: 'juz = ?',
        whereArgs: [juzNumber],
        orderBy: 'id ASC',
      );
      final ayahs = rows.map((row) => AyahModel.fromMap(row)).toList();
      return Right(ayahs);
    } catch (e) {
      return Left(QuranFailure('Failed to load ayahs for juz $juzNumber', e));
    }
  }

  @override
  Future<Either<QuranFailure, Ayah>> getAyah(int surahNumber, int ayahNumber) async {
    try {
      final rows = await _database.query(
        'ayahs',
        where: 'surah_number = ? AND ayah_number = ?',
        whereArgs: [surahNumber, ayahNumber],
        limit: 1,
      );
      if (rows.isEmpty) {
        return Left(QuranFailure('Ayah $surahNumber:$ayahNumber not found'));
      }
      return Right(AyahModel.fromMap(rows.first));
    } catch (e) {
      return Left(QuranFailure('Failed to load ayah $surahNumber:$ayahNumber', e));
    }
  }

  @override
  Future<Either<QuranFailure, List<Ayah>>> searchAyahs(String query) async {
    try {
      final rows = await _database.query(
        'ayahs',
        where: 'text_uthmani LIKE ? OR text_simple LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'id ASC',
        limit: 50,
      );
      final ayahs = rows.map((row) => AyahModel.fromMap(row)).toList();
      return Right(ayahs);
    } catch (e) {
      return Left(QuranFailure('Search failed for "$query"', e));
    }
  }

  @override
  Future<Either<QuranFailure, Ayah>> getRandomAyah() async {
    try {
      // Pick a random ayah ID between 1 and 6236.
      final randomId = Random().nextInt(6236) + 1;
      final rows = await _database.query(
        'ayahs',
        where: 'id = ?',
        whereArgs: [randomId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return Left(const QuranFailure('Could not fetch random ayah'));
      }
      return Right(AyahModel.fromMap(rows.first));
    } catch (e) {
      return Left(QuranFailure('Failed to fetch random ayah', e));
    }
  }

  @override
  Future<Either<QuranFailure, int>> getAyahCount(int surahNumber) async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM ayahs WHERE surah_number = ?',
        [surahNumber],
      );
      final count = result.first['count'] as int;
      return Right(count);
    } catch (e) {
      return Left(QuranFailure('Failed to get ayah count for surah $surahNumber', e));
    }
  }
}
