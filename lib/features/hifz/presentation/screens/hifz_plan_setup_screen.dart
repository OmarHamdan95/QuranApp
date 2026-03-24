import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/hifz_plan.dart';
import '../providers/hifz_providers.dart';

/// Screen for creating or editing a Hifz (memorization) plan.
/// Supports surah/juz/custom range, daily/weekly targets,
/// reminders, estimated completion, and difficulty indicator.
class HifzPlanSetupScreen extends ConsumerStatefulWidget {
  const HifzPlanSetupScreen({super.key});

  @override
  ConsumerState<HifzPlanSetupScreen> createState() =>
      _HifzPlanSetupScreenState();
}

class _HifzPlanSetupScreenState extends ConsumerState<HifzPlanSetupScreen> {
  int _dailyGoal = AppConstants.defaultDailyAyahGoal;
  int _startSurah = 1;
  int _startAyah = 1;
  int? _endSurah;
  HifzScheduleType _scheduleType = HifzScheduleType.daily;
  HifzRangeType _rangeType = HifzRangeType.fullQuran;
  bool _includeRevision = true;
  int _revisionAyahs = 10;
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 6, minute: 0);
  bool _isSaving = false;

  static const _surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
    'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
    'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
    'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
    'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان',
    'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
    'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر',
    'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
    'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
    'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
    'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق',
    'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج',
    'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة',
    'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
    'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج',
    'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
    'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين',
    'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
    'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل',
    'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر',
    'المسد', 'الإخلاص', 'الفلق', 'الناس',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final difficulty = _getDifficulty();
    final remainingAyahs = _estimateRemainingAyahs();
    final daysToComplete = _estimateDaysToComplete(remainingAyahs);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'خطة الحفظ',
          style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Range Type ──
            _SectionHeader(title: 'نطاق الحفظ', isDark: isDark),
            const SizedBox(height: 8),
            _RangeTypeSelector(
              selected: _rangeType,
              onChanged: (v) => setState(() => _rangeType = v),
            ),
            const SizedBox(height: 20),

            // ── Start Position ──
            if (_rangeType != HifzRangeType.fullQuran) ...[
              _SectionHeader(title: 'بداية الحفظ', isDark: isDark),
              const SizedBox(height: 8),
              _SurahSelector(
                label: 'من سورة',
                value: _startSurah,
                names: _surahNames,
                onChanged: (v) => setState(() {
                  _startSurah = v;
                  _startAyah = 1;
                }),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              if (_rangeType == HifzRangeType.bySurah ||
                  _rangeType == HifzRangeType.custom) ...[
                _SurahSelector(
                  label: 'إلى سورة',
                  value: _endSurah ?? 114,
                  names: _surahNames,
                  onChanged: (v) => setState(() => _endSurah = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
              ],
            ],

            // ── Daily Goal ──
            _SectionHeader(title: 'الهدف اليومي', isDark: isDark),
            const SizedBox(height: 8),
            _DailyGoalCard(
              goal: _dailyGoal,
              difficulty: difficulty,
              isDark: isDark,
              onChanged: (v) => setState(() => _dailyGoal = v),
            ),
            const SizedBox(height: 20),

            // ── Schedule ──
            _SectionHeader(title: 'جدول الحفظ', isDark: isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ScheduleChip(
                  label: 'يوميًا',
                  icon: Icons.calendar_today,
                  type: HifzScheduleType.daily,
                  selected: _scheduleType == HifzScheduleType.daily,
                  onTap: () =>
                      setState(() => _scheduleType = HifzScheduleType.daily),
                ),
                _ScheduleChip(
                  label: '٥ أيام/أسبوع',
                  icon: Icons.date_range,
                  type: HifzScheduleType.fiveDays,
                  selected: _scheduleType == HifzScheduleType.fiveDays,
                  onTap: () =>
                      setState(() => _scheduleType = HifzScheduleType.fiveDays),
                ),
                _ScheduleChip(
                  label: 'مخصص',
                  icon: Icons.tune,
                  type: HifzScheduleType.custom,
                  selected: _scheduleType == HifzScheduleType.custom,
                  onTap: () =>
                      setState(() => _scheduleType = HifzScheduleType.custom),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Revision ──
            _SectionHeader(title: 'المراجعة', isDark: isDark),
            const SizedBox(height: 8),
            _RevisionCard(
              includeRevision: _includeRevision,
              revisionAyahs: _revisionAyahs,
              isDark: isDark,
              onToggle: (v) => setState(() => _includeRevision = v),
              onRevisionChanged: (v) => setState(() => _revisionAyahs = v),
            ),
            const SizedBox(height: 20),

            // ── Reminders ──
            _SectionHeader(title: 'التذكيرات', isDark: isDark),
            const SizedBox(height: 8),
            _RemindersCard(
              enabled: _remindersEnabled,
              time: _reminderTime,
              isDark: isDark,
              onToggle: (v) => setState(() => _remindersEnabled = v),
              onTimePicked: (t) => setState(() => _reminderTime = t),
            ),
            const SizedBox(height: 20),

            // ── Estimated Completion ──
            _EstimationCard(
              dailyGoal: _dailyGoal,
              daysToComplete: daysToComplete,
              difficulty: difficulty,
              isDark: isDark,
            ),
            const SizedBox(height: 28),

            // ── Save Button ──
            ElevatedButton(
              onPressed: _isSaving ? null : _savePlan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'حفظ الخطة',
                      style: AppTextStyles.arabicBody.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
            ),

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
      ),
    );
  }

  HifzDifficulty _getDifficulty() {
    if (_dailyGoal <= 3) return HifzDifficulty.beginner;
    if (_dailyGoal <= 7) return HifzDifficulty.moderate;
    if (_dailyGoal <= 15) return HifzDifficulty.intensive;
    return HifzDifficulty.advanced;
  }

  int _estimateRemainingAyahs() {
    return switch (_rangeType) {
      HifzRangeType.fullQuran => AppConstants.totalAyahs,
      HifzRangeType.byJuz => AppConstants.totalAyahs ~/ 3,
      _ => AppConstants.totalAyahs,
    };
  }

  int _estimateDaysToComplete(int remaining) {
    if (_dailyGoal <= 0) return 0;
    final studyFraction =
        _scheduleType == HifzScheduleType.fiveDays ? 5 / 7 : 1.0;
    return (remaining / _dailyGoal / studyFraction).ceil();
  }

  Future<void> _savePlan() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final plan = HifzPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: 'خطتي الجديدة',
      dailyAyahGoal: _dailyGoal,
      scheduleType: _scheduleType,
      rangeType: _rangeType,
      startSurah: _startSurah,
      startAyah: _startAyah,
      endSurah: _endSurah,
      includeRevision: _includeRevision,
      revisionAyahsPerDay: _includeRevision ? _revisionAyahs : 0,
      remindersEnabled: _remindersEnabled,
      reminderTime: _remindersEnabled
          ? '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
          : null,
      createdAt: DateTime.now(),
    );

    ref.read(hifzProvider.notifier).savePlan(plan);

    if (mounted) {
      setState(() => _isSaving = false);
      context.showSuccess('تم حفظ خطة الحفظ بنجاح');
      Navigator.of(context).pop();
    }
  }
}

// ─────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.arabicBody.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}

class _RangeTypeSelector extends StatelessWidget {
  final HifzRangeType selected;
  final ValueChanged<HifzRangeType> onChanged;

  const _RangeTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (type: HifzRangeType.fullQuran, label: 'القرآن كاملاً', icon: Icons.menu_book),
      (type: HifzRangeType.byJuz, label: 'بالأجزاء', icon: Icons.layers_outlined),
      (type: HifzRangeType.bySurah, label: 'بالسور', icon: Icons.bookmark_border),
      (type: HifzRangeType.custom, label: 'نطاق مخصص', icon: Icons.tune),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected == item.type;
        return GestureDetector(
          onTap: () => onChanged(item.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(width: 6),
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SurahSelector extends StatelessWidget {
  final String label;
  final int value;
  final List<String> names;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _SurahSelector({
    required this.label,
    required this.value,
    required this.names,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                isExpanded: true,
                items: List.generate(names.length, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                      '${i + 1}. ${names[i]}',
                      style: AppTextStyles.arabicCaption,
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }),
                onChanged: (v) => onChanged(v ?? 1),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final int goal;
  final HifzDifficulty difficulty;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _DailyGoalCard({
    required this.goal,
    required this.difficulty,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = switch (difficulty) {
      HifzDifficulty.beginner => AppColors.success,
      HifzDifficulty.moderate => AppColors.info,
      HifzDifficulty.intensive => AppColors.warning,
      HifzDifficulty.advanced => AppColors.error,
    };
    final diffLabel = switch (difficulty) {
      HifzDifficulty.beginner => 'مبتدئ',
      HifzDifficulty.moderate => 'متوسط',
      HifzDifficulty.intensive => 'مكثف',
      HifzDifficulty.advanced => 'متقدم',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Difficulty badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diffLabel,
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: diffColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              // Goal display
              RichText(
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: ' آيات/يوم',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    TextSpan(
                      text: '$goal',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: goal.toDouble(),
            min: AppConstants.minDailyAyahGoal.toDouble(),
            max: AppConstants.maxDailyAyahGoal.toDouble(),
            divisions: AppConstants.maxDailyAyahGoal -
                AppConstants.minDailyAyahGoal,
            label: '$goal آيات',
            activeColor: AppColors.primary,
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppConstants.maxDailyAyahGoal}',
                style:
                    AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryLight),
              ),
              Text(
                '${AppConstants.minDailyAyahGoal}',
                style:
                    AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final HifzScheduleType type;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleChip({
    required this.label,
    required this.icon,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.dividerLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.arabicCaption.copyWith(
                color: selected
                    ? Colors.white
                    : AppColors.textPrimaryLight,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevisionCard extends StatelessWidget {
  final bool includeRevision;
  final int revisionAyahs;
  final bool isDark;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onRevisionChanged;

  const _RevisionCard({
    required this.includeRevision,
    required this.revisionAyahs,
    required this.isDark,
    required this.onToggle,
    required this.onRevisionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: includeRevision,
            onChanged: onToggle,
            title: Text(
              'تضمين المراجعة اليومية',
              style: AppTextStyles.arabicBody,
              textDirection: TextDirection.rtl,
            ),
            subtitle: Text(
              'مراجعة الآيات المحفوظة سابقًا',
              style: AppTextStyles.arabicCaption
                  .copyWith(color: AppColors.textTertiaryLight),
              textDirection: TextDirection.rtl,
            ),
            activeColor: AppColors.primary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          if (includeRevision) ...[
            Divider(
              height: 0,
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.primary),
                        onPressed: revisionAyahs > 5
                            ? () => onRevisionChanged(revisionAyahs - 5)
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$revisionAyahs',
                        style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.primary),
                        onPressed: revisionAyahs < 50
                            ? () => onRevisionChanged(revisionAyahs + 5)
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Text(
                    'آيات مراجعة يوميًا',
                    style: AppTextStyles.arabicCaption
                        .copyWith(color: AppColors.textSecondaryLight),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemindersCard extends StatelessWidget {
  final bool enabled;
  final TimeOfDay time;
  final bool isDark;
  final ValueChanged<bool> onToggle;
  final ValueChanged<TimeOfDay> onTimePicked;

  const _RemindersCard({
    required this.enabled,
    required this.time,
    required this.isDark,
    required this.onToggle,
    required this.onTimePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: enabled,
            onChanged: onToggle,
            title: Text(
              'تفعيل التذكيرات',
              style: AppTextStyles.arabicBody,
              textDirection: TextDirection.rtl,
            ),
            subtitle: Text(
              'تذكير يومي بموعد الحفظ',
              style: AppTextStyles.arabicCaption
                  .copyWith(color: AppColors.textTertiaryLight),
              textDirection: TextDirection.rtl,
            ),
            activeColor: AppColors.primary,
            secondary: const Icon(Icons.notifications_outlined,
                color: AppColors.primary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          if (enabled) ...[
            Divider(
              height: 0,
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                  builder: (ctx, child) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: child!,
                  ),
                );
                if (picked != null) onTimePicked(picked);
              },
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.access_time, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'وقت التذكير',
                      style: AppTextStyles.arabicCaption
                          .copyWith(color: AppColors.textSecondaryLight),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EstimationCard extends StatelessWidget {
  final int dailyGoal;
  final int daysToComplete;
  final HifzDifficulty difficulty;
  final bool isDark;

  const _EstimationCard({
    required this.dailyGoal,
    required this.daysToComplete,
    required this.difficulty,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final years = daysToComplete ~/ 365;
    final months = (daysToComplete % 365) ~/ 30;

    String estimate;
    if (years > 0) {
      estimate = months > 0
          ? 'حوالي $years سنة و $months أشهر'
          : 'حوالي $years سنة';
    } else if (months > 0) {
      estimate = 'حوالي $months شهر';
    } else {
      estimate = '$daysToComplete يوم';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الوقت التقديري لختم القرآن',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Text(
                  estimate,
                  style: AppTextStyles.arabicBody.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 2),
                Text(
                  'بمعدل $dailyGoal آيات يوميًا',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }
}
