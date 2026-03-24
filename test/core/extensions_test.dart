import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/extensions/context_extensions.dart';

void main() {
  group('ArabicStringExtensions', () {
    test('containsArabic returns true for Arabic text', () {
      expect('بسم الله'.containsArabic, true);
    });

    test('containsArabic returns false for Latin text', () {
      expect('Hello World'.containsArabic, false);
    });

    test('containsArabic returns true for mixed text', () {
      expect('Surah الفاتحة'.containsArabic, true);
    });

    test('toArabicNumerals converts Western to Eastern Arabic', () {
      expect('123'.toArabicNumerals, '١٢٣');
      expect('0'.toArabicNumerals, '٠');
      expect('6236'.toArabicNumerals, '٦٢٣٦');
    });

    test('toArabicNumerals preserves non-digit characters', () {
      expect('Page 5'.toArabicNumerals, 'Page ٥');
      expect('2:255'.toArabicNumerals, '٢:٢٥٥');
    });
  });

  group('IntExtensions', () {
    test('toArabicNumeral converts integer to Eastern Arabic string', () {
      expect(1.toArabicNumeral, '١');
      expect(114.toArabicNumeral, '١١٤');
    });

    test('toTimerString formats seconds as mm:ss', () {
      expect(0.toTimerString, '00:00');
      expect(61.toTimerString, '01:01');
      expect(3600.toTimerString, '60:00');
    });
  });

  group('DurationExtensions', () {
    test('formatted returns mm:ss', () {
      expect(const Duration(minutes: 3, seconds: 45).formatted, '03:45');
      expect(Duration.zero.formatted, '00:00');
    });

    test('formattedLong returns hh:mm:ss', () {
      expect(
        const Duration(hours: 1, minutes: 15, seconds: 30).formattedLong,
        '01:15:30',
      );
    });
  });
}
