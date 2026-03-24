import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/isar_service.dart';
import '../../domain/entities/tafsir.dart';
import '../../domain/repositories/tafsir_repository.dart';
import '../models/tafsir_model.dart';

/// Implementation of [TafsirRepository] with a bundled content layer
/// and optional local cache.
///
/// For the MVP phase, tafsir text is generated locally (real integration
/// with a tafsir API or bundled SQLite is a production step).
/// The cache layer uses [IsarService] (SharedPreferences) so that once
/// content is loaded it does not need to be re-fetched.
class TafsirRepositoryImpl implements TafsirRepository {
  final IsarService _isarService;

  TafsirRepositoryImpl(this._isarService);

  // ── Public interface ──────────────────────────────────────────────────────

  @override
  Future<Either<TafsirFailure, Tafsir>> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  }) async {
    try {
      // 1. Try cache
      final cached = _fromCache(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        source: source,
      );
      if (cached != null) return Right(cached);

      // 2. Generate / fetch content
      final tafsir = _buildTafsir(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        source: source,
      );

      // 3. Persist to cache
      await _saveToCache(tafsir);

      return Right(tafsir);
    } catch (e) {
      debugPrint('TafsirRepositoryImpl.getTafsir error: $e');
      return Left(TafsirFailure('Failed to load tafsir', e));
    }
  }

  @override
  Future<Either<TafsirFailure, List<Tafsir>>> getTafsirBySurah({
    required int surahNumber,
    required TafsirSource source,
  }) async {
    try {
      // Return tafsir for ayahs 1-7 of al-Fatiha as a demonstration;
      // a full implementation would query the bundled database.
      final ayahCount = _surahAyahCount(surahNumber);
      final results = <Tafsir>[];
      for (var i = 1; i <= ayahCount; i++) {
        final result = await getTafsir(
          surahNumber: surahNumber,
          ayahNumber: i,
          source: source,
        );
        result.fold((_) {}, results.add);
      }
      return Right(results);
    } catch (e) {
      return Left(TafsirFailure('Failed to load surah tafsir', e));
    }
  }

  @override
  Future<bool> isCached({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  }) async {
    final key = _cacheKey(source, surahNumber, ayahNumber);
    return _isarService.containsKey(key);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _cacheKey(TafsirSource source, int surah, int ayah) =>
      'tafsir_${source.apiKey}_${surah}_$ayah';

  TafsirModel? _fromCache({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  }) {
    try {
      final key = _cacheKey(source, surahNumber, ayahNumber);
      final json = _isarService.getString(key);
      if (json == null) return null;
      return TafsirModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(TafsirModel tafsir) async {
    try {
      final key = _cacheKey(tafsir.source, tafsir.surahNumber, tafsir.ayahNumber);
      await _isarService.setString(key, tafsir.toJson());
    } catch (_) {}
  }

  /// Returns a locally-generated tafsir entry.
  ///
  /// In production this method would call a bundled SQLite database or
  /// a remote tafsir API endpoint.
  TafsirModel _buildTafsir({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  }) {
    final text = _tafsirText(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      source: source,
    );

    return TafsirModel(
      source: source,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      text: text,
    );
  }

  /// Returns representative tafsir text.
  String _tafsirText({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  }) {
    // Specific well-known passages with rich tafsir.
    if (surahNumber == 1 && ayahNumber == 1) {
      switch (source) {
        case TafsirSource.ibnKathir:
          return 'قال ابن كثير رحمه الله: البسملة آية من كتاب الله الكريم، '
              'وهي مشتملة على ذكر اسم الله وصفتين عظيمتين من صفاته، '
              'وهما: الرحمة العامة التي تشمل جميع المخلوقات، والرحمة الخاصة '
              'بالمؤمنين. ويستحب البدء بها في كل أمر ذي بال، '
              'وقد ثبت ذلك في السنة النبوية الشريفة بأحاديث كثيرة.';
        case TafsirSource.alSaadi:
          return 'قال السعدي رحمه الله: هذه الجملة الجليلة يُبتدأ بها في كل '
              'عمل وقول مشروع، وفيها اعتراف العبد بأن الله هو المعبود بحق، '
              'وأن جميع صفات الكمال ثابتة له، والنعم كلها منه، '
              'وأنه المتفضل على عباده في الدنيا والآخرة.';
        case TafsirSource.alTabari:
          return 'قال الطبري رحمه الله: القول في تأويل قوله تعالى: '
              '﴿بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ﴾ يعني بذلك جل ثناؤه: '
              'أبتدئ بأسماء الله جميعها، إذ كانت "الباء" دخلت على الاسم '
              'وهو يؤدي عن الجمع الكثير، وذلك أن اسم الله يجمع الأسماء كلها.';
        case TafsirSource.alQurtubi:
          return 'قال القرطبي رحمه الله: البسملة آية تامة في أول كل سورة، '
              'وقد أجمع العلماء على أن "بسم الله الرحمن الرحيم" مكتوبة '
              'في المصحف، وأنها من القرآن في الجملة، وإنما اختلفوا هل '
              'هي آية مستقلة أم جزء من الفاتحة.';
        case TafsirSource.muyassar:
          return 'أبتدئ بذكر اسم الله مستعيناً به، والله هو المعبود الحق '
              'وحده لا شريك له، الرحمن: ذو الرحمة الواسعة التي وسعت '
              'كل شيء، الرحيم: الرحيم بعباده المؤمنين خاصة.';
      }
    }

    if (surahNumber == 2 && ayahNumber == 255) {
      return 'هذه الآية الكريمة هي آية الكرسي، وهي أعظم آية في كتاب الله، '
          'لما اشتملت عليه من صفات الجلال والكمال. قال صلى الله عليه وسلم: '
          '"أعظم آية في القرآن الكريم آية الكرسي". '
          'فيها إثبات الوحدانية لله سبحانه، وإثبات الحياة الكاملة، '
          'والقيومية التي تعني قيامه بنفسه وقيامه على كل شيء سواه. '
          'ولا تأخذه سنة ولا نوم أي لا يعتريه نقص في حياته ولا قصور '
          'في علمه وتدبيره. وله ما في السماوات وما في الأرض ملكاً '
          'وخلقاً وعبيداً. لا يشفع أحد عنده إلا بإذنه. '
          'يعلم ما بين أيدي خلقه من أمور الدنيا وما خلفهم من '
          'أمور الآخرة. الكرسي: محل قدمي الرحمن. '
          'ولا يئوده أي لا يثقله ولا يشق عليه حفظ السماوات والأرض.';
    }

    // Generic template for all other ayahs.
    return 'تفسير الآية الكريمة رقم $ayahNumber من سورة $surahNumber '
        'وفق ${source.arabicName}:\n\n'
        'تُبيِّن هذه الآية الكريمة جانباً من عظمة الله سبحانه وتعالى '
        'وكمال صفاته، وتوجّه المؤمنين إلى التأمل في معانيها الجليلة. '
        'وقد ذكر أهل التفسير في بيان هذه الآية أقوالاً متعددة، '
        'كلها تصبُّ في المعنى العام الذي تدل عليه الكلمات.\n\n'
        'وقد استنبط العلماء من هذه الآية جملةً من الفوائد الفقهية '
        'والأحكام الشرعية والحِكَم البالغة التي تُثري فهم المسلم '
        'لكتاب الله العزيز. ومن أبرز ما يُستفاد: الإيمان بوحدانية الله '
        'وكمال صفاته، والتسليم لأمره والانقياد لشريعته.\n\n'
        'يُنصح بمراجعة المصادر الأصلية لـ${source.arabicName} للاطلاع '
        'على كامل الشرح والتفصيل.';
  }

  /// Returns the number of ayahs in a given surah.
  int _surahAyahCount(int surahNumber) {
    const counts = <int>[
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99,
      128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34,
      30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29,
      18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12,
      12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19,
      36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
      11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
    ];
    if (surahNumber < 1 || surahNumber > 114) return 7;
    return counts[surahNumber - 1];
  }
}
