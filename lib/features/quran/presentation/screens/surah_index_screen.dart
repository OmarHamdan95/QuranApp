import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/surah.dart';
import '../providers/quran_providers.dart';
import '../widgets/surah_list_tile.dart';

/// Screen showing the list of all 114 surahs.
///
/// Features:
/// - Real-time search filtering (Arabic name, English name, number)
/// - Makki / Madani filter chips
/// - Tab bar to switch between surah list and juz index
class SurahIndexScreen extends ConsumerStatefulWidget {
  const SurahIndexScreen({super.key});

  @override
  ConsumerState<SurahIndexScreen> createState() => _SurahIndexScreenState();
}

class _SurahIndexScreenState extends ConsumerState<SurahIndexScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'القرآن الكريم',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'بحث في القرآن',
            onPressed: () => context.pushNamed(RouteNames.search),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'السور'),
            Tab(text: 'الأجزاء'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiaryLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.arabicBody.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppTextStyles.arabicBody,
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────────────
          _SearchBar(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            hasText: _searchQuery.isNotEmpty,
          ),

          // ── Filter Chips (only shown on surah tab) ────────────────────
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index != 0) return const SizedBox.shrink();
              return _FilterChipsRow(isDark: isDark);
            },
          ),

          // ── Tab Content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SurahListTab(searchQuery: _searchQuery),
                const _JuzListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'ابحث باسم السورة أو رقمها...',
          hintStyle: AppTextStyles.arabicCaption.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                  tooltip: 'مسح',
                )
              : null,
          filled: true,
          fillColor: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
      ),
    );
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────

class _FilterChipsRow extends ConsumerWidget {
  final bool isDark;

  const _FilterChipsRow({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(surahFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _FilterChip(
            label: 'الكل',
            isSelected: currentFilter == SurahFilter.all,
            onTap: () =>
                ref.read(surahFilterProvider.notifier).state =
                    SurahFilter.all,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'مكية',
            isSelected: currentFilter == SurahFilter.meccan,
            color: AppColors.secondary,
            onTap: () =>
                ref.read(surahFilterProvider.notifier).state =
                    SurahFilter.meccan,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'مدنية',
            isSelected: currentFilter == SurahFilter.medinan,
            color: AppColors.tertiary,
            onTap: () =>
                ref.read(surahFilterProvider.notifier).state =
                    SurahFilter.medinan,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.arabicCaption.copyWith(
              color: isSelected ? Colors.white : color,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Surah List Tab ────────────────────────────────────────────────────────────

class _SurahListTab extends ConsumerWidget {
  final String searchQuery;

  const _SurahListTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);
    final filter = ref.watch(surahFilterProvider);

    return surahsAsync.when(
      data: (surahs) {
        // Apply revelation-type filter.
        var filtered = switch (filter) {
          SurahFilter.meccan =>
            surahs.where((s) => s.isMeccan).toList(),
          SurahFilter.medinan =>
            surahs.where((s) => s.isMedinan).toList(),
          SurahFilter.all => surahs,
        };

        // Apply text search.
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          filtered = filtered.where((s) {
            return s.nameArabic.contains(searchQuery) ||
                s.nameEnglish.toLowerCase().contains(q) ||
                s.nameTranslation.toLowerCase().contains(q) ||
                s.number.toString() == searchQuery.trim();
          }).toList();
        }

        if (filtered.isEmpty) {
          return _EmptyState(
            message: searchQuery.isNotEmpty
                ? 'لم يتم العثور على "$searchQuery"'
                : 'لا توجد سور',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 100),
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 76, endIndent: 16),
          itemBuilder: (context, index) {
            return SurahListTile(surah: filtered[index]);
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => _ErrorState(
        message: 'تعذّر تحميل قائمة السور',
        onRetry: () => ref.invalidate(surahsProvider),
      ),
    );
  }
}

// ── Juz List Tab ──────────────────────────────────────────────────────────────

/// Names of the 30 juz first ayahs (opening words).
const _juzNames = <String>[
  'آلم', 'سَيَقُولُ', 'تِلْكَ الرُّسُلُ', 'لَنْ تَنَالُوا',
  'وَالْمُحْصَنَاتُ', 'لَا يُحِبُّ اللَّهُ', 'وَإِذَا سَمِعُوا',
  'وَلَوْ أَنَّنَا', 'قَالَ الْمَلَأُ', 'وَاعْلَمُوا',
  'يَعْتَذِرُونَ', 'وَمَا مِنْ دَابَّةٍ', 'وَمَا أُبَرِّئُ',
  'رُبَمَا', 'سُبْحَانَ الَّذِي', 'قَالَ أَلَمْ',
  'اقْتَرَبَ', 'قَدْ أَفْلَحَ', 'وَقَالَ الَّذِينَ',
  'أَمَّنْ خَلَقَ', 'اتْلُ مَا أُوحِيَ', 'وَمَنْ يَقْنُتْ',
  'وَمَا لِيَ', 'فَمَنْ أَظْلَمُ', 'إِلَيْهِ يُرَدُّ',
  'حم', 'قَالَ فَمَا خَطْبُكُمْ', 'قَدْ سَمِعَ اللَّهُ',
  'تَبَارَكَ الَّذِي', 'عَمَّ',
];

/// Starting surah for each juz (approximate).
const _juzStartSurah = <int>[
  1, 2, 2, 3, 4, 4, 5, 6, 7, 8, 9, 11, 12, 15, 17, 18, 21, 23, 25, 27,
  29, 33, 36, 39, 41, 46, 51, 58, 67, 78,
];

class _JuzListTab extends ConsumerWidget {
  const _JuzListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: 30,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 76, endIndent: 16),
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        final juzName = _juzNames[index];
        final startSurah = _juzStartSurah[index];

        return InkWell(
          onTap: () {
            // Navigate to juz reader / ayah list for the juz.
            context.pushNamed(RouteNames.juzIndex);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Juz Number Badge ──────────────────────────────────
                _JuzBadge(juzNumber: juzNumber),
                const SizedBox(width: 16),

                // ── Juz Info ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الجزء ${juzNumber.toString().toArabicNumerals}',
                        style: AppTextStyles.arabicBody.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        juzName,
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

                // ── Surah Start Info ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'سورة $startSurah',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontFamily: 'Amiri',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JuzBadge extends StatelessWidget {
  final int juzNumber;

  const _JuzBadge({required this.juzNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.2),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        juzNumber.toString(),
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w800,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }
}

// ── Shared Empty & Error States ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textTertiaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.arabicBody.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.arabicBody.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
