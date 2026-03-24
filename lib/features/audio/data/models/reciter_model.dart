import '../../domain/entities/reciter.dart';

/// Data model for [Reciter] with JSON/Map serialization support.
///
/// Also holds the canonical list of popular reciters sourced from
/// QuranicAudio.com (EveryAyah.com compatible URL patterns).
class ReciterModel extends Reciter {
  const ReciterModel({
    required super.id,
    required super.nameArabic,
    required super.nameEnglish,
    required super.style,
    super.photoUrl,
    required super.baseUrl,
    super.everyAyahId,
    super.bio,
    super.country,
  });

  factory ReciterModel.fromMap(Map<String, dynamic> map) {
    return ReciterModel(
      id: map['id'] as int,
      nameArabic: map['name_arabic'] as String,
      nameEnglish: map['name_english'] as String,
      style: map['style'] as String? ?? 'Murattal',
      photoUrl: map['photo_url'] as String?,
      baseUrl: map['base_url'] as String,
      everyAyahId: map['every_ayah_id'] as String?,
      bio: map['bio'] as String?,
      country: map['country'] as String?,
    );
  }

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    return ReciterModel(
      id: json['id'] as int,
      nameArabic:
          json['name_arabic'] as String? ??
          json['translated_name']?['name'] as String? ??
          '',
      nameEnglish:
          json['reciter_name'] as String? ??
          json['name_english'] as String? ??
          '',
      style:
          json['style']?['style'] as String? ??
          json['style'] as String? ??
          'Murattal',
      photoUrl: json['photo_url'] as String?,
      baseUrl: json['base_url'] as String? ?? '',
      everyAyahId: json['every_ayah_id'] as String?,
      bio: json['bio'] as String?,
      country: json['country'] as String?,
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
      'every_ayah_id': everyAyahId,
      'bio': bio,
      'country': country,
    };
  }

  /// Full catalogue of popular Quran reciters with EveryAyah.com
  /// and QuranicAudio.com compatible URLs.
  ///
  /// Surah audio: [baseUrl]/[3-digit-surah].mp3
  /// Ayah  audio: [everyAyahBaseUrl]/[3-digit-surah][3-digit-ayah].mp3
  static const List<ReciterModel> popularReciters = [
    ReciterModel(
      id: 7,
      nameArabic: 'مشاري راشد العفاسي',
      nameEnglish: 'Mishary Rashid Alafasy',
      style: 'Murattal',
      country: 'الكويت',
      bio:
          'قارئ كويتي مشهور بصوته الجميل وأسلوبه المميز في تلاوة القرآن الكريم.',
      baseUrl:
          'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee',
      everyAyahId: 'Alafasy_64kbps',
    ),
    ReciterModel(
      id: 1,
      nameArabic: 'عبد الباسط عبد الصمد',
      nameEnglish: 'Abdul Basit Abdul Samad',
      style: 'Murattal',
      country: 'مصر',
      bio: 'أحد أشهر قراء القرآن في القرن العشرين من مصر.',
      baseUrl:
          'https://download.quranicaudio.com/quran/abdul_basit_murattal',
      everyAyahId: 'Abdul_Basit_Murattal_192kbps',
    ),
    ReciterModel(
      id: 2,
      nameArabic: 'عبد الباسط عبد الصمد (مجوّد)',
      nameEnglish: 'Abdul Basit Abdul Samad (Mujawwad)',
      style: 'Mujawwad',
      country: 'مصر',
      bio: 'تلاوة مجوّدة بأعلى مستويات التجويد والخشوع.',
      baseUrl:
          'https://download.quranicaudio.com/quran/abdulbaset_mujawwad',
      everyAyahId: 'Abdul_Basit_Mujawwad_128kbps',
    ),
    ReciterModel(
      id: 5,
      nameArabic: 'ماهر المعيقلي',
      nameEnglish: 'Maher Al Muaiqly',
      style: 'Murattal',
      country: 'المملكة العربية السعودية',
      bio: 'إمام المسجد الحرام بمكة المكرمة.',
      baseUrl:
          'https://download.quranicaudio.com/quran/maher_al_muaiqly',
      everyAyahId: 'MaherAlMuaiqly128kbps',
    ),
    ReciterModel(
      id: 3,
      nameArabic: 'سعود الشريم',
      nameEnglish: 'Saud Al-Shuraim',
      style: 'Murattal',
      country: 'المملكة العربية السعودية',
      bio: 'إمام المسجد الحرام بمكة المكرمة.',
      baseUrl:
          'https://download.quranicaudio.com/quran/sa3ood_al-shuraym',
      everyAyahId: 'Shuraym_64kbps',
    ),
    ReciterModel(
      id: 4,
      nameArabic: 'عبد الرحمن السديس',
      nameEnglish: 'Abdurrahman As-Sudais',
      style: 'Murattal',
      country: 'المملكة العربية السعودية',
      bio: 'الرئيس العام لشؤون المسجد الحرام والمسجد النبوي.',
      baseUrl:
          'https://download.quranicaudio.com/quran/abdurrahmaan_as-sudays',
      everyAyahId: 'Sudais_64kbps',
    ),
    ReciterModel(
      id: 6,
      nameArabic: 'محمد صديق المنشاوي',
      nameEnglish: 'Mohamed Siddiq El-Minshawi',
      style: 'Murattal',
      country: 'مصر',
      bio: 'من أبرز قراء القرآن في مصر والعالم العربي.',
      baseUrl:
          'https://download.quranicaudio.com/quran/muhammad_siddeeq_al-minshaawee',
      everyAyahId: 'Minshawy_Murattal_128kbps',
    ),
    ReciterModel(
      id: 8,
      nameArabic: 'محمود خليل الحصري',
      nameEnglish: 'Mahmoud Khalil Al-Husary',
      style: 'Murattal',
      country: 'مصر',
      bio: 'رائد علم التجويد ومن أبرز قراء القرآن في القرن العشرين.',
      baseUrl:
          'https://download.quranicaudio.com/quran/mahmoud_khaleel_al-husaree',
      everyAyahId: 'Husary_128kbps',
    ),
    ReciterModel(
      id: 9,
      nameArabic: 'محمود خليل الحصري (مجوّد)',
      nameEnglish: 'Mahmoud Khalil Al-Husary (Mujawwad)',
      style: 'Mujawwad',
      country: 'مصر',
      bio: 'تلاوة مجوّدة بأعلى درجات الإتقان.',
      baseUrl:
          'https://download.quranicaudio.com/quran/mahmoud_khaleel_al-husaree_mujawwad',
      everyAyahId: 'Husary_Mujawwad_128kbps',
    ),
    ReciterModel(
      id: 10,
      nameArabic: 'علي عبد الله جابر',
      nameEnglish: 'Ali Abdallah Jaber',
      style: 'Murattal',
      country: 'المملكة العربية السعودية',
      bio: 'قارئ سعودي بارز وإمام مسجد.',
      baseUrl:
          'https://download.quranicaudio.com/quran/ali_jaber',
      everyAyahId: 'AliJaber_64kbps',
    ),
    ReciterModel(
      id: 11,
      nameArabic: 'ناصر القطامي',
      nameEnglish: 'Nasser Al Qatami',
      style: 'Murattal',
      country: 'المملكة العربية السعودية',
      bio: 'قارئ سعودي مشهور بصوته الخاشع.',
      baseUrl:
          'https://download.quranicaudio.com/quran/nasser_alqatami',
      everyAyahId: 'Nasser_Alqatami_128kbps',
    ),
    ReciterModel(
      id: 12,
      nameArabic: 'أحمد العجمي',
      nameEnglish: 'Ahmed Al-Ajmi',
      style: 'Murattal',
      country: 'المملكة العربية السعودية',
      bio: 'قارئ كويتي مشهور بتلاوته الخاشعة.',
      baseUrl:
          'https://download.quranicaudio.com/quran/ahmed_ibn_ali_al-ajamy',
      everyAyahId: 'Ahmed_ibn_Ali_al-Ajamy_128kbps',
    ),
  ];
}
