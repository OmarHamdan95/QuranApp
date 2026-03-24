import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/features/bookmarks/data/models/bookmark_model.dart';
import 'package:quran_app/features/bookmarks/domain/entities/bookmark.dart';

void main() {
  group('BookmarkModel', () {
    final now = DateTime(2024, 1, 15, 10, 30);

    test('fromMap creates correct model', () {
      final map = {
        'id': 'bk_1',
        'surah_number': 2,
        'ayah_number': 255,
        'surah_name': 'البقرة',
        'ayah_text': 'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
        'page': 42,
        'created_at': now.millisecondsSinceEpoch,
        'note': 'آية الكرسي',
        'is_favorite': 1,
        'color': 0,
      };

      final bookmark = BookmarkModel.fromMap(map);

      expect(bookmark.id, 'bk_1');
      expect(bookmark.surahNumber, 2);
      expect(bookmark.ayahNumber, 255);
      expect(bookmark.surahName, 'البقرة');
      expect(bookmark.isFavorite, true);
      expect(bookmark.color, BookmarkColor.green);
      expect(bookmark.reference, '2:255');
    });

    test('toMap produces correct map', () {
      final bookmark = BookmarkModel(
        id: 'bk_2',
        surahNumber: 36,
        ayahNumber: 1,
        surahName: 'يس',
        ayahText: 'يسٓ',
        page: 440,
        createdAt: now,
        isFavorite: false,
        color: BookmarkColor.blue,
      );

      final map = bookmark.toMap();

      expect(map['id'], 'bk_2');
      expect(map['surah_number'], 36);
      expect(map['is_favorite'], 0);
      expect(map['color'], BookmarkColor.blue.index);
    });

    test('copyWith creates modified copy', () {
      final original = BookmarkModel(
        id: 'bk_3',
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'الفاتحة',
        ayahText: 'test',
        page: 1,
        createdAt: now,
      );

      final modified = original.copyWith(isFavorite: true, note: 'My note');

      expect(modified.id, 'bk_3');
      expect(modified.isFavorite, true);
      expect(modified.note, 'My note');
      expect(modified.surahName, 'الفاتحة');
    });
  });
}
