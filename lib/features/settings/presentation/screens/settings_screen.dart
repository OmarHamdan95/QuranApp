import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../main.dart';
import '../../../audio/data/models/reciter_model.dart';
import '../../../audio/presentation/providers/audio_providers.dart';
import '../../../prayer/presentation/providers/prayer_providers.dart';
import '../providers/settings_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Accent color palette
// ─────────────────────────────────────────────────────────────────────────────

const _accentColors = [
  Color(0xFF1B5E20), // Islamic Green (default)
  Color(0xFF00695C), // Teal
  Color(0xFF1565C0), // Royal Blue
  Color(0xFF6A1B9A), // Purple
  Color(0xFFBF8C30), // Gold
  Color(0xFFD84315), // Terracotta
  Color(0xFF37474F), // Slate
];

// ─────────────────────────────────────────────────────────────────────────────
// Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Production-quality settings screen with sections:
/// Appearance, Reading, Audio, Prayer, Notifications, Data, About.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.primary),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: 8,
          bottom: context.bottomPadding + 88,
        ),
        children: [
          // ── APPEARANCE ────────────────────────────────────────────────
          _SectionHeader(title: 'المظهر', icon: Icons.palette_outlined),

          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            iconColor: AppColors.isha,
            title: 'مظهر التطبيق',
            subtitle: _themeModeLabel(settings.themeMode),
            onTap: () => _showThemePicker(context, ref, settings.themeMode),
          ),

          _ColorAccentTile(
            currentColor: settings.accentColor,
            isDark: isDark,
            onColorSelected: (color) {
              ref.read(settingsProvider.notifier).setAccentColor(color);
            },
          ),

          const _SectionDivider(),

          // ── READING ───────────────────────────────────────────────────
          _SectionHeader(title: 'القراءة', icon: Icons.menu_book_outlined),

          _FontSizeTile(
            label: 'حجم خط القرآن',
            value: settings.quranFontSize,
            min: AppConstants.minFontSize,
            max: AppConstants.maxFontSize,
            onChanged: (v) => ref.read(settingsProvider.notifier).setQuranFontSize(v),
          ),

          _FontSizeTile(
            label: 'حجم خط الترجمة',
            value: settings.translationFontSize,
            min: 12,
            max: 28,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setTranslationFontSize(v),
          ),

          _SwitchTile(
            icon: Icons.translate,
            iconColor: AppColors.tertiary,
            title: 'إظهار الترجمة',
            subtitle: 'عرض الترجمة أسفل النص العربي',
            value: settings.showTranslation,
            onChanged: (v) => ref.read(settingsProvider.notifier).setShowTranslation(v),
          ),

          _SettingsTile(
            icon: Icons.font_download_outlined,
            iconColor: AppColors.secondary,
            title: 'خط القرآن',
            subtitle: _fontStyleLabel(settings.quranFontStyle),
            onTap: () => _showFontStylePicker(context, ref, settings.quranFontStyle),
          ),

          _SettingsTile(
            icon: Icons.auto_stories_outlined,
            iconColor: AppColors.dhuhr,
            title: 'طريقة العرض',
            subtitle: _readingModeLabel(settings.readingMode),
            onTap: () => _showReadingModePicker(context, ref, settings.readingMode),
          ),

          const _SectionDivider(),

          // ── AUDIO ──────────────────────────────────────────────────────
          _SectionHeader(title: 'الصوت', icon: Icons.headphones_outlined),

          _SettingsTile(
            icon: Icons.record_voice_over_outlined,
            iconColor: AppColors.asr,
            title: 'القارئ الافتراضي',
            subtitle: ref.watch(selectedReciterProvider).nameArabic,
            onTap: () => _showReciterPicker(context, ref),
          ),

          _SettingsTile(
            icon: Icons.high_quality_outlined,
            iconColor: AppColors.fajr,
            title: 'جودة الصوت',
            subtitle: _audioQualityLabel(settings.audioQuality),
            onTap: () => _showAudioQualityPicker(context, ref, settings.audioQuality),
          ),

          _SwitchTile(
            icon: Icons.skip_next_outlined,
            iconColor: AppColors.tertiary,
            title: 'تشغيل السورة التالية تلقائياً',
            subtitle: 'الانتقال للسورة التالية بعد الانتهاء',
            value: settings.autoPlayNext,
            onChanged: (v) => ref.read(settingsProvider.notifier).setAutoPlayNext(v),
          ),

          const _SectionDivider(),

          // ── PRAYER ────────────────────────────────────────────────────
          _SectionHeader(title: 'الصلاة', icon: Icons.mosque_outlined),

          _SettingsTile(
            icon: Icons.calculate_outlined,
            iconColor: AppColors.primary,
            title: 'طريقة الحساب',
            subtitle: CalculationMethod.fromKey(settings.calculationMethod).labelArabic,
            onTap: () => _showCalculationMethodPicker(context, ref, settings.calculationMethod),
          ),

          _SettingsTile(
            icon: Icons.access_time,
            iconColor: AppColors.secondary,
            title: 'المذهب (وقت العصر)',
            subtitle: Madhab.fromKey(settings.madhab).labelArabic,
            onTap: () => _showMadhabPicker(context, ref, settings.madhab),
          ),

          // Per-prayer adhan toggles
          _PrayerAdhanSection(settings: settings, isDark: isDark),

          const _SectionDivider(),

          // ── NOTIFICATIONS ─────────────────────────────────────────────
          _SectionHeader(title: 'الإشعارات', icon: Icons.notifications_outlined),

          _SwitchTile(
            icon: Icons.wb_sunny_outlined,
            iconColor: AppColors.sunrise,
            title: 'الآية اليومية',
            subtitle: 'إشعار يومي بآية قرآنية',
            value: settings.dailyAyahEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).setDailyAyahEnabled(v),
          ),

          if (settings.dailyAyahEnabled)
            _SettingsTile(
              icon: Icons.schedule_outlined,
              iconColor: AppColors.sunrise,
              title: 'وقت الآية اليومية',
              subtitle: settings.dailyAyahTime.format(context),
              onTap: () => _showTimePicker(context, ref, settings.dailyAyahTime),
            ),

          _SwitchTile(
            icon: Icons.brightness_5_outlined,
            iconColor: AppColors.dhuhr,
            title: 'أذكار الصباح',
            subtitle: 'تذكير بأذكار الصباح',
            value: settings.morningAdhkarEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setMorningAdhkarEnabled(v),
          ),

          _SwitchTile(
            icon: Icons.brightness_3_outlined,
            iconColor: AppColors.isha,
            title: 'أذكار المساء',
            subtitle: 'تذكير بأذكار المساء',
            value: settings.eveningAdhkarEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setEveningAdhkarEnabled(v),
          ),

          const _SectionDivider(),

          // ── DATA ──────────────────────────────────────────────────────
          _SectionHeader(title: 'البيانات', icon: Icons.storage_outlined),

          _SettingsTile(
            icon: Icons.download_outlined,
            iconColor: AppColors.tertiary,
            title: 'إدارة التحميلات',
            subtitle: 'تحميل وحذف الملفات الصوتية',
            onTap: () => context.pushNamed(RouteNames.downloads),
          ),

          _SettingsTile(
            icon: Icons.bookmark_outline,
            iconColor: AppColors.secondary,
            title: 'الإشارات المرجعية',
            subtitle: 'عرض وإدارة الإشارات المرجعية',
            onTap: () => context.pushNamed(RouteNames.bookmarks),
          ),

          Consumer(
            builder: (context, ref, _) {
              final cacheSizeAsync = ref.watch(cacheSizeProvider);
              final sizeLabel = cacheSizeAsync.maybeWhen(
                data: (s) => s,
                orElse: () => 'جاري الحساب...',
              );
              return _SettingsTile(
                icon: Icons.cleaning_services_outlined,
                iconColor: AppColors.warning,
                title: 'مسح ذاكرة التخزين المؤقت',
                subtitle: 'الحجم الحالي: $sizeLabel',
                onTap: () => _confirmClearCache(context, ref),
              );
            },
          ),

          _SettingsTile(
            icon: Icons.restore_outlined,
            iconColor: AppColors.error,
            title: 'إعادة تعيين الإعدادات',
            subtitle: 'استعادة جميع الإعدادات الافتراضية',
            onTap: () => _confirmResetSettings(context, ref),
          ),

          const _SectionDivider(),

          // ── ABOUT ─────────────────────────────────────────────────────
          _SectionHeader(title: 'حول التطبيق', icon: Icons.info_outline),

          _SettingsTile(
            icon: Icons.apps_outlined,
            iconColor: AppColors.primary,
            title: AppConstants.appNameArabic,
            subtitle: 'الإصدار ${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
          ),

          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.info,
            title: 'سياسة الخصوصية',
            subtitle: 'لا إعلانات · لا تتبع · مفتوح المصدر',
            onTap: () {
              // TODO: Launch privacy policy URL
            },
          ),

          _SettingsTile(
            icon: Icons.star_outline,
            iconColor: AppColors.warning,
            title: 'تقييم التطبيق',
            subtitle: 'ادعمنا بتقييمك في المتجر',
            onTap: () {
              // TODO: Launch store review
            },
          ),

          _SettingsTile(
            icon: Icons.share_outlined,
            iconColor: AppColors.tertiary,
            title: 'مشاركة التطبيق',
            subtitle: 'شارك التطبيق مع أصدقائك',
            onTap: () {
              // TODO: Share app link
            },
          ),

          _SettingsTile(
            icon: Icons.code_outlined,
            iconColor: AppColors.textTertiaryLight,
            title: 'الفريق والمساهمون',
            subtitle: 'تعرف على من بنى هذا التطبيق',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: AppConstants.appNameArabic,
                applicationVersion: AppConstants.appVersion,
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Pickers ─────────────────────────────────────────────────────────────

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _BottomSheetHandle(),
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
                  _themeModeLabel(mode),
                  style: AppTextStyles.arabicBody,
                  textDirection: TextDirection.rtl,
                ),
                value: mode,
                groupValue: current,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(v);
                    ref.read(themeModeProvider.notifier).state = v;
                  }
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFontStylePicker(BuildContext context, WidgetRef ref, String current) {
    const styles = {
      'Uthmani': 'عثماني (المصحف الشريف)',
      'IndoPak': 'الباكستاني',
      'Simple': 'مبسط',
    };

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _BottomSheetHandle(),
            const SizedBox(height: 8),
            Text('خط القرآن', style: AppTextStyles.arabicHeadline, textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            for (final entry in styles.entries)
              RadioListTile<String>(
                title: Text(entry.value, style: AppTextStyles.arabicBody, textDirection: TextDirection.rtl),
                value: entry.key,
                groupValue: current,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  if (v != null) ref.read(settingsProvider.notifier).setQuranFontStyle(v);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReadingModePicker(BuildContext context, WidgetRef ref, QuranReadingMode current) {
    const modes = {
      QuranReadingMode.surah: 'حسب السورة',
      QuranReadingMode.mushaf: 'صفحة المصحف',
      QuranReadingMode.juz: 'حسب الجزء',
    };

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _BottomSheetHandle(),
            const SizedBox(height: 8),
            Text('طريقة العرض', style: AppTextStyles.arabicHeadline, textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            for (final entry in modes.entries)
              RadioListTile<QuranReadingMode>(
                title: Text(entry.value, style: AppTextStyles.arabicBody, textDirection: TextDirection.rtl),
                value: entry.key,
                groupValue: current,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  if (v != null) ref.read(settingsProvider.notifier).setReadingMode(v);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReciterPicker(BuildContext context, WidgetRef ref) {
    final reciters = ReciterModel.popularReciters;
    final current = ref.read(selectedReciterProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, controller) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _BottomSheetHandle(),
              const SizedBox(height: 8),
              Text('القارئ الافتراضي', style: AppTextStyles.arabicHeadline, textDirection: TextDirection.rtl),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: reciters.length,
                  itemBuilder: (_, i) {
                    final reciter = reciters[i];
                    return RadioListTile<int>(
                      title: Text(reciter.nameArabic, style: AppTextStyles.arabicBody, textDirection: TextDirection.rtl),
                      subtitle: Text(reciter.style, textDirection: TextDirection.rtl, style: AppTextStyles.arabicCaption.copyWith(color: AppColors.textTertiaryLight)),
                      value: reciter.id,
                      groupValue: current.id,
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(selectedReciterProvider.notifier).state = reciter;
                          ref.read(settingsProvider.notifier).setDefaultReciter(reciter.id);
                        }
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAudioQualityPicker(BuildContext context, WidgetRef ref, String current) {
    const qualities = {
      'low': 'منخفضة (توفير البيانات)',
      'medium': 'متوسطة',
      'high': 'عالية (الافتراضي)',
    };

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _BottomSheetHandle(),
            const SizedBox(height: 8),
            Text('جودة الصوت', style: AppTextStyles.arabicHeadline, textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            for (final entry in qualities.entries)
              RadioListTile<String>(
                title: Text(entry.value, style: AppTextStyles.arabicBody, textDirection: TextDirection.rtl),
                value: entry.key,
                groupValue: current,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  if (v != null) ref.read(settingsProvider.notifier).setAudioQuality(v);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCalculationMethodPicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, controller) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _BottomSheetHandle(),
              const SizedBox(height: 8),
              Text('طريقة الحساب', style: AppTextStyles.arabicHeadline, textDirection: TextDirection.rtl),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    for (final method in CalculationMethod.values)
                      RadioListTile<String>(
                        title: Text(method.labelArabic, style: AppTextStyles.arabicBody, textDirection: TextDirection.rtl),
                        value: method.key,
                        groupValue: current,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          if (v != null) {
                            ref.read(settingsProvider.notifier).setCalculationMethod(v);
                            ref.read(calculationMethodProvider.notifier).state = v;
                          }
                          Navigator.of(ctx).pop();
                        },
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

  void _showMadhabPicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _BottomSheetHandle(),
            const SizedBox(height: 8),
            Text('المذهب', style: AppTextStyles.arabicHeadline, textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            for (final madhab in Madhab.values)
              RadioListTile<String>(
                title: Text(madhab.labelArabic, style: AppTextStyles.arabicBody, textDirection: TextDirection.rtl),
                subtitle: Text(
                  madhab == Madhab.shafi
                      ? 'وقت العصر: ظل مثله'
                      : 'وقت العصر: ظل مثليه',
                  style: AppTextStyles.arabicCaption.copyWith(color: AppColors.textTertiaryLight),
                  textDirection: TextDirection.rtl,
                ),
                value: madhab.key,
                groupValue: current,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).setMadhab(v);
                    ref.read(madhabProvider.notifier).state = v;
                  }
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: 'وقت الآية اليومية',
    );
    if (picked != null) {
      ref.read(settingsProvider.notifier).setDailyAyahTime(picked);
    }
  }

  Future<void> _confirmClearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('مسح ذاكرة التخزين المؤقت', style: AppTextStyles.arabicHeadline, textDirection: TextDirection.rtl),
        content: Text(
          'سيتم حذف ملفات التخزين المؤقت. لن تتأثر بياناتك الشخصية.',
          style: AppTextStyles.arabicBody,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(settingsRepositoryProvider);
      final result = await repo.clearCache();
      result.fold(
        (f) => context.showError('فشل مسح الكاش: ${f.message}'),
        (_) {
          ref.invalidate(cacheSizeProvider);
          context.showSuccess('تم مسح ذاكرة التخزين المؤقت');
        },
      );
    }
  }

  Future<void> _confirmResetSettings(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إعادة تعيين الإعدادات', style: AppTextStyles.arabicHeadline, textDirection: TextDirection.rtl),
        content: Text(
          'سيتم استعادة جميع الإعدادات إلى قيمها الافتراضية. هل أنت متأكد؟',
          style: AppTextStyles.arabicBody,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(settingsProvider.notifier).resetSettings();
      context.showSuccess('تمت إعادة تعيين الإعدادات');
    }
  }

  // ── Label helpers ───────────────────────────────────────────────────────

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'تلقائي (حسب النظام)',
        ThemeMode.light => 'فاتح',
        ThemeMode.dark => 'داكن',
      };

  String _fontStyleLabel(String style) => switch (style) {
        'Uthmani' => 'عثماني (المصحف الشريف)',
        'IndoPak' => 'الباكستاني',
        'Simple' => 'مبسط',
        _ => style,
      };

  String _readingModeLabel(QuranReadingMode mode) => switch (mode) {
        QuranReadingMode.surah => 'حسب السورة',
        QuranReadingMode.mushaf => 'صفحة المصحف',
        QuranReadingMode.juz => 'حسب الجزء',
      };

  String _audioQualityLabel(String quality) => switch (quality) {
        'low' => 'منخفضة',
        'medium' => 'متوسطة',
        'high' => 'عالية',
        _ => quality,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Prayer Adhan Section
// ─────────────────────────────────────────────────────────────────────────────

class _PrayerAdhanSection extends ConsumerWidget {
  final AppSettings settings;
  final bool isDark;

  const _PrayerAdhanSection({required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const prayers = [
      ('Fajr', 'الفجر', Icons.dark_mode_outlined, AppColors.fajr),
      ('Dhuhr', 'الظهر', Icons.wb_sunny, AppColors.dhuhr),
      ('Asr', 'العصر', Icons.wb_twilight, AppColors.asr),
      ('Maghrib', 'المغرب', Icons.nights_stay_outlined, AppColors.maghrib),
      ('Isha', 'العشاء', Icons.nights_stay, AppColors.isha),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'أذان الصلوات',
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        for (final (key, name, icon, color) in prayers)
          _SwitchTile(
            icon: icon,
            iconColor: color,
            title: name,
            subtitle: 'تشغيل الأذان عند دخول وقت $name',
            value: ref.watch(settingsProvider.notifier).getPrayerAdhan(key),
            onChanged: (v) => ref.read(settingsProvider.notifier).setPrayerAdhan(key, v),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 16, color: AppColors.primary),
        ],
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

class _BottomSheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.dividerLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.arabicBody.copyWith(fontSize: 16),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.arabicCaption.copyWith(
          color: AppColors.textTertiaryLight,
          fontSize: 13,
        ),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_left, size: 20) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.arabicBody.copyWith(fontSize: 16),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.arabicCaption.copyWith(
          color: AppColors.textTertiaryLight,
          fontSize: 13,
        ),
        textDirection: TextDirection.rtl,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _FontSizeTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _FontSizeTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                label,
                style: AppTextStyles.arabicBody.copyWith(fontSize: 16),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 2).round(),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withValues(alpha: 0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ColorAccentTile extends StatelessWidget {
  final Color currentColor;
  final bool isDark;
  final ValueChanged<Color> onColorSelected;

  const _ColorAccentTile({
    required this.currentColor,
    required this.isDark,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'لون التمييز',
                style: AppTextStyles.arabicBody.copyWith(fontSize: 16),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: currentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.color_lens_outlined, color: currentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: _accentColors.map((color) {
              // ignore: deprecated_member_use
              final isSelected = color.value == currentColor.value;
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2.5,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
