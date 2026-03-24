import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/features/quran/data/models/ayah_model.dart';

void main() {
  group('AyahModel', () {
    test('fromMap creates correct model from SQLite row', () {
      final map = {
        'id': 1,
        'surah_number': 1,
        'ayah_number': 1,
        'text_uthmani': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        'text_simple': 'بسم الله الرحمن الرحيم',
        'page': 1,
        'juz': 1,
        'hizb_quarter': 1,
        'sajdah': 0,
        'sajdah_type': null,
        'ruku': 1,
        'manzil': 1,
      };

      final ayah = AyahModel.fromMap(map);

      expect(ayah.id, 1);
      expect(ayah.surahNumber, 1);
      expect(ayah.ayahNumber, 1);
      expect(ayah.textUthmani, contains('بِسْمِ'));
      expect(ayah.page, 1);
      expect(ayah.juz, 1);
      expect(ayah.sajdah, false);
    });

    test('reference returns correct format', () {
      const ayah = AyahModel(
        id: 262,
        surahNumber: 2,
        ayahNumber: 255,
        textUthmani: 'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ',
        textSimple: 'الله لا إله إلا هو',
        page: 42,
        juz: 3,
        hizbQuarter: 17,
        ruku: 35,
        manzil: 1,
      );

      expect(ayah.reference, '2:255');
    });

    test('isBismillah correctly identifies first ayahs', () {
      const bismillahAyah = AyahModel(
        id: 8,
        surahNumber: 2,
        ayahNumber: 1,
        textUthmani: 'test',
        textSimple: 'test',
        page: 2,
        juz: 1,
        hizbQuarter: 1,
        ruku: 1,
        manzil: 1,
      );

      // Surah 2 ayah 1 should be bismillah
      expect(bismillahAyah.isBismillah, true);

      // Surah 9 has no bismillah
      const tawbahAyah = AyahModel(
        id: 1200,
        surahNumber: 9,
        ayahNumber: 1,
        textUthmani: 'test',
        textSimple: 'test',
        page: 187,
        juz: 10,
        hizbQuarter: 1,
        ruku: 1,
        manzil: 1,
      );

      expect(tawbahAyah.isBismillah, false);
    });

    test('toMap and fromMap are inverse operations', () {
      const original = AyahModel(
        id: 100,
        surahNumber: 3,
        ayahNumber: 5,
        textUthmani: 'test uthmani',
        textSimple: 'test simple',
        page: 50,
        juz: 3,
        hizbQuarter: 10,
        sajdah: true,
        sajdahType: 'recommended',
        ruku: 15,
        manzil: 2,
      );

      final map = original.toMap();
      final restored = AyahModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.surahNumber, original.surahNumber);
      expect(restored.ayahNumber, original.ayahNumber);
      expect(restored.textUthmani, original.textUthmani);
      expect(restored.sajdah, original.sajdah);
      expect(restored.sajdahType, original.sajdahType);
    });
  });
}
