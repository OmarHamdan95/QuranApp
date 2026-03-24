import 'package:equatable/equatable.dart';

/// Domain entity representing a bookmark or favorite ayah.
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
  });

  String get reference => '$surahNumber:$ayahNumber';

  @override
  List<Object?> get props => [id];
}

enum BookmarkColor {
  green,
  blue,
  red,
  yellow,
  purple,
}
