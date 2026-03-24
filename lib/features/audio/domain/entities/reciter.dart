import 'package:equatable/equatable.dart';

/// Domain entity representing a Quran reciter.
class Reciter extends Equatable {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String style; // e.g., 'Murattal', 'Mujawwad'
  final String? photoUrl;
  final String baseUrl; // base URL for audio files

  const Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.style,
    this.photoUrl,
    required this.baseUrl,
  });

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'Reciter($id: $nameEnglish)';
}
