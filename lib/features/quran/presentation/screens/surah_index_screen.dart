import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_app/core/extensions/context_extensions.dart';
import 'package:quran_app/core/routing/app_router.dart';
import 'package:quran_app/core/theme/app_colors.dart';
import 'package:quran_app/core/theme/app_text_styles.dart';
import 'package:quran_app/shared/widgets/loading_widget.dart';
import 'package:quran_app/features/quran/presentation/providers/quran_providers.dart';
import 'package:quran_app/features/quran/presentation/widgets/surah_list_tile.dart';

/// Screen showing the list of all 114 surahs with modern design.
///
/// Features:
/// - Elegant header with app title
/// - Real-time search filtering (Arabic name, English name, number)
/// - Makki / Madani filter chips
/// - Tab bar to switch between surah list and juz index
/// - Card-style surah tiles with smooth animations
class SurahIndexScreen extends ConsumerStatefulWidget {
  const SurahIndexScreen({super.key});

  @override
  ConsumerState<SurahIndexScreen> createState() => _SurahIndexScreenState();
}

class _SurahIndexScreenState extends ConsumerState<SurahIndexScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // -- Modern SliverAppBar --
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              surfaceTintColor: Colors.transparent,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 60),
                title: Text(
                  'القرآن الكريم',
                  style: AppTextStyles.arabicHeadline.copyWith(
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    fontSize: 22,
                  ),
                ),
                centerTitle: true,
              ),
              actions: [
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      _isSearchExpanded
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      key: ValueKey(_isSearchExpanded),
                      size: 22,
                    ),
                  ),
                  tooltip: 'بحث',
                  onPressed: _toggleSearch,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                IconButton(
                  icon: const Icon(Icons.manage_search_rounded, size: 22),
                  tooltip: 'بحث متقدم في القرآن',
                  onPressed: () => context.pushNamed(RouteNames.search),
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'السور'),
                      Tab(text: 'الأجزاء'),
                    ],
                    labelColor: isDark ? AppColors.primaryLight : AppColors.primary,
                    unselectedLabelColor: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                    indicatorColor: isDark ? AppColors.primaryLight : AppColors.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: AppTextStyles.arabicBody.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // -- Animated Search Bar --
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _isSearchExpanded
                  ? _ModernSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onClear: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      hasText: _searchQuery.isNotEmpty,
                      isDark: isDark,
                    )
                  : const SizedBox.shrink(),
            ),

            // -- Filter Chips (only on surah tab) --
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index != 0) return const SizedBox.shrink();
                return _FilterChipsRow(isDark: isDark);
              },
            ),

            // -- Tab Content --
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
      ),
    );
  }
}

// -- Modern Search Bar --

class _ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;
  final bool isDark;

  const _ModernSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'ابحث باسم السورة أو رقمها...',
            hintStyle: AppTextStyles.arabicCaption.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: onClear,
                    tooltip: 'مسح',
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          textDirection: TextDirection.rtl,
          style: AppTextStyles.arabicBody.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontSize: 15,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// -- Filter Chips --

class _FilterChipsRow extends ConsumerWidget {
  final bool isDark;

  const _FilterChipsRow({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(surahFilterProvider);

    return Padding(
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
            icon: Icons.location_city_rounded,
            isSelected: currentFilter == SurahFilter.meccan,
            color: AppColors.secondary,
            onTap: () =>
                ref.read(surahFilterProvider.notifier).state =
                    SurahFilter.meccan,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'مدنية',
            icon: Icons.mosque_rounded,
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
  final IconData? icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.25),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.arabicCaption.copyWith(
                  color: isSelected ? Colors.white : color,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Surah List Tab --

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

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return SurahListTile(surah: filtered[index]);
          },
        );
      },
      loading: () => const LoadingWidget(message: 'جاري تحميل السور...'),
      error: (error, stack) => _ErrorState(
        message: 'تعذّر تحميل قائمة السور',
        onRetry: () => ref.invalidate(surahsProvider),
      ),
    );
  }
}

// -- Juz List Tab --

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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        final juzName = _juzNames[index];
        final startSurah = _juzStartSurah[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Material(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            elevation: isDark ? 0 : 0.5,
            shadowColor: AppColors.secondary.withValues(alpha: 0.1),
            child: InkWell(
              onTap: () {
                context.pushNamed(RouteNames.juzIndex);
              },
              borderRadius: BorderRadius.circular(16),
              splashColor: AppColors.secondary.withValues(alpha: 0.06),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark.withValues(alpha: 0.3)
                        : AppColors.borderLight.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    // -- Juz Number Badge --
                    _JuzBadge(juzNumber: juzNumber, isDark: isDark),
                    const SizedBox(width: 16),

                    // -- Juz Info --
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
                          const SizedBox(height: 3),
                          Text(
                            juzName,
                            style: AppTextStyles.arabicCaption.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                              fontSize: 13,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // -- Surah Start Info --
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'سورة $startSurah',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(width: 6),
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
            ),
          ),
        );
      },
    );
  }
}

class _JuzBadge extends StatelessWidget {
  final int juzNumber;
  final bool isDark;

  const _JuzBadge({required this.juzNumber, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: isDark ? 0.25 : 0.15),
            AppColors.secondary.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        juzNumber.toString(),
        style: AppTextStyles.labelLarge.copyWith(
          color: isDark ? AppColors.secondaryLight : AppColors.secondary,
          fontWeight: FontWeight.w800,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }
}

// -- Shared Empty & Error States --

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: AppTextStyles.arabicBody.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final isDark = context.isDarkMode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: AppTextStyles.arabicBody.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
