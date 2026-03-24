import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/features/audio/data/models/reciter_model.dart';

void main() {
  group('ReciterModel', () {
    test('fromMap creates correct model', () {
      final map = {
        'id': 7,
        'name_arabic': 'مشاري راشد العفاسي',
        'name_english': 'Mishary Rashid Alafasy',
        'style': 'Murattal',
        'photo_url': null,
        'base_url': 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee',
      };

      final reciter = ReciterModel.fromMap(map);

      expect(reciter.id, 7);
      expect(reciter.nameArabic, 'مشاري راشد العفاسي');
      expect(reciter.nameEnglish, 'Mishary Rashid Alafasy');
      expect(reciter.style, 'Murattal');
      expect(reciter.baseUrl, contains('quranicaudio.com'));
    });

    test('popularReciters contains expected entries', () {
      expect(ReciterModel.popularReciters.length, greaterThanOrEqualTo(5));
      expect(
        ReciterModel.popularReciters.any((r) => r.nameEnglish.contains('Alafasy')),
        true,
      );
    });

    test('toMap is inverse of fromMap', () {
      const original = ReciterModel(
        id: 10,
        nameArabic: 'قارئ',
        nameEnglish: 'Reciter',
        style: 'Mujawwad',
        baseUrl: 'https://example.com',
      );

      final map = original.toMap();
      final restored = ReciterModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.nameArabic, original.nameArabic);
      expect(restored.style, original.style);
    });
  });
}
