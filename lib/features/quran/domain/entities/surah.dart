import 'package:equatable/equatable.dart';

/// Domain entity representing a Surah (chapter) of the Quran.
class Surah extends Equatable {
  /// Surah number (1-114).
  final int number;

  /// Arabic name of the surah (e.g., الفاتحة).
  final String nameArabic;

  /// English transliteration (e.g., Al-Fatihah).
  final String nameEnglish;

  /// English meaning of the surah name (e.g., The Opening).
  final String nameTranslation;

  /// Total number of ayahs in this surah.
  final int ayahCount;

  /// Revelation type: 'Meccan' or 'Medinan'.
  final String revelationType;

  /// Order of revelation.
  final int revelationOrder;

  /// Page number in the standard Mushaf where this surah begins.
  final int startPage;

  /// Juz number where this surah begins.
  final int startJuz;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameTranslation,
    required this.ayahCount,
    required this.revelationType,
    required this.revelationOrder,
    required this.startPage,
    required this.startJuz,
  });

  bool get isMeccan => revelationType == 'Meccan';
  bool get isMedinan => revelationType == 'Medinan';

  @override
  List<Object?> get props => [number];

  @override
  String toString() => 'Surah($number: $nameEnglish)';
}
