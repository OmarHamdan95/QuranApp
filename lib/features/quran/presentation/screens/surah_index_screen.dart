import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/quran_providers.dart';
import '../widgets/surah_list_tile.dart';

/// Screen showing the list of all 114 surahs.
///
/// Supports search filtering and switching between surah/juz views.
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        titleTextStyle: AppTextStyles.arabicHeadline.copyWith(
          color: AppColors.primary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.arabicBody,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة...',
                hintStyle: AppTextStyles.arabicCaption,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              textDirection: TextDirection.rtl,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Tab content
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

/// Surah list tab showing all surahs with search filtering.
class _SurahListTab extends ConsumerWidget {
  final String searchQuery;

  const _SurahListTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);

    return surahsAsync.when(
      data: (surahs) {
        final filtered = searchQuery.isEmpty
            ? surahs
            : surahs.where((s) {
                final q = searchQuery.toLowerCase();
                return s.nameArabic.contains(searchQuery) ||
                    s.nameEnglish.toLowerCase().contains(q) ||
                    s.nameTranslation.toLowerCase().contains(q) ||
                    s.number.toString() == searchQuery;
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: AppColors.textTertiaryLight),
                const SizedBox(height: 12),
                Text(
                  'لم يتم العثور على نتائج',
                  style: AppTextStyles.arabicBody.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            return SurahListTile(surah: filtered[index]);
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Error loading surahs: $error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(surahsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Juz list tab showing 30 juz entries.
class _JuzListTab extends StatelessWidget {
  const _JuzListTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: 30,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              juzNumber.toString(),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            'الجزء $juzNumber',
            style: AppTextStyles.arabicBody,
            textDirection: TextDirection.rtl,
          ),
          onTap: () => context.pushNamed(RouteNames.juzIndex),
        );
      },
    );
  }
}
