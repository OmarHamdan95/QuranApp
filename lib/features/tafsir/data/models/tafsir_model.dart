import 'dart:convert';

import '../../domain/entities/tafsir.dart';

/// Data model for [Tafsir] with JSON serialisation.
///
/// Used for both API deserialization and local cache storage.
class TafsirModel extends Tafsir {
  const TafsirModel({
    required super.source,
    required super.surahNumber,
    required super.ayahNumber,
    required super.text,
    super.summary,
  });

  /// Deserialises from a JSON map.
  factory TafsirModel.fromMap(Map<String, dynamic> map) {
    return TafsirModel(
      source: TafsirSource.values.firstWhere(
        (s) => s.apiKey == (map['source'] as String? ?? ''),
        orElse: () => TafsirSource.muyassar,
      ),
      surahNumber: map['surah_number'] as int,
      ayahNumber: map['ayah_number'] as int,
      text: map['text'] as String,
      summary: map['summary'] as String?,
    );
  }

  /// Deserialises from a JSON string.
  factory TafsirModel.fromJson(String json) =>
      TafsirModel.fromMap(jsonDecode(json) as Map<String, dynamic>);

  /// Deserialises from the al-quran.cloud / quranenc.com style API response.
  factory TafsirModel.fromApiResponse(
    Map<String, dynamic> data, {
    required TafsirSource source,
    required int surahNumber,
    required int ayahNumber,
  }) {
    return TafsirModel(
      source: source,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      text: (data['text'] as String?) ??
          (data['tafsir'] as String?) ??
          (data['content'] as String?) ??
          '',
    );
  }

  /// Serialises to a JSON map.
  Map<String, dynamic> toMap() {
    return {
      'source': source.apiKey,
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'text': text,
      'summary': summary,
    };
  }

  /// Serialises to a JSON string.
  String toJson() => jsonEncode(toMap());

  /// Cache key used in SharedPreferences.
  String get cacheKey => 'tafsir_${source.apiKey}_${surahNumber}_$ayahNumber';
}
