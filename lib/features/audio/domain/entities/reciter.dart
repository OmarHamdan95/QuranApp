import 'package:equatable/equatable.dart';

/// Domain entity representing a Quran reciter.
class Reciter extends Equatable {
  final int id;
  final String nameArabic;
  final String nameEnglish;

  /// Recitation style: 'Murattal' or 'Mujawwad'.
  final String style;

  /// Optional URL to a reciter photo.
  final String? photoUrl;

  /// Base URL for full-surah MP3 files.
  /// File pattern: [baseUrl]/[3-digit-surah].mp3
  final String baseUrl;

  /// Identifier used by EveryAyah.com for per-ayah audio URLs.
  /// Ayah pattern: https://everyayah.com/data/[everyAyahId]/[surah][ayah].mp3
  final String? everyAyahId;

  /// Short biography in Arabic.
  final String? bio;

  /// Country of origin (Arabic name).
  final String? country;

  const Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.style,
    this.photoUrl,
    required this.baseUrl,
    this.everyAyahId,
    this.bio,
    this.country,
  });

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'Reciter($id: $nameEnglish [$style])';
}
