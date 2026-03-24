/// App-wide constants for the Quran App.
abstract final class AppConstants {
  // ── App Metadata ──
  static const String appName = 'Quran App';
  static const String appNameArabic = 'تطبيق القرآن';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ── Quran Data ──
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;
  static const int totalJuz = 30;
  static const int totalHizb = 60;
  static const int totalPages = 604;
  static const int totalRuku = 556;

  // ── Database ──
  static const String quranDbName = 'quran.db';
  static const String userDbName = 'user_data';
  static const String quranDbAssetPath = 'assets/data/quran.db';

  // ── API Base URLs ──
  static const String quranApiBase = 'https://api.quran.com/api/v4';
  static const String audioApiBase = 'https://audio.qurancdn.com';
  static const String recitationBaseUrl = 'https://download.quranicaudio.com/quran';

  // ── Audio ──
  static const int defaultReciterId = 7; // Mishary Rashid Alafasy
  static const double defaultPlaybackSpeed = 1.0;
  static const List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  // ── Reading ──
  static const double minFontSize = 18.0;
  static const double maxFontSize = 48.0;
  static const double defaultQuranFontSize = 28.0;
  static const double defaultTranslationFontSize = 15.0;

  // ── Prayer ──
  static const String defaultCalculationMethod = 'MuslimWorldLeague';
  static const String defaultMadhab = 'Shafi';

  // ── Hifz ──
  static const int defaultDailyAyahGoal = 5;
  static const int maxDailyAyahGoal = 30;
  static const int minDailyAyahGoal = 1;
  static const int selfTestDefaultAyahCount = 5;

  // ── Mosabqat (Quizzes) ──
  static const int quizTimePerQuestionSeconds = 30;
  static const int dailyChallengeQuestionCount = 10;
  static const int minQuizQuestions = 5;
  static const int maxQuizQuestions = 50;
  static const int defaultQuizQuestions = 10;

  // ── Animation Durations ──
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animPageTransition = Duration(milliseconds: 300);

  // ── Shared Preferences Keys ──
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefQuranFontSize = 'quran_font_size';
  static const String prefTranslationFontSize = 'translation_font_size';
  static const String prefShowTranslation = 'show_translation';
  static const String prefDefaultTranslation = 'default_translation';
  static const String prefDefaultReciter = 'default_reciter';
  static const String prefLastReadSurah = 'last_read_surah';
  static const String prefLastReadAyah = 'last_read_ayah';
  static const String prefLastReadPage = 'last_read_page';
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefCalculationMethod = 'calculation_method';
  static const String prefMadhab = 'madhab';
  static const String prefLatitude = 'latitude';
  static const String prefLongitude = 'longitude';
  static const String prefLocationName = 'location_name';
  static const String prefDailyAyahGoal = 'daily_ayah_goal';
  static const String prefNotificationsEnabled = 'notifications_enabled';

  // ── Surah Types ──
  static const String surahTypeMakki = 'Meccan';
  static const String surahTypeMadani = 'Medinan';

  // ── Bismillah ──
  static const String bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

  // ── Bottom Nav Indices ──
  static const int navHome = 0;
  static const int navQuran = 1;
  static const int navPrayer = 2;
  static const int navHifz = 3;
  static const int navMore = 4;
}

/// Enum for Quran reading modes.
enum QuranReadingMode {
  mushaf,   // page-by-page like physical Quran
  surah,    // continuous surah scroll
  juz,      // juz-based reading
}

/// Enum for quiz difficulty levels.
enum QuizDifficulty {
  easy,
  medium,
  hard,
  expert,
}

/// Enum for quiz categories.
enum QuizCategory {
  ayahCompletion,     // Complete the ayah
  surahIdentification, // Which surah is this from?
  ayahOrder,          // Which comes first?
  wordMeaning,        // What does this word mean?
  generalKnowledge,   // General Quran knowledge
}
