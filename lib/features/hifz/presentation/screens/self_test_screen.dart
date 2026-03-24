import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/hifz_providers.dart';

// ── Data Types ───────────────────────────────────────────────────────────────

class _TestItem {
  final String prompt;
  final String answer;
  final String reference;
  final String? hint;

  const _TestItem({
    required this.prompt,
    required this.answer,
    required this.reference,
    this.hint,
  });
}

enum _AnswerResult { correct, incorrect, skipped }

// ── Self-Test Screen ─────────────────────────────────────────────────────────

/// Self-test screen for reviewing memorized ayahs with modern design.
/// Shows the beginning of an ayah, user recites, then reveals to verify.
class SelfTestScreen extends ConsumerStatefulWidget {
  const SelfTestScreen({super.key});

  @override
  ConsumerState<SelfTestScreen> createState() => _SelfTestScreenState();
}

class _SelfTestScreenState extends ConsumerState<SelfTestScreen>
    with SingleTickerProviderStateMixin {
  bool _isRevealed = false;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  bool _isPlaying = false;
  bool _isFinished = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  final List<int> _failedIndices = [];
  bool _inRepeatMode = false;
  List<int> _repeatQueue = [];

  static const _testItems = [
    _TestItem(
      prompt: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ﴿١﴾ ...',
      answer: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
      reference: 'الفاتحة : ٢',
    ),
    _TestItem(
      prompt: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ﴿٣﴾ ...',
      answer: 'مَـٰلِكِ يَوْمِ ٱلدِّينِ',
      reference: 'الفاتحة : ٤',
    ),
    _TestItem(
      prompt: 'إِيَّاكَ نَعْبُدُ ...',
      answer: 'وَإِيَّاكَ نَسْتَعِينُ',
      reference: 'الفاتحة : ٥',
    ),
    _TestItem(
      prompt: 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ ﴿٦﴾ ...',
      answer: 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ',
      reference: 'الفاتحة : ٧',
    ),
    _TestItem(
      prompt: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ ﴿١﴾ ...',
      answer: 'ٱللَّهُ ٱلصَّمَدُ',
      reference: 'الإخلاص : ٢',
      hint: 'من سورة الإخلاص',
    ),
    _TestItem(
      prompt: 'لَمْ يَلِدْ وَلَمْ يُولَدْ ﴿٣﴾ ...',
      answer: 'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌ',
      reference: 'الإخلاص : ٤',
    ),
    _TestItem(
      prompt: 'إِنَّا أَعْطَيْنَـٰكَ ٱلْكَوْثَرَ ﴿١﴾ ...',
      answer: 'فَصَلِّ لِرَبِّكَ وَٱنْحَرْ',
      reference: 'الكوثر : ٢',
    ),
    _TestItem(
      prompt: 'إِذَا جَآءَ نَصْرُ ٱللَّهِ وَٱلْفَتْحُ ﴿١﴾ ...',
      answer: 'وَرَأَيْتَ ٱلنَّاسَ يَدْخُلُونَ فِى دِينِ ٱللَّهِ أَفْوَاجًا',
      reference: 'النصر : ٢',
    ),
  ];

  List<_TestItem> get _currentItems => _inRepeatMode
      ? _repeatQueue.map((i) => _testItems[i]).toList()
      : _testItems;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _revealController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _toggleAudio() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  void _reveal() {
    setState(() => _isRevealed = true);
    _revealController.forward(from: 0);
  }

  void _markResult(_AnswerResult result) {
    if (result == _AnswerResult.correct) {
      _correctCount++;
    } else {
      _incorrectCount++;
      if (!_inRepeatMode) {
        _failedIndices.add(_currentIndex);
      }
    }

    final nextIndex = _currentIndex + 1;

    if (nextIndex >= _currentItems.length) {
      _timer?.cancel();
      if (!_inRepeatMode && _failedIndices.isNotEmpty) {
        setState(() {
          _isRevealed = false;
          _currentIndex = 0;
          _isFinished = true;
        });
      } else {
        ref.read(hifzProvider.notifier).logSession(
              ayahsStudied: 0,
              ayahsRevised: _testItems.length,
              durationMinutes: _elapsedSeconds ~/ 60,
              accuracyScore: _testItems.isNotEmpty
                  ? _correctCount / _testItems.length * 100
                  : 0,
            );
        setState(() {
          _isRevealed = false;
          _isFinished = true;
          _inRepeatMode = false;
        });
      }
    } else {
      setState(() {
        _currentIndex = nextIndex;
        _isRevealed = false;
      });
      _revealController.reset();
    }
  }

  void _startRepeatFailed() {
    setState(() {
      _inRepeatMode = true;
      _repeatQueue = List.from(_failedIndices);
      _failedIndices.clear();
      _currentIndex = 0;
      _isFinished = false;
      _isRevealed = false;
    });
    _revealController.reset();
    _startTimer();
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      _isRevealed = false;
      _isFinished = false;
      _inRepeatMode = false;
      _repeatQueue = [];
      _failedIndices.clear();
      _elapsedSeconds = 0;
    });
    _revealController.reset();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    if (_isFinished) {
      return _ResultsScreen(
        correct: _correctCount,
        incorrect: _incorrectCount,
        total: _testItems.length,
        elapsedSeconds: _elapsedSeconds,
        failedCount: _failedIndices.length,
        onRepeatFailed:
            _failedIndices.isNotEmpty ? _startRepeatFailed : null,
        onRestart: _restart,
      );
    }

    final items = _currentItems;
    final item = items[_currentIndex];

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _inRepeatMode ? 'إعادة الخطأ' : 'اختبر نفسك',
          style: AppTextStyles.arabicBody.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          textDirection: TextDirection.rtl,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScoreBadge(
                    count: _correctCount,
                    color: AppColors.success,
                    icon: Icons.check_rounded),
                const SizedBox(width: 6),
                _ScoreBadge(
                    count: _incorrectCount,
                    color: AppColors.error,
                    icon: Icons.close_rounded),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / items.length,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} / ${items.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Instruction
            Text(
              'أكمل الآية التالية:',
              style: AppTextStyles.arabicCaption.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),

            // Prompt card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.quranPageBackgroundDark
                    : AppColors.quranPageBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.15 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    item.prompt,
                    style: AppTextStyles.quranAyah.copyWith(
                      fontSize: 24,
                      color: isDark
                          ? AppColors.quranTextColorDark
                          : AppColors.quranTextColor,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  if (item.hint != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.hint!,
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: AppColors.info,
                          fontSize: 12,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Audio play button
            Center(
              child: GestureDetector(
                onTap: _toggleAudio,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isPlaying ? 'يشغّل...' : 'تشغيل الآية',
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: AppColors.primary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isPlaying
                            ? Icons.stop_rounded
                            : Icons.volume_up_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Revealed answer
            if (_isRevealed)
              FadeTransition(
                opacity: _revealAnimation,
                child: SizeTransition(
                  sizeFactor: _revealAnimation,
                  axisAlignment: -1,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primary.withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item.answer,
                          style: AppTextStyles.quranAyah.copyWith(
                            fontSize: 24,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.reference,
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Action buttons
            if (!_isRevealed) ...[
              GestureDetector(
                onTap: _reveal,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'كشف الإجابة',
                        style: AppTextStyles.arabicBody.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.visibility_outlined,
                          color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () =>
                    _markResult(_AnswerResult.skipped),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'تخطي',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _AnswerButton(
                      label: 'لم أتذكر',
                      icon: Icons.close_rounded,
                      color: AppColors.error,
                      onTap: () =>
                          _markResult(_AnswerResult.incorrect),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnswerButton(
                      label: 'تذكرت',
                      icon: Icons.check_rounded,
                      color: AppColors.success,
                      filled: true,
                      onTap: () =>
                          _markResult(_AnswerResult.correct),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: context.bottomPadding + 8),
          ],
        ),
      ),
    );
  }
}

// ── Score Badge ──────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int count;
  final Color color;
  final IconData icon;

  const _ScoreBadge({
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Answer Button ────────────────────────────────────────────────────────────

class _AnswerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.arabicCaption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: AppTextStyles.arabicCaption.copyWith(color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// ── Results Screen ───────────────────────────────────────────────────────────

class _ResultsScreen extends StatelessWidget {
  final int correct;
  final int incorrect;
  final int total;
  final int elapsedSeconds;
  final int failedCount;
  final VoidCallback? onRepeatFailed;
  final VoidCallback onRestart;

  const _ResultsScreen({
    required this.correct,
    required this.incorrect,
    required this.total,
    required this.elapsedSeconds,
    required this.failedCount,
    this.onRepeatFailed,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        total > 0 ? (correct / total * 100).round() : 0;
    final isDark = context.isDarkMode;

    final (message, color) = switch (percentage) {
      >= 90 => ('ممتاز! حفظك رائع', AppColors.secondary),
      >= 70 => ('أحسنت! استمر في المراجعة', AppColors.primary),
      >= 50 => ('جيد، كرر المراجعة', AppColors.info),
      _ => ('لا بأس، تدرب أكثر', AppColors.warning),
    };

    final mins = elapsedSeconds ~/ 60;
    final secs = elapsedSeconds % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'نتيجة الاختبار',
          style: AppTextStyles.arabicBody.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          textDirection: TextDirection.rtl,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Score circle
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: color, width: 4),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$correct / $total',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Message
            Text(
              message,
              style: AppTextStyles.arabicHeadline
                  .copyWith(color: color),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Stats row
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ResultStat(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    value: '$correct',
                    label: 'صحيح',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                  _ResultStat(
                    icon: Icons.cancel_rounded,
                    color: AppColors.error,
                    value: '$incorrect',
                    label: 'خطأ',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                  _ResultStat(
                    icon: Icons.timer_outlined,
                    color: AppColors.info,
                    value: timeStr,
                    label: 'الوقت',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Repeat failed
            if (failedCount > 0 && onRepeatFailed != null) ...[
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: onRepeatFailed,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'كرر الآيات الخاطئة ($failedCount)',
                          style: AppTextStyles.arabicBody.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.replay_rounded,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Restart
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.primary),
                label: Text(
                  'إعادة الاختبار',
                  style: AppTextStyles.arabicBody.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _ResultStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.arabicCaption.copyWith(
            color: AppColors.textTertiaryLight,
            fontSize: 12,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}
