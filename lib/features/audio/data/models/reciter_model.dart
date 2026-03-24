import '../../domain/entities/reciter.dart';

/// Data model for [Reciter] with serialization support.
class ReciterModel extends Reciter {
  const ReciterModel({
    required super.id,
    required super.nameArabic,
    required super.nameEnglish,
    required super.style,
    super.photoUrl,
    required super.baseUrl,
  });

  factory ReciterModel.fromMap(Map<String, dynamic> map) {
    return ReciterModel(
      id: map['id'] as int,
      nameArabic: map['name_arabic'] as String,
      nameEnglish: map['name_english'] as String,
      style: map['style'] as String? ?? 'Murattal',
      photoUrl: map['photo_url'] as String?,
      baseUrl: map['base_url'] as String,
    );
  }

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    return ReciterModel(
      id: json['id'] as int,
      nameArabic: json['name_arabic'] as String? ?? json['translated_name']?['name'] as String? ?? '',
      nameEnglish: json['reciter_name'] as String? ?? json['name_english'] as String? ?? '',
      style: json['style']?['style'] as String? ?? json['style'] as String? ?? 'Murattal',
      photoUrl: json['photo_url'] as String?,
      baseUrl: json['base_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_arabic': nameArabic,
      'name_english': nameEnglish,
      'style': style,
      'photo_url': photoUrl,
      'base_url': baseUrl,
    };
  }

  /// Pre-built list of popular reciters.
  static const List<ReciterModel> popularReciters = [
    ReciterModel(
      id: 7,
      nameArabic: 'مشاري راشد العفاسي',
      nameEnglish: 'Mishary Rashid Alafasy',
      style: 'Murattal',
      baseUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee',
    ),
    ReciterModel(
      id: 1,
      nameArabic: 'عبد الباسط عبد الصمد',
      nameEnglish: 'Abdul Basit Abdul Samad',
      style: 'Murattal',
      baseUrl: 'https://download.quranicaudio.com/quran/abdul_basit_murattal',
    ),
    ReciterModel(
      id: 5,
      nameArabic: 'ماهر المعيقلي',
      nameEnglish: 'Maher Al Muaiqly',
      style: 'Murattal',
      baseUrl: 'https://download.quranicaudio.com/quran/maher_al_muaiqly',
    ),
    ReciterModel(
      id: 3,
      nameArabic: 'سعود الشريم',
      nameEnglish: 'Saud Al-Shuraim',
      style: 'Murattal',
      baseUrl: 'https://download.quranicaudio.com/quran/sa3ood_al-shuraym',
    ),
    ReciterModel(
      id: 4,
      nameArabic: 'عبد الرحمن السديس',
      nameEnglish: 'Abdurrahman As-Sudais',
      style: 'Murattal',
      baseUrl: 'https://download.quranicaudio.com/quran/abdurrahmaan_as-sudays',
    ),
    ReciterModel(
      id: 6,
      nameArabic: 'محمد صديق المنشاوي',
      nameEnglish: 'Mohamed Siddiq El-Minshawi',
      style: 'Murattal',
      baseUrl: 'https://download.quranicaudio.com/quran/muhammad_siddeeq_al-minshaawee',
    ),
  ];
}
