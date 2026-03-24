import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../main.dart';
import '../../../audio/presentation/providers/audio_providers.dart';
import '../../../prayer/presentation/providers/prayer_providers.dart';
import '../../../quran/presentation/providers/quran_providers.dart';

/// Settings screen providing user preferences and app configuration.
///
/// Organized into sections: Appearance, Reading, Audio, Prayer, and About.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final quranFontSize = ref.watch(quranFontSizeProvider);
    final showTranslation = ref.watch(showTranslationProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final calculationMethod = ref.watch(calculationMethodProvider);
    final madhab = ref.watch(madhabProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Appearance Section ──
          _SectionHeader(title: 'المظهر'),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'المظهر',
            subtitle: _themeModeLabel(themeMode),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),

          const _SectionDivider(),

          // ── Reading Section ──
          _SectionHeader(title: 'القراءة'),
          _SettingsTile(
            icon: Icons.text_fields,
            title: 'حجم خط القرآن',
            subtitle: '${quranFontSize.round()}',
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: quranFontSize,
                min: AppConstants.minFontSize,
                max: AppConstants.maxFontSize,
                onChanged: (v) {
                  ref.read(quranFontSizeProvider.notifier).state = v;
                },
              ),
            ),
          ),
          SwitchListTile(
            secondary: Icon(
              Icons.translate,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            title: Text(
              'إظهار الترجمة',
              style: AppTextStyles.arabicBody,
              textDirection: TextDirection.rtl,
            ),
            subtitle: Text(
              'عرض الترجمة أسفل النص العربي',
              style: AppTextStyles.arabicCaption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            value: showTranslation,
            onChanged: (v) {
              ref.read(showTranslationProvider.notifier).state = v;
            },
            activeColor: AppColors.primary,
          ),

          const _SectionDivider(),

          // ── Audio Section ──
          _SectionHeader(title: 'الصوت'),
          _SettingsTile(
            icon: Icons.record_voice_over_outlined,
            title: 'القارئ الافتراضي',
            subtitle: selectedReciter.nameArabic,
            onTap: () {
              // Opens reciter selector
              context.pushNamed(RouteNames.audioPlayer);
            },
          ),

          const _SectionDivider(),

          // ── Prayer Section ──
          _SectionHeader(title: 'الصلاة'),
          _SettingsTile(
            icon: Icons.calculate_outlined,
            title: 'طريقة الحساب',
            subtitle: _calculationMethodLabel(calculationMethod),
            onTap: () => _showCalculationMethodPicker(context, ref),
          ),
          _SettingsTile(
            icon: Icons.access_time,
            title: 'المذهب',
            subtitle: madhab == 'Shafi' ? 'الشافعي' : 'الحنفي',
            onTap: () => _showMadhabPicker(context, ref, madhab),
          ),

          const _SectionDivider(),

          // ── Data Section ──
          _SectionHeader(title: 'البيانات'),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'إدارة التحميلات',
            subtitle: 'تحميل وحذف الملفات الصوتية',
            onTap: () => context.pushNamed(RouteNames.downloads),
          ),
          _SettingsTile(
            icon: Icons.bookmark_outline,
            title: 'الإشارات المرجعية',
            subtitle: 'عرض وإدارة الإشارات المرجعية',
            onTap: () => context.pushNamed(RouteNames.bookmarks),
          ),

          const _SectionDivider(),

          // ── About Section ──
          _SectionHeader(title: 'حول التطبيق'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: AppConstants.appName,
            subtitle: 'الإصدار ${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'سياسة الخصوصية',
            subtitle: 'لا إعلانات - لا تتبع',
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            title: 'تقييم التطبيق',
            subtitle: 'ادعمنا بتقييمك',
            onTap: () {
              // TODO: Open store rating
            },
          ),
          _SettingsTile(
            icon: Icons.share_outlined,
            title: 'مشاركة التطبيق',
            subtitle: 'شارك التطبيق مع أصدقائك',
            onTap: () {
              // TODO: Share app link
            },
          ),

          SizedBox(height: context.bottomPadding + 80),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'تلقائي (حسب النظام)',
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
    };
  }

  String _calculationMethodLabel(String method) {
    return switch (method) {
      'MuslimWorldLeague' => 'رابطة العالم الإسلامي',
      'Egyptian' => 'الهيئة المصرية العامة للمساحة',
      'Karachi' => 'جامعة العلوم الإسلامية، كراتشي',
      'UmmAlQura' => 'أم القرى',
      'NorthAmerica' => 'الجمعية الإسلامية لأمريكا الشمالية',
      'MoonsightingCommittee' => 'لجنة رؤية الهلال',
      _ => method,
    };
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'اختر المظهر',
              style: AppTextStyles.arabicHeadline,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                title: Text(
                  switch (mode) {
                    ThemeMode.system => 'تلقائي (حسب النظام)',
                    ThemeMode.light => 'فاتح',
                    ThemeMode.dark => 'داكن',
                  },
                  style: AppTextStyles.arabicBody,
                  textDirection: TextDirection.rtl,
                ),
                value: mode,
                groupValue: current,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(themeModeProvider.notifier).state = v;
                  }
                  Navigator.of(context).pop();
                },
                activeColor: AppColors.primary,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCalculationMethodPicker(BuildContext context, WidgetRef ref) {
    const methods = {
      'MuslimWorldLeague': 'رابطة العالم الإسلامي',
      'Egyptian': 'الهيئة المصرية العامة للمساحة',
      'Karachi': 'جامعة العلوم الإسلامية، كراتشي',
      'UmmAlQura': 'أم القرى',
      'NorthAmerica': 'الجمعية الإسلامية لأمريكا الشمالية',
      'MoonsightingCommittee': 'لجنة رؤية الهلال',
    };

    final current = ref.read(calculationMethodProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.7,
        minChildSize: 0.3,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'طريقة الحساب',
              style: AppTextStyles.arabicHeadline,
              textDirection: TextDirection.rtl,
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                children: methods.entries.map((entry) {
                  return RadioListTile<String>(
                    title: Text(
                      entry.value,
                      style: AppTextStyles.arabicBody,
                      textDirection: TextDirection.rtl,
                    ),
                    value: entry.key,
                    groupValue: current,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(calculationMethodProvider.notifier).state = v;
                      }
                      Navigator.of(context).pop();
                    },
                    activeColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMadhabPicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'المذهب',
              style: AppTextStyles.arabicHeadline,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: Text(
                'الشافعي (المالكي، الحنبلي)',
                style: AppTextStyles.arabicBody,
                textDirection: TextDirection.rtl,
              ),
              subtitle: Text(
                'وقت العصر عندما يصبح ظل كل شيء مثله',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),
              value: 'Shafi',
              groupValue: current,
              onChanged: (v) {
                if (v != null) {
                  ref.read(madhabProvider.notifier).state = v;
                }
                Navigator.of(context).pop();
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<String>(
              title: Text(
                'الحنفي',
                style: AppTextStyles.arabicBody,
                textDirection: TextDirection.rtl,
              ),
              subtitle: Text(
                'وقت العصر عندما يصبح ظل كل شيء مثليه',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),
              value: 'Hanafi',
              groupValue: current,
              onChanged: (v) {
                if (v != null) {
                  ref.read(madhabProvider.notifier).state = v;
                }
                Navigator.of(context).pop();
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: AppTextStyles.arabicCaption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        size: 22,
      ),
      title: Text(
        title,
        style: AppTextStyles.arabicBody,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.arabicCaption.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        textDirection: TextDirection.rtl,
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_left, size: 20)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
