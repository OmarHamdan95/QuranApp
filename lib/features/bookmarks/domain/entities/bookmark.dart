import 'package:equatable/equatable.dart';

/// Domain entity representing a bookmarked or favourite ayah.
///
/// Supports coloured labels, user notes, and folder-based organisation.
class Bookmark extends Equatable {
  final String id;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final int page;
  final DateTime createdAt;
  final String? note;
  final bool isFavorite;
  final BookmarkColor color;

  /// User-defined folder name. Defaults to the general "All" bucket.
  final String folder;

  const Bookmark({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    required this.page,
    required this.createdAt,
    this.note,
    this.isFavorite = false,
    this.color = BookmarkColor.green,
    this.folder = 'عام',
  });

  /// Returns the standard Quran reference, e.g. "2:255".
  String get reference => '$surahNumber:$ayahNumber';

  /// Creates a copy of this bookmark with optional field overrides.
  Bookmark copyWith({
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
    String? folder,
  }) {
    return Bookmark(
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
      folder: folder ?? this.folder,
    );
  }

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'Bookmark($surahNumber:$ayahNumber, folder: $folder)';
}

/// Colour labels that users can assign to their bookmarks.
enum BookmarkColor {
  green,
  blue,
  red,
  yellow,
  purple,
}

/// Extension helpers for [BookmarkColor].
extension BookmarkColorX on BookmarkColor {
  /// Arabic display name for this colour.
  String get arabicLabel {
    switch (this) {
      case BookmarkColor.green:
        return 'أخضر';
      case BookmarkColor.blue:
        return 'أزرق';
      case BookmarkColor.red:
        return 'أحمر';
      case BookmarkColor.yellow:
        return 'أصفر';
      case BookmarkColor.purple:
        return 'بنفسجي';
    }
  }
}
