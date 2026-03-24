import 'package:equatable/equatable.dart';

/// Domain entity representing a tafsir (Quranic exegesis) entry
/// for a specific ayah from a named source.
class Tafsir extends Equatable {
  /// The tafsir source.
  final TafsirSource source;

  /// Surah number of the explained ayah.
  final int surahNumber;

  /// Ayah number within the surah.
  final int ayahNumber;

  /// The full tafsir text in Arabic.
  final String text;

  /// Optional short summary of the tafsir.
  final String? summary;

  const Tafsir({
    required this.source,
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    this.summary,
  });

  /// Standard Quran reference (e.g. "2:255").
  String get reference => '$surahNumber:$ayahNumber';

  @override
  List<Object?> get props => [source, surahNumber, ayahNumber];

  @override
  String toString() =>
      'Tafsir(${source.name}, $surahNumber:$ayahNumber)';
}

/// Enumeration of supported tafsir sources.
enum TafsirSource {
  ibnKathir,
  alSaadi,
  alTabari,
  alQurtubi,
  muyassar,
}

/// Extension helpers for [TafsirSource].
extension TafsirSourceX on TafsirSource {
  /// Human-readable Arabic name.
  String get arabicName {
    switch (this) {
      case TafsirSource.ibnKathir:
        return 'تفسير ابن كثير';
      case TafsirSource.alSaadi:
        return 'تفسير السعدي';
      case TafsirSource.alTabari:
        return 'تفسير الطبري';
      case TafsirSource.alQurtubi:
        return 'تفسير القرطبي';
      case TafsirSource.muyassar:
        return 'التفسير الميسر';
    }
  }

  /// Short label used in tab selectors.
  String get shortLabel {
    switch (this) {
      case TafsirSource.ibnKathir:
        return 'ابن كثير';
      case TafsirSource.alSaadi:
        return 'السعدي';
      case TafsirSource.alTabari:
        return 'الطبري';
      case TafsirSource.alQurtubi:
        return 'القرطبي';
      case TafsirSource.muyassar:
        return 'الميسر';
    }
  }

  /// Scholar / author description shown in the source selector.
  String get authorDescription {
    switch (this) {
      case TafsirSource.ibnKathir:
        return 'الحافظ إسماعيل بن عمر بن كثير (ت 774هـ)';
      case TafsirSource.alSaadi:
        return 'الشيخ عبد الرحمن بن ناصر السعدي (ت 1376هـ)';
      case TafsirSource.alTabari:
        return 'الإمام محمد بن جرير الطبري (ت 310هـ)';
      case TafsirSource.alQurtubi:
        return 'الإمام محمد بن أحمد القرطبي (ت 671هـ)';
      case TafsirSource.muyassar:
        return 'مجمع الملك فهد لطباعة المصحف الشريف';
    }
  }

  /// API identifier string used when fetching from the tafsir API.
  String get apiKey {
    switch (this) {
      case TafsirSource.ibnKathir:
        return 'ibn-kathir';
      case TafsirSource.alSaadi:
        return 'al-saadi';
      case TafsirSource.alTabari:
        return 'al-tabari';
      case TafsirSource.alQurtubi:
        return 'al-qurtubi';
      case TafsirSource.muyassar:
        return 'muyassar';
    }
  }
}
