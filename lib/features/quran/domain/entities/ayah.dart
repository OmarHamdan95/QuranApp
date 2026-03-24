import 'package:equatable/equatable.dart';

/// Domain entity representing a single Ayah (verse) of the Quran.
class Ayah extends Equatable {
  /// Unique ID across the entire Quran (1-6236).
  final int id;

  /// Surah number this ayah belongs to (1-114).
  final int surahNumber;

  /// Ayah number within the surah.
  final int ayahNumber;

  /// Full Arabic text in Uthmani script.
  final String textUthmani;

  /// Simplified Arabic text (without tajweed marks).
  final String textSimple;

  /// Page number in the standard Mushaf.
  final int page;

  /// Juz number (1-30).
  final int juz;

  /// Hizb quarter (1-240).
  final int hizbQuarter;

  /// Whether this ayah contains a sajdah (prostration).
  final bool sajdah;

  /// Type of sajdah if applicable: 'recommended' or 'obligatory'.
  final String? sajdahType;

  /// Ruku number.
  final int ruku;

  /// Manzil number (1-7).
  final int manzil;

  const Ayah({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.textUthmani,
    required this.textSimple,
    required this.page,
    required this.juz,
    required this.hizbQuarter,
    this.sajdah = false,
    this.sajdahType,
    required this.ruku,
    required this.manzil,
  });

  /// Returns the standard Quran reference (e.g., "2:255" for Ayat al-Kursi).
  String get reference => '$surahNumber:$ayahNumber';

  /// Whether this is the Bismillah ayah (first ayah of any surah except At-Tawbah).
  bool get isBismillah => ayahNumber == 1 && surahNumber != 9 && surahNumber != 1;

  @override
  List<Object?> get props => [id, surahNumber, ayahNumber];

  @override
  String toString() => 'Ayah($surahNumber:$ayahNumber)';
}
