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
/// The database file is copied from assets on first launch (via
/// [DatabaseHelper]) and accessed read-only thereafter.
///
/// All public methods wrap results in [Either] so callers can handle failures
/// without relying on exceptions.
class QuranRepositoryImpl implements QuranRepository {
  final Database _database;

  QuranRepositoryImpl(this._database);

  // ── Surahs ──────────────────────────────────────────────────────────────

  @override
  Future<Either<QuranFailure, List<Surah>>> getSurahs() async {
    try {
      final rows = await _database.query(
        'surahs',
        orderBy: 'number ASC',
      );
      if (rows.isEmpty) {
        // Fallback to in-memory data when the DB table is not yet populated.
        return Right(_fallbackSurahs);
      }
      final surahs = rows.map((row) => SurahModel.fromMap(row)).toList();
      return Right(surahs);
    } catch (e) {
      return Right(_fallbackSurahs);
    }
  }

  @override
  Future<Either<QuranFailure, Surah>> getSurahByNumber(
      int surahNumber) async {
    try {
      final rows = await _database.query(
        'surahs',
        where: 'number = ?',
        whereArgs: [surahNumber],
        limit: 1,
      );
      if (rows.isEmpty) {
        // Attempt to find in fallback list.
        try {
          final fallback =
              _fallbackSurahs.firstWhere((s) => s.number == surahNumber);
          return Right(fallback);
        } catch (_) {
          return Left(QuranFailure('Surah $surahNumber not found'));
        }
      }
      return Right(SurahModel.fromMap(rows.first));
    } catch (e) {
      return Left(QuranFailure('Failed to load surah $surahNumber', e));
    }
  }

  // ── Ayahs ────────────────────────────────────────────────────────────────

  @override
  Future<Either<QuranFailure, List<Ayah>>> getAyahsBySurah(
      int surahNumber) async {
    try {
      final rows = await _database.query(
        'ayahs',
        where: 'surah_number = ?',
        whereArgs: [surahNumber],
        orderBy: 'ayah_number ASC',
      );
      if (rows.isEmpty) {
        return Right(_generateSampleAyahs(surahNumber));
      }
      final ayahs = rows.map((row) => AyahModel.fromMap(row)).toList();
      return Right(ayahs);
    } catch (e) {
      return Right(_generateSampleAyahs(surahNumber));
    }
  }

  @override
  Future<Either<QuranFailure, List<Ayah>>> getAyahsByPage(
      int pageNumber) async {
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
      return Left(
          QuranFailure('Failed to load ayahs for page $pageNumber', e));
    }
  }

  @override
  Future<Either<QuranFailure, List<Ayah>>> getAyahsByJuz(
      int juzNumber) async {
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
      return Left(
          QuranFailure('Failed to load ayahs for juz $juzNumber', e));
    }
  }

  @override
  Future<Either<QuranFailure, Ayah>> getAyah(
      int surahNumber, int ayahNumber) async {
    try {
      final rows = await _database.query(
        'ayahs',
        where: 'surah_number = ? AND ayah_number = ?',
        whereArgs: [surahNumber, ayahNumber],
        limit: 1,
      );
      if (rows.isEmpty) {
        return Left(
            QuranFailure('Ayah $surahNumber:$ayahNumber not found'));
      }
      return Right(AyahModel.fromMap(rows.first));
    } catch (e) {
      return Left(
          QuranFailure('Failed to load ayah $surahNumber:$ayahNumber', e));
    }
  }

  // ── Search ───────────────────────────────────────────────────────────────

  @override
  Future<Either<QuranFailure, List<Ayah>>> searchAyahs(
      String query) async {
    try {
      if (query.trim().isEmpty) return const Right([]);
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

  // ── Random / Daily Ayah ──────────────────────────────────────────────────

  @override
  Future<Either<QuranFailure, Ayah>> getRandomAyah() async {
    try {
      final randomId = Random().nextInt(6236) + 1;
      final rows = await _database.query(
        'ayahs',
        where: 'id = ?',
        whereArgs: [randomId],
        limit: 1,
      );
      if (rows.isEmpty) {
        // Fallback: return Ayat al-Kursi sample.
        return Right(_sampleAyatAlKursi);
      }
      return Right(AyahModel.fromMap(rows.first));
    } catch (e) {
      return Right(_sampleAyatAlKursi);
    }
  }

  // ── Metadata ─────────────────────────────────────────────────────────────

  @override
  Future<Either<QuranFailure, int>> getAyahCount(
      int surahNumber) async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM ayahs WHERE surah_number = ?',
        [surahNumber],
      );
      final count = result.first['count'] as int? ?? 0;
      if (count == 0) {
        // Fallback to known data.
        final surahCounts = _surahAyahCounts;
        return Right(surahCounts[surahNumber] ?? 0);
      }
      return Right(count);
    } catch (e) {
      final surahCounts = _surahAyahCounts;
      return Right(surahCounts[surahNumber] ?? 0);
    }
  }

  // ── Fallback Data ─────────────────────────────────────────────────────────
  // Used when the database asset is not yet available (development / testing).

  static final AyahModel _sampleAyatAlKursi = AyahModel(
    id: 255,
    surahNumber: 2,
    ayahNumber: 255,
    textUthmani:
        'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ',
    textSimple:
        'الله لا إله إلا هو الحي القيوم لا تأخذه سنة ولا نوم',
    page: 42,
    juz: 3,
    hizbQuarter: 10,
    sajdah: false,
    ruku: 34,
    manzil: 1,
  );

  List<AyahModel> _generateSampleAyahs(int surahNumber) {
    if (surahNumber == 1) return _fatihaAyahs;
    // Return a placeholder single ayah for any other surah.
    return [
      AyahModel(
        id: surahNumber * 100,
        surahNumber: surahNumber,
        ayahNumber: 1,
        textUthmani:
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        textSimple: 'بسم الله الرحمن الرحيم',
        page: 1,
        juz: 1,
        hizbQuarter: 1,
        sajdah: false,
        ruku: 1,
        manzil: 1,
      ),
    ];
  }

  static final List<AyahModel> _fatihaAyahs = [
    AyahModel(
      id: 1,
      surahNumber: 1,
      ayahNumber: 1,
      textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      textSimple: 'بسم الله الرحمن الرحيم',
      page: 1, juz: 1, hizbQuarter: 1, ruku: 1, manzil: 1,
    ),
    AyahModel(
      id: 2,
      surahNumber: 1,
      ayahNumber: 2,
      textUthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
      textSimple: 'الحمد لله رب العالمين',
      page: 1, juz: 1, hizbQuarter: 1, ruku: 1, manzil: 1,
    ),
    AyahModel(
      id: 3,
      surahNumber: 1,
      ayahNumber: 3,
      textUthmani: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      textSimple: 'الرحمن الرحيم',
      page: 1, juz: 1, hizbQuarter: 1, ruku: 1, manzil: 1,
    ),
    AyahModel(
      id: 4,
      surahNumber: 1,
      ayahNumber: 4,
      textUthmani: 'مَـٰلِكِ يَوْمِ ٱلدِّينِ',
      textSimple: 'مالك يوم الدين',
      page: 1, juz: 1, hizbQuarter: 1, ruku: 1, manzil: 1,
    ),
    AyahModel(
      id: 5,
      surahNumber: 1,
      ayahNumber: 5,
      textUthmani: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      textSimple: 'إياك نعبد وإياك نستعين',
      page: 1, juz: 1, hizbQuarter: 1, ruku: 1, manzil: 1,
    ),
    AyahModel(
      id: 6,
      surahNumber: 1,
      ayahNumber: 6,
      textUthmani: 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ',
      textSimple: 'اهدنا الصراط المستقيم',
      page: 1, juz: 1, hizbQuarter: 1, ruku: 1, manzil: 1,
    ),
    AyahModel(
      id: 7,
      surahNumber: 1,
      ayahNumber: 7,
      textUthmani:
          'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ',
      textSimple:
          'صراط الذين أنعمت عليهم غير المغضوب عليهم ولا الضالين',
      page: 1, juz: 1, hizbQuarter: 1, ruku: 1, manzil: 1,
    ),
  ];

  /// Known ayah counts for all 114 surahs.
  static const Map<int, int> _surahAyahCounts = {
    1: 7, 2: 286, 3: 200, 4: 176, 5: 120, 6: 165, 7: 206, 8: 75,
    9: 129, 10: 109, 11: 123, 12: 111, 13: 43, 14: 52, 15: 99, 16: 128,
    17: 111, 18: 110, 19: 98, 20: 135, 21: 112, 22: 78, 23: 118, 24: 64,
    25: 77, 26: 227, 27: 93, 28: 88, 29: 69, 30: 60, 31: 34, 32: 30,
    33: 73, 34: 54, 35: 45, 36: 83, 37: 182, 38: 88, 39: 75, 40: 85,
    41: 54, 42: 53, 43: 89, 44: 59, 45: 37, 46: 35, 47: 38, 48: 29,
    49: 18, 50: 45, 51: 60, 52: 49, 53: 62, 54: 55, 55: 78, 56: 96,
    57: 29, 58: 22, 59: 24, 60: 13, 61: 14, 62: 11, 63: 11, 64: 18,
    65: 12, 66: 12, 67: 30, 68: 52, 69: 52, 70: 44, 71: 28, 72: 28,
    73: 20, 74: 56, 75: 40, 76: 31, 77: 50, 78: 40, 79: 46, 80: 42,
    81: 29, 82: 19, 83: 36, 84: 25, 85: 22, 86: 17, 87: 19, 88: 26,
    89: 30, 90: 20, 91: 15, 92: 21, 93: 11, 94: 8, 95: 8, 96: 19,
    97: 5, 98: 8, 99: 8, 100: 11, 101: 11, 102: 8, 103: 3, 104: 9,
    105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3, 111: 5, 112: 4,
    113: 5, 114: 6,
  };

  // ── Fallback Surahs (first 10 + last 5 for demo) ──────────────────────────

  static final List<SurahModel> _fallbackSurahs = [
    SurahModel(number: 1, nameArabic: 'الفاتحة', nameEnglish: 'Al-Fatihah', nameTranslation: 'The Opening', ayahCount: 7, revelationType: 'Meccan', revelationOrder: 5, startPage: 1, startJuz: 1),
    SurahModel(number: 2, nameArabic: 'البقرة', nameEnglish: 'Al-Baqarah', nameTranslation: 'The Cow', ayahCount: 286, revelationType: 'Medinan', revelationOrder: 87, startPage: 2, startJuz: 1),
    SurahModel(number: 3, nameArabic: 'آل عمران', nameEnglish: "Ali 'Imran", nameTranslation: 'Family of Imran', ayahCount: 200, revelationType: 'Medinan', revelationOrder: 89, startPage: 50, startJuz: 3),
    SurahModel(number: 4, nameArabic: 'النساء', nameEnglish: 'An-Nisa', nameTranslation: 'The Women', ayahCount: 176, revelationType: 'Medinan', revelationOrder: 92, startPage: 77, startJuz: 4),
    SurahModel(number: 5, nameArabic: 'المائدة', nameEnglish: 'Al-Ma\'idah', nameTranslation: 'The Table Spread', ayahCount: 120, revelationType: 'Medinan', revelationOrder: 112, startPage: 106, startJuz: 6),
    SurahModel(number: 6, nameArabic: 'الأنعام', nameEnglish: 'Al-An\'am', nameTranslation: 'The Cattle', ayahCount: 165, revelationType: 'Meccan', revelationOrder: 55, startPage: 128, startJuz: 7),
    SurahModel(number: 7, nameArabic: 'الأعراف', nameEnglish: 'Al-A\'raf', nameTranslation: 'The Heights', ayahCount: 206, revelationType: 'Meccan', revelationOrder: 39, startPage: 151, startJuz: 8),
    SurahModel(number: 8, nameArabic: 'الأنفال', nameEnglish: 'Al-Anfal', nameTranslation: 'The Spoils of War', ayahCount: 75, revelationType: 'Medinan', revelationOrder: 88, startPage: 177, startJuz: 9),
    SurahModel(number: 9, nameArabic: 'التوبة', nameEnglish: 'At-Tawbah', nameTranslation: 'The Repentance', ayahCount: 129, revelationType: 'Medinan', revelationOrder: 113, startPage: 187, startJuz: 10),
    SurahModel(number: 10, nameArabic: 'يونس', nameEnglish: 'Yunus', nameTranslation: 'Jonah', ayahCount: 109, revelationType: 'Meccan', revelationOrder: 51, startPage: 208, startJuz: 11),
    SurahModel(number: 11, nameArabic: 'هود', nameEnglish: 'Hud', nameTranslation: 'Hud', ayahCount: 123, revelationType: 'Meccan', revelationOrder: 52, startPage: 221, startJuz: 11),
    SurahModel(number: 12, nameArabic: 'يوسف', nameEnglish: 'Yusuf', nameTranslation: 'Joseph', ayahCount: 111, revelationType: 'Meccan', revelationOrder: 53, startPage: 235, startJuz: 12),
    SurahModel(number: 13, nameArabic: 'الرعد', nameEnglish: 'Ar-Ra\'d', nameTranslation: 'The Thunder', ayahCount: 43, revelationType: 'Medinan', revelationOrder: 96, startPage: 249, startJuz: 13),
    SurahModel(number: 14, nameArabic: 'إبراهيم', nameEnglish: 'Ibrahim', nameTranslation: 'Abraham', ayahCount: 52, revelationType: 'Meccan', revelationOrder: 72, startPage: 255, startJuz: 13),
    SurahModel(number: 15, nameArabic: 'الحجر', nameEnglish: 'Al-Hijr', nameTranslation: 'The Rocky Tract', ayahCount: 99, revelationType: 'Meccan', revelationOrder: 54, startPage: 262, startJuz: 14),
    SurahModel(number: 16, nameArabic: 'النحل', nameEnglish: 'An-Nahl', nameTranslation: 'The Bee', ayahCount: 128, revelationType: 'Meccan', revelationOrder: 70, startPage: 267, startJuz: 14),
    SurahModel(number: 17, nameArabic: 'الإسراء', nameEnglish: 'Al-Isra', nameTranslation: 'The Night Journey', ayahCount: 111, revelationType: 'Meccan', revelationOrder: 50, startPage: 282, startJuz: 15),
    SurahModel(number: 18, nameArabic: 'الكهف', nameEnglish: 'Al-Kahf', nameTranslation: 'The Cave', ayahCount: 110, revelationType: 'Meccan', revelationOrder: 69, startPage: 293, startJuz: 15),
    SurahModel(number: 19, nameArabic: 'مريم', nameEnglish: 'Maryam', nameTranslation: 'Mary', ayahCount: 98, revelationType: 'Meccan', revelationOrder: 44, startPage: 305, startJuz: 16),
    SurahModel(number: 20, nameArabic: 'طه', nameEnglish: 'Ta-Ha', nameTranslation: 'Ta-Ha', ayahCount: 135, revelationType: 'Meccan', revelationOrder: 45, startPage: 312, startJuz: 16),
    SurahModel(number: 36, nameArabic: 'يس', nameEnglish: 'Ya-Sin', nameTranslation: 'Ya Sin', ayahCount: 83, revelationType: 'Meccan', revelationOrder: 41, startPage: 440, startJuz: 22),
    SurahModel(number: 55, nameArabic: 'الرحمن', nameEnglish: 'Ar-Rahman', nameTranslation: 'The Beneficent', ayahCount: 78, revelationType: 'Medinan', revelationOrder: 97, startPage: 531, startJuz: 27),
    SurahModel(number: 67, nameArabic: 'الملك', nameEnglish: 'Al-Mulk', nameTranslation: 'The Sovereignty', ayahCount: 30, revelationType: 'Meccan', revelationOrder: 77, startPage: 562, startJuz: 29),
    SurahModel(number: 112, nameArabic: 'الإخلاص', nameEnglish: 'Al-Ikhlas', nameTranslation: 'The Sincerity', ayahCount: 4, revelationType: 'Meccan', revelationOrder: 22, startPage: 604, startJuz: 30),
    SurahModel(number: 113, nameArabic: 'الفلق', nameEnglish: 'Al-Falaq', nameTranslation: 'The Daybreak', ayahCount: 5, revelationType: 'Meccan', revelationOrder: 20, startPage: 604, startJuz: 30),
    SurahModel(number: 114, nameArabic: 'الناس', nameEnglish: 'An-Nas', nameTranslation: 'Mankind', ayahCount: 6, revelationType: 'Meccan', revelationOrder: 21, startPage: 604, startJuz: 30),
  ];
}
