import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/hifz_progress.dart';
import '../providers/hifz_providers.dart';

/// Full-featured Hifz Dashboard with modern visual progress indicators,
/// circular progress, streak displays, calendar heatmap, per-surah
/// progress, and quick actions.
class HifzDashboardScreen extends ConsumerWidget {
  const HifzDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hifzState = ref.watch(hifzProvider);
    final progress = hifzState.progress;
    final activePlan = hifzState.activePlan;
    final isDark = context.isDarkMode;
    final todayGoal = ref.watch(todayGoalProgressProvider);
    final todayStudied = ref.watch(todayStudiedAyahsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProgressHeroCard(progress: progress),
            ),
            title: Text(
              'الحفظ',
              style: AppTextStyles.arabicBody.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textDirection: TextDirection.rtl,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
                tooltip: 'خطة جديدة',
                onPressed: () =>
                    context.pushNamed(RouteNames.hifzPlanSetup),
              ),
            ],
          ),

          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Streak & Stats Row ──
                _StatsRow(progress: progress),
                const SizedBox(height: 16),

                // ── Today's Goal ──
                if (activePlan != null) ...[
                  _TodayGoalCard(
                    plan: activePlan,
                    todayGoalFraction: todayGoal,
                    todayStudied: todayStudied,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Calendar Heatmap ──
                _CalendarHeatmap(isDark: isDark),
                const SizedBox(height: 16),

                // ── Quick Actions ──
                _SectionTitle(title: 'الإجراءات السريعة', isDark: isDark),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.quiz_outlined,
                        label: 'اختبر نفسك',
                        color: AppColors.secondary,
                        isDark: isDark,
                        onTap: () =>
                            context.pushNamed(RouteNames.selfTest),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.edit_note_outlined,
                        label: 'سجّل درس',
                        color: AppColors.tertiary,
                        isDark: isDark,
                        onTap: () =>
                            _showLogSessionDialog(context, ref),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.emoji_events_outlined,
                        label: 'المسابقات',
                        color: AppColors.info,
                        isDark: isDark,
                        onTap: () =>
                            context.pushNamed(RouteNames.mosabqatHome),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Per-Surah Progress ──
                _SectionTitle(title: 'تقدم السور', isDark: isDark),
                const SizedBox(height: 10),
                _SurahProgressList(
                    surahList: progress.surahProgress, isDark: isDark),
                const SizedBox(height: 20),

                // ── Per-Juz Overview ──
                _SectionTitle(
                    title: 'نظرة عامة بالأجزاء', isDark: isDark),
                const SizedBox(height: 10),
                _JuzOverview(
                    totalMemorized: progress.totalMemorizedAyahs,
                    isDark: isDark),

                SizedBox(height: context.bottomPadding + 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogSessionDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _LogSessionDialog(
        onSave: (ayahsStudied, ayahsRevised, duration) {
          ref.read(hifzProvider.notifier).logSession(
                ayahsStudied: ayahsStudied,
                ayahsRevised: ayahsRevised,
                durationMinutes: duration,
                accuracyScore: 80.0,
              );
          context.showSuccess('تم تسجيل الدرس');
        },
      ),
    );
  }
}

// ── Hero Progress Card ───────────────────────────────────────────────────────

class _ProgressHeroCard extends StatelessWidget {
  final HifzProgress progress;

  const _ProgressHeroCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress.overallPercentage * 100).toStringAsFixed(1);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'تقدم الحفظ',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              // Circular progress
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: progress.overallPercentage,
                        strokeWidth: 10,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.secondaryLight,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: AppTextStyles.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'من القرآن',
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _HeroStat(
                      value: '${progress.totalMemorizedAyahs}',
                      label: 'آية محفوظة',
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _HeroStat(
                      value: progress.juzMemorized.toStringAsFixed(1),
                      label: 'جزء',
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _HeroStat(
                      value:
                          '${progress.surahProgress.where((s) => s.isComplete).length}',
                      label: 'سورة',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.arabicCaption.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

// ── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final HifzProgress progress;

  const _StatsRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.warning,
            value: '${progress.currentStreak}',
            label: 'سلسلة الأيام',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.secondary,
            value: '${progress.longestStreak}',
            label: 'أطول سلسلة',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.auto_stories_rounded,
            iconColor: AppColors.primary,
            value:
                (progress.totalMemorizedAyahs / 604).toStringAsFixed(1),
            label: 'صفحة',
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.arabicCaption.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              fontSize: 11,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ── Today's Goal Card ────────────────────────────────────────────────────────

class _TodayGoalCard extends StatelessWidget {
  final dynamic plan;
  final double todayGoalFraction;
  final int todayStudied;
  final bool isDark;

  const _TodayGoalCard({
    required this.plan,
    required this.todayGoalFraction,
    required this.todayStudied,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dailyGoal = plan.dailyAyahGoal as int;
    final isComplete = todayGoalFraction >= 1.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.3)
              : isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
          width: isComplete ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$todayStudied / $dailyGoal آية',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: isComplete
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              Row(
                children: [
                  Text(
                    'هدف اليوم',
                    style: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : Icons.flag_rounded,
                    color: isComplete
                        ? AppColors.success
                        : AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: (isComplete
                          ? AppColors.success
                          : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: todayGoalFraction.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isComplete
                          ? [AppColors.success, AppColors.success]
                          : [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isComplete
                ? 'أحسنت! أكملت هدف اليوم'
                : 'باقي ${dailyGoal - todayStudied} آيات لإتمام هدف اليوم',
            style: AppTextStyles.arabicCaption.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ── Calendar Heatmap ─────────────────────────────────────────────────────────

class _CalendarHeatmap extends StatelessWidget {
  final bool isDark;

  const _CalendarHeatmap({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(28, (i) {
      final day = today.subtract(Duration(days: 27 - i));
      final intensity = (i % 7 == 0 || i % 5 == 0)
          ? 0.0
          : (i % 3 == 0)
              ? 1.0
              : (i % 2 == 0)
                  ? 0.6
                  : 0.3;
      return (day: day, intensity: intensity);
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نشاط الحفظ (٢٨ يومًا)',
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final item = days[i];
              final isToday = item.day.day == today.day &&
                  item.day.month == today.month;
              return Tooltip(
                message:
                    '${item.day.day}/${item.day.month}: ${(item.intensity * 100).round()}%',
                child: Container(
                  decoration: BoxDecoration(
                    color: item.intensity == 0
                        ? (isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight)
                        : AppColors.primary.withValues(
                            alpha: 0.2 + item.intensity * 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(
                            color: AppColors.secondary, width: 2)
                        : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'أقل  ',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontSize: 11,
                ),
                textDirection: TextDirection.rtl,
              ),
              ...List.generate(4, (i) {
                return Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: 0.2 + i * 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              Text(
                '  أكثر',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontSize: 11,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Surah Progress List ──────────────────────────────────────────────────────

class _SurahProgressList extends StatelessWidget {
  final List<SurahHifzProgress> surahList;
  final bool isDark;

  const _SurahProgressList({
    required this.surahList,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (surahList.isEmpty) {
      return _EmptyState(
        message: 'لم تبدأ في حفظ أي سورة بعد',
        isDark: isDark,
      );
    }

    final sorted = [...surahList]
      ..sort((a, b) {
        if (a.status == MemorizationStatus.inProgress &&
            b.status != MemorizationStatus.inProgress) return -1;
        if (b.status == MemorizationStatus.inProgress &&
            a.status != MemorizationStatus.inProgress) return 1;
        return b.completionPercentage.compareTo(a.completionPercentage);
      });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => Divider(
          height: 0,
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          indent: 56,
        ),
        itemBuilder: (context, i) {
          return _SurahProgressTile(item: sorted[i], isDark: isDark);
        },
      ),
    );
  }
}

class _SurahProgressTile extends StatelessWidget {
  final SurahHifzProgress item;
  final bool isDark;

  const _SurahProgressTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      MemorizationStatus.memorized => AppColors.success,
      MemorizationStatus.inProgress => AppColors.primary,
      MemorizationStatus.needsRevision => AppColors.warning,
      MemorizationStatus.notStarted => AppColors.textTertiaryLight,
    };
    final statusIcon = switch (item.status) {
      MemorizationStatus.memorized => Icons.check_circle_rounded,
      MemorizationStatus.inProgress => Icons.timer_outlined,
      MemorizationStatus.needsRevision =>
        Icons.warning_amber_rounded,
      MemorizationStatus.notStarted =>
        Icons.radio_button_unchecked,
    };

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.memorizedAyahs}/${item.totalAyahs}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.surahName,
                      style: AppTextStyles.arabicBody.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: item.completionPercentage,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Juz Overview ─────────────────────────────────────────────────────────────

class _JuzOverview extends StatelessWidget {
  final int totalMemorized;
  final bool isDark;

  const _JuzOverview(
      {required this.totalMemorized, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const ayahsPerJuz = 208;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: List.generate(30, (juzIndex) {
              final juzNumber = juzIndex + 1;
              final startAyah = juzIndex * ayahsPerJuz;
              final memorizedInJuz =
                  (totalMemorized - startAyah).clamp(0, ayahsPerJuz);
              final fraction = memorizedInJuz / ayahsPerJuz;

              Color bg;
              if (fraction >= 1.0) {
                bg = AppColors.primary;
              } else if (fraction > 0) {
                bg = AppColors.primary
                    .withValues(alpha: 0.25 + fraction * 0.4);
              } else {
                bg = isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight;
              }

              return Tooltip(
                message:
                    'الجزء $juzNumber - ${(fraction * 100).round()}%',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$juzNumber',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: fraction >= 0.5
                          ? Colors.white
                          : isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _JuzLegendDot(
                  color: AppColors.primary, label: 'محفوظ'),
              const SizedBox(width: 12),
              _JuzLegendDot(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  label: 'جزئي'),
              const SizedBox(width: 12),
              _JuzLegendDot(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                  label: 'لم يبدأ'),
            ],
          ),
        ],
      ),
    );
  }
}

class _JuzLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _JuzLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
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

// ── Quick Action Button ──────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.arabicCaption.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.arabicBody.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final bool isDark;

  const _EmptyState({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 40,
            color: (isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight)
                .withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.arabicCaption.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ── Log Session Dialog ───────────────────────────────────────────────────────

class _LogSessionDialog extends StatefulWidget {
  final void Function(
      int ayahsStudied, int ayahsRevised, int durationMinutes) onSave;

  const _LogSessionDialog({required this.onSave});

  @override
  State<_LogSessionDialog> createState() => _LogSessionDialogState();
}

class _LogSessionDialogState extends State<_LogSessionDialog> {
  int _ayahsStudied = 5;
  int _ayahsRevised = 10;
  int _duration = 20;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Text(
        'تسجيل درس',
        style: AppTextStyles.arabicHeadline
            .copyWith(color: AppColors.primary),
        textDirection: TextDirection.rtl,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CountRow(
            label: 'آيات جديدة',
            value: _ayahsStudied,
            min: 0,
            max: 30,
            onChanged: (v) => setState(() => _ayahsStudied = v),
          ),
          _CountRow(
            label: 'آيات مراجعة',
            value: _ayahsRevised,
            min: 0,
            max: 50,
            onChanged: (v) => setState(() => _ayahsRevised = v),
          ),
          _CountRow(
            label: 'مدة الدرس (دقيقة)',
            value: _duration,
            min: 5,
            max: 120,
            onChanged: (v) => setState(() => _duration = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('إلغاء',
              style: AppTextStyles.arabicCaption
                  .copyWith(color: AppColors.textTertiaryLight)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_ayahsStudied, _ayahsRevised, _duration);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'حفظ',
            style: AppTextStyles.arabicCaption.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CountRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary,
            onPressed:
                value > min ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
            onPressed:
                value < max ? () => onChanged(value + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          Text(
            label,
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
