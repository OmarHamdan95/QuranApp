import '../../domain/entities/bookmark.dart';

/// Data model for [Bookmark] with Isar serialization support.
class BookmarkModel extends Bookmark {
  const BookmarkModel({
    required super.id,
    required super.surahNumber,
    required super.ayahNumber,
    required super.surahName,
    required super.ayahText,
    required super.page,
    required super.createdAt,
    super.note,
    super.isFavorite = false,
    super.color = BookmarkColor.green,
  });

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as String,
      surahNumber: map['surah_number'] as int,
      ayahNumber: map['ayah_number'] as int,
      surahName: map['surah_name'] as String,
      ayahText: map['ayah_text'] as String,
      page: map['page'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      note: map['note'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      color: BookmarkColor.values[map['color'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'surah_name': surahName,
      'ayah_text': ayahText,
      'page': page,
      'created_at': createdAt.millisecondsSinceEpoch,
      'note': note,
      'is_favorite': isFavorite ? 1 : 0,
      'color': color.index,
    };
  }

  BookmarkModel copyWith({
    String? id,
    int? surahNumber,
    int? ayahNumber,
    String? surahName,
    String? ayahText,
    int? page,
    DateTime? createdAt,
    String? note,
    bool? isFavorite,
    BookmarkColor? color,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      surahName: surahName ?? this.surahName,
      ayahText: ayahText ?? this.ayahText,
      page: page ?? this.page,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
      color: color ?? this.color,
    );
  }
}
