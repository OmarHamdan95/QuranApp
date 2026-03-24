import '../../domain/entities/surah.dart';

/// Data model for [Surah] that handles serialization from SQLite / JSON.
class SurahModel extends Surah {
  const SurahModel({
    required super.number,
    required super.nameArabic,
    required super.nameEnglish,
    required super.nameTranslation,
    required super.ayahCount,
    required super.revelationType,
    required super.revelationOrder,
    required super.startPage,
    required super.startJuz,
  });

  /// Creates a [SurahModel] from a SQLite row map.
  factory SurahModel.fromMap(Map<String, dynamic> map) {
    return SurahModel(
      number: map['number'] as int,
      nameArabic: map['name_arabic'] as String,
      nameEnglish: map['name_english'] as String,
      nameTranslation: map['name_translation'] as String? ?? '',
      ayahCount: map['ayah_count'] as int,
      revelationType: map['revelation_type'] as String,
      revelationOrder: map['revelation_order'] as int,
      startPage: map['start_page'] as int? ?? 1,
      startJuz: map['start_juz'] as int? ?? 1,
    );
  }

  /// Creates a [SurahModel] from a JSON map (API response).
  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['id'] as int? ?? json['number'] as int,
      nameArabic: json['name_arabic'] as String? ?? '',
      nameEnglish: json['name_simple'] as String? ?? json['name_english'] as String? ?? '',
      nameTranslation: json['translated_name']?['name'] as String? ?? json['name_translation'] as String? ?? '',
      ayahCount: json['verses_count'] as int? ?? json['ayah_count'] as int? ?? 0,
      revelationType: json['revelation_place'] as String? ?? json['revelation_type'] as String? ?? '',
      revelationOrder: json['revelation_order'] as int? ?? 0,
      startPage: json['pages']?.first as int? ?? json['start_page'] as int? ?? 1,
      startJuz: json['start_juz'] as int? ?? 1,
    );
  }

  /// Converts to a map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'name_arabic': nameArabic,
      'name_english': nameEnglish,
      'name_translation': nameTranslation,
      'ayah_count': ayahCount,
      'revelation_type': revelationType,
      'revelation_order': revelationOrder,
      'start_page': startPage,
      'start_juz': startJuz,
    };
  }

  /// Converts to a JSON-compatible map.
  Map<String, dynamic> toJson() => toMap();

  /// Creates a copy with optional overrides.
  SurahModel copyWith({
    int? number,
    String? nameArabic,
    String? nameEnglish,
    String? nameTranslation,
    int? ayahCount,
    String? revelationType,
    int? revelationOrder,
    int? startPage,
    int? startJuz,
  }) {
    return SurahModel(
      number: number ?? this.number,
      nameArabic: nameArabic ?? this.nameArabic,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      nameTranslation: nameTranslation ?? this.nameTranslation,
      ayahCount: ayahCount ?? this.ayahCount,
      revelationType: revelationType ?? this.revelationType,
      revelationOrder: revelationOrder ?? this.revelationOrder,
      startPage: startPage ?? this.startPage,
      startJuz: startJuz ?? this.startJuz,
    );
  }
}
