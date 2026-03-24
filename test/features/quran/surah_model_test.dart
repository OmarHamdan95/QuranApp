import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/features/quran/data/models/surah_model.dart';

void main() {
  group('SurahModel', () {
    test('fromMap creates correct model from SQLite row', () {
      final map = {
        'number': 1,
        'name_arabic': 'الفاتحة',
        'name_english': 'Al-Fatihah',
        'name_translation': 'The Opening',
        'ayah_count': 7,
        'revelation_type': 'Meccan',
        'revelation_order': 5,
        'start_page': 1,
        'start_juz': 1,
      };

      final surah = SurahModel.fromMap(map);

      expect(surah.number, 1);
      expect(surah.nameArabic, 'الفاتحة');
      expect(surah.nameEnglish, 'Al-Fatihah');
      expect(surah.nameTranslation, 'The Opening');
      expect(surah.ayahCount, 7);
      expect(surah.revelationType, 'Meccan');
      expect(surah.isMeccan, true);
      expect(surah.isMedinan, false);
    });

    test('toMap produces a valid map for SQLite storage', () {
      const surah = SurahModel(
        number: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'Al-Baqarah',
        nameTranslation: 'The Cow',
        ayahCount: 286,
        revelationType: 'Medinan',
        revelationOrder: 87,
        startPage: 2,
        startJuz: 1,
      );

      final map = surah.toMap();

      expect(map['number'], 2);
      expect(map['name_arabic'], 'البقرة');
      expect(map['ayah_count'], 286);
      expect(map['revelation_type'], 'Medinan');
    });

    test('copyWith creates a modified copy', () {
      const original = SurahModel(
        number: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        nameTranslation: 'The Opening',
        ayahCount: 7,
        revelationType: 'Meccan',
        revelationOrder: 5,
        startPage: 1,
        startJuz: 1,
      );

      final modified = original.copyWith(ayahCount: 10);

      expect(modified.number, 1);
      expect(modified.ayahCount, 10);
      expect(modified.nameArabic, 'الفاتحة');
    });

    test('equatable compares by number', () {
      const surah1 = SurahModel(
        number: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        nameTranslation: 'The Opening',
        ayahCount: 7,
        revelationType: 'Meccan',
        revelationOrder: 5,
        startPage: 1,
        startJuz: 1,
      );

      const surah2 = SurahModel(
        number: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        nameTranslation: 'The Opening',
        ayahCount: 7,
        revelationType: 'Meccan',
        revelationOrder: 5,
        startPage: 1,
        startJuz: 1,
      );

      expect(surah1, equals(surah2));
    });
  });
}
