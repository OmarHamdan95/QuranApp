import '../../domain/entities/ayah.dart';

/// Data model for [Ayah] that handles serialization from SQLite / JSON.
class AyahModel extends Ayah {
  const AyahModel({
    required super.id,
    required super.surahNumber,
    required super.ayahNumber,
    required super.textUthmani,
    required super.textSimple,
    required super.page,
    required super.juz,
    required super.hizbQuarter,
    super.sajdah = false,
    super.sajdahType,
    required super.ruku,
    required super.manzil,
  });

  /// Creates an [AyahModel] from a SQLite row map.
  factory AyahModel.fromMap(Map<String, dynamic> map) {
    return AyahModel(
      id: map['id'] as int,
      surahNumber: map['surah_number'] as int,
      ayahNumber: map['ayah_number'] as int,
      textUthmani: map['text_uthmani'] as String,
      textSimple: map['text_simple'] as String? ?? '',
      page: map['page'] as int,
      juz: map['juz'] as int,
      hizbQuarter: map['hizb_quarter'] as int? ?? 0,
      sajdah: (map['sajdah'] as int? ?? 0) == 1,
      sajdahType: map['sajdah_type'] as String?,
      ruku: map['ruku'] as int? ?? 0,
      manzil: map['manzil'] as int? ?? 0,
    );
  }

  /// Creates an [AyahModel] from a JSON map (API response).
  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      id: json['id'] as int? ?? json['verse_key_id'] as int? ?? 0,
      surahNumber: json['surah_number'] as int? ??
          (json['verse_key'] != null
              ? int.parse((json['verse_key'] as String).split(':')[0])
              : 0),
      ayahNumber: json['ayah_number'] as int? ??
          json['verse_number'] as int? ??
          (json['verse_key'] != null
              ? int.parse((json['verse_key'] as String).split(':')[1])
              : 0),
      textUthmani: json['text_uthmani'] as String? ?? '',
      textSimple: json['text_imlaei'] as String? ?? json['text_simple'] as String? ?? '',
      page: json['page_number'] as int? ?? json['page'] as int? ?? 0,
      juz: json['juz_number'] as int? ?? json['juz'] as int? ?? 0,
      hizbQuarter: json['hizb_number'] as int? ?? json['hizb_quarter'] as int? ?? 0,
      sajdah: json['sajdah'] == true || json['sajdah_number'] != null,
      sajdahType: json['sajdah_type'] as String?,
      ruku: json['rub_el_hizb_number'] as int? ?? json['ruku'] as int? ?? 0,
      manzil: json['manzil'] as int? ?? 0,
    );
  }

  /// Converts to a map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'text_uthmani': textUthmani,
      'text_simple': textSimple,
      'page': page,
      'juz': juz,
      'hizb_quarter': hizbQuarter,
      'sajdah': sajdah ? 1 : 0,
      'sajdah_type': sajdahType,
      'ruku': ruku,
      'manzil': manzil,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  AyahModel copyWith({
    int? id,
    int? surahNumber,
    int? ayahNumber,
    String? textUthmani,
    String? textSimple,
    int? page,
    int? juz,
    int? hizbQuarter,
    bool? sajdah,
    String? sajdahType,
    int? ruku,
    int? manzil,
  }) {
    return AyahModel(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      textUthmani: textUthmani ?? this.textUthmani,
      textSimple: textSimple ?? this.textSimple,
      page: page ?? this.page,
      juz: juz ?? this.juz,
      hizbQuarter: hizbQuarter ?? this.hizbQuarter,
      sajdah: sajdah ?? this.sajdah,
      sajdahType: sajdahType ?? this.sajdahType,
      ruku: ruku ?? this.ruku,
      manzil: manzil ?? this.manzil,
    );
  }
}
