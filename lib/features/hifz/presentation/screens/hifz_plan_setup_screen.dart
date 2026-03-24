import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Screen for creating or editing a Hifz (memorization) plan.
class HifzPlanSetupScreen extends ConsumerStatefulWidget {
  const HifzPlanSetupScreen({super.key});

  @override
  ConsumerState<HifzPlanSetupScreen> createState() => _HifzPlanSetupScreenState();
}

class _HifzPlanSetupScreenState extends ConsumerState<HifzPlanSetupScreen> {
  int _dailyGoal = AppConstants.defaultDailyAyahGoal;
  int _startSurah = 1;
  int _startAyah = 1;
  bool _includeRevision = true;
  String _selectedSchedule = 'daily';

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

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
            // Daily goal
            Text(
              'عدد الآيات يوميًا',
              style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Container(
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
                  Text(
                    '$_dailyGoal',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'آيات',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _dailyGoal.toDouble(),
                    min: AppConstants.minDailyAyahGoal.toDouble(),
                    max: AppConstants.maxDailyAyahGoal.toDouble(),
                    divisions: AppConstants.maxDailyAyahGoal - AppConstants.minDailyAyahGoal,
                    label: '$_dailyGoal',
                    onChanged: (value) {
                      setState(() => _dailyGoal = value.round());
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${AppConstants.minDailyAyahGoal}', style: AppTextStyles.labelSmall),
                      Text('${AppConstants.maxDailyAyahGoal}', style: AppTextStyles.labelSmall),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Start position
            Text(
              'بداية الحفظ',
              style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: 'السورة',
                    value: _startSurah,
                    items: List.generate(114, (i) => i + 1),
                    onChanged: (v) => setState(() => _startSurah = v ?? 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropdownField(
                    label: 'الآية',
                    value: _startAyah,
                    items: List.generate(286, (i) => i + 1),
                    onChanged: (v) => setState(() => _startAyah = v ?? 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Schedule
            Text(
              'جدول الحفظ',
              style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _ScheduleChip(
                  label: 'يوميًا',
                  value: 'daily',
                  isSelected: _selectedSchedule == 'daily',
                  onTap: () => setState(() => _selectedSchedule = 'daily'),
                ),
                _ScheduleChip(
                  label: '٥ أيام/أسبوع',
                  value: '5days',
                  isSelected: _selectedSchedule == '5days',
                  onTap: () => setState(() => _selectedSchedule = '5days'),
                ),
                _ScheduleChip(
                  label: 'مخصص',
                  value: 'custom',
                  isSelected: _selectedSchedule == 'custom',
                  onTap: () => setState(() => _selectedSchedule = 'custom'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Revision toggle
            SwitchListTile(
              value: _includeRevision,
              onChanged: (v) => setState(() => _includeRevision = v),
              title: Text(
                'تضمين المراجعة',
                style: AppTextStyles.arabicBody,
                textDirection: TextDirection.rtl,
              ),
              subtitle: Text(
                'مراجعة الآيات المحفوظة سابقًا',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // Estimated completion
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'بهذا المعدل، ستحفظ القرآن كاملاً في حوالي ${(6236 / _dailyGoal / 365).toStringAsFixed(1)} سنة',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: AppColors.primary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: () {
                context.showSuccess('تم حفظ خطة الحفظ');
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'حفظ الخطة',
                  style: AppTextStyles.arabicBody.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final int value;
  final List<int> items;
  final ValueChanged<int?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.arabicCaption,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: items.take(50).map((i) {
            return DropdownMenuItem(value: i, child: Text('$i'));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScheduleChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTextStyles.arabicCaption.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
    );
  }
}
