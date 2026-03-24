import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../quran/domain/entities/ayah.dart';
import '../../../quran/domain/entities/surah.dart';
import '../../domain/repositories/search_repository.dart';
import '../providers/search_providers.dart';

/// Full-screen Quran search with:
/// - Arabic RTL input with debounce.
/// - Recent searches history.
/// - Toggle between Ayah and Surah scope.
/// - Filter panel (by surah / juz / page).
/// - Highlighted matches in result text.
/// - Tap to navigate to the Quran reader.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = value;
      }
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).state = value;
    if (value.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).addSearch(value.trim());
    }
    context.unfocus();
  }

  void _selectSuggestion(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _submitSearch(query);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final showFilter = ref.watch(showSearchFilterProvider);
    final scope = ref.watch(searchScopeProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _SearchBar(
          controller: _controller,
          focusNode: _focusNode,
          query: query,
          onChanged: _onQueryChanged,
          onSubmitted: _submitSearch,
          onClear: _clear,
        ),
        actions: [
          // Scope toggle
          IconButton(
            icon: Icon(
              scope == SearchScope.ayahs
                  ? Icons.format_list_bulleted
                  : Icons.menu_book,
              size: 22,
            ),
            tooltip: scope == SearchScope.ayahs
                ? 'البحث في السور'
                : 'البحث في الآيات',
            onPressed: () {
              ref.read(searchScopeProvider.notifier).state =
                  scope == SearchScope.ayahs
                      ? SearchScope.surahs
                      : SearchScope.ayahs;
            },
          ),
          // Filter toggle (only for ayah scope)
          if (scope == SearchScope.ayahs)
            IconButton(
              icon: Icon(
                Icons.filter_list,
                size: 22,
                color: showFilter ? AppColors.secondary : null,
              ),
              tooltip: 'تصفية النتائج',
              onPressed: () => ref
                  .read(showSearchFilterProvider.notifier)
                  .state = !showFilter,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Filter panel ──
          if (showFilter && scope == SearchScope.ayahs)
            _FilterPanel(
              filter: ref.watch(searchFilterProvider),
              onFilterChanged: (f) =>
                  ref.read(searchFilterProvider.notifier).state = f,
            ),

          // ── Scope tabs ──
          if (query.isNotEmpty)
            _ScopeTabs(
              scope: scope,
              onSelect: (s) =>
                  ref.read(searchScopeProvider.notifier).state = s,
            ),

          // ── Body ──
          Expanded(
            child: query.isEmpty
                ? _SuggestionsView(
                    isDark: isDark,
                    onSelect: _selectSuggestion,
                    onClearRecent: () =>
                        ref.read(recentSearchesProvider.notifier).clearAll(),
                    onRemoveRecent: (q) => ref
                        .read(recentSearchesProvider.notifier)
                        .remove(q),
                  )
                : scope == SearchScope.ayahs
                    ? _AyahResults(query: query)
                    : _SurahResults(query: query),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textDirection: TextDirection.rtl,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث في القرآن الكريم...',
        hintStyle: AppTextStyles.arabicCaption.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        fillColor: Colors.transparent,
        filled: false,
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              )
            : const Icon(Icons.search, size: 22),
      ),
      style: AppTextStyles.arabicBody,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

// ── Scope tabs ────────────────────────────────────────────────────────────────

class _ScopeTabs extends StatelessWidget {
  final SearchScope scope;
  final ValueChanged<SearchScope> onSelect;

  const _ScopeTabs({required this.scope, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerLight.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'الآيات',
            selected: scope == SearchScope.ayahs,
            onTap: () => onSelect(SearchScope.ayahs),
          ),
          _Tab(
            label: 'السور',
            selected: scope == SearchScope.surahs,
            onTap: () => onSelect(SearchScope.surahs),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.arabicBody.copyWith(
              color: selected
                  ? AppColors.primary
                  : AppColors.textTertiaryLight,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

// ── Filter panel ──────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final SearchFilter filter;
  final ValueChanged<SearchFilter> onFilterChanged;

  const _FilterPanel({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: AppColors.surfaceVariantLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'تصفية النتائج',
            style: AppTextStyles.arabicCaption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Surah filter chip
              _FilterChip(
                label: filter.surahNumber != null
                    ? 'سورة ${filter.surahNumber}'
                    : 'كل السور',
                active: filter.surahNumber != null,
                onTap: () => _showSurahPicker(context),
                onClear: () =>
                    onFilterChanged(filter.copyWith(surahNumber: null)),
              ),
              const SizedBox(width: 8),
              // Juz filter chip
              _FilterChip(
                label: filter.juzNumber != null
                    ? 'الجزء ${filter.juzNumber}'
                    : 'كل الأجزاء',
                active: filter.juzNumber != null,
                onTap: () => _showJuzPicker(context),
                onClear: () =>
                    onFilterChanged(filter.copyWith(juzNumber: null)),
              ),
              const SizedBox(width: 8),
              // Reset all
              if (filter.hasActiveFilters)
                TextButton(
                  onPressed: () => onFilterChanged(const SearchFilter()),
                  child: Text(
                    'مسح الكل',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSurahPicker(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'اختر السورة',
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
          textDirection: TextDirection.rtl,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 114,
            itemBuilder: (_, i) => ListTile(
              title: Text(
                'سورة ${i + 1}',
                style: AppTextStyles.arabicCaption,
                textDirection: TextDirection.rtl,
              ),
              onTap: () => Navigator.of(ctx).pop(i + 1),
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      onFilterChanged(filter.copyWith(surahNumber: result));
    }
  }

  Future<void> _showJuzPicker(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'اختر الجزء',
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
          textDirection: TextDirection.rtl,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 30,
            itemBuilder: (_, i) => ListTile(
              title: Text(
                'الجزء ${i + 1}',
                style: AppTextStyles.arabicCaption,
                textDirection: TextDirection.rtl,
              ),
              onTap: () => Navigator.of(ctx).pop(i + 1),
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      onFilterChanged(filter.copyWith(juzNumber: result));
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              label,
              style: AppTextStyles.arabicCaption.copyWith(
                color: active ? AppColors.primary : AppColors.textSecondaryLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Suggestions / recent searches ────────────────────────────────────────────

class _SuggestionsView extends ConsumerWidget {
  final bool isDark;
  final ValueChanged<String> onSelect;
  final VoidCallback onClearRecent;
  final ValueChanged<String> onRemoveRecent;

  static const _staticSuggestions = [
    'الفاتحة',
    'آية الكرسي',
    'سورة يس',
    'سورة الملك',
    'الرحمن',
    'سورة الكهف',
    'قل هو الله أحد',
    'سورة الواقعة',
  ];

  const _SuggestionsView({
    required this.isDark,
    required this.onSelect,
    required this.onClearRecent,
    required this.onRemoveRecent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSearches = ref.watch(recentSearchesProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Recent searches ──
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onClearRecent,
                child: Text(
                  'مسح الكل',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'عمليات البحث الأخيرة',
                style: AppTextStyles.arabicBody.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentSearches.take(8).map(
                (q) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => onSelect(q),
                  leading: const Icon(
                    Icons.history,
                    size: 18,
                    color: AppColors.textTertiaryLight,
                  ),
                  title: Text(
                    q,
                    style: AppTextStyles.arabicBody.copyWith(fontSize: 16),
                    textDirection: TextDirection.rtl,
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textTertiaryLight,
                    ),
                    onPressed: () => onRemoveRecent(q),
                  ),
                ),
              ),
          const Divider(height: 24),
        ],

        // ── Popular searches ──
        Text(
          'بحث مقترح',
          style: AppTextStyles.arabicBody.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          textDirection: TextDirection.rtl,
          children: _staticSuggestions
              .map(
                (s) => ActionChip(
                  label: Text(
                    s,
                    style: AppTextStyles.arabicCaption,
                  ),
                  avatar: const Icon(
                    Icons.search,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  onPressed: () => onSelect(s),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Ayah results ──────────────────────────────────────────────────────────────

class _AyahResults extends ConsumerWidget {
  final String query;

  const _AyahResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (ayahs) {
        if (ayahs.isEmpty) {
          return _EmptyResults(
            message: 'لم يتم العثور على نتائج لـ"$query"',
          );
        }

        return Column(
          children: [
            // Result count
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'نتائج البحث: ${ayahs.length} آية',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: ayahs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final ayah = ayahs[index];
                  return _AyahResultTile(
                    ayah: ayah,
                    query: query,
                    onTap: () => context.pushNamed(
                      RouteNames.quranReader,
                      pathParameters: {
                        'surahNumber': ayah.surahNumber.toString(),
                      },
                      queryParameters: {
                        'ayah': ayah.ayahNumber.toString(),
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Ayah result tile ──────────────────────────────────────────────────────────

class _AyahResultTile extends StatelessWidget {
  final Ayah ayah;
  final String query;
  final VoidCallback onTap;

  const _AyahResultTile({
    required this.ayah,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Reference row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'صفحة ${ayah.page}  •  الجزء ${ayah.juz}',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ayah.surahNumber}:${ayah.ayahNumber}',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Highlighted ayah text
            _HighlightedText(
              text: ayah.textUthmani,
              query: query,
              baseStyle: AppTextStyles.quranAyah.copyWith(
                fontSize: 18,
                height: 1.7,
                color: isDark
                    ? AppColors.quranTextColorDark
                    : AppColors.quranTextColor,
              ),
              highlightStyle: AppTextStyles.quranAyah.copyWith(
                fontSize: 18,
                height: 1.7,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              ),
              textDirection: TextDirection.rtl,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Highlighted text widget ───────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;
  final TextDirection textDirection;
  final int? maxLines;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
    required this.textDirection,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow:
            maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      );
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    int start = 0;

    while (true) {
      final idx = lower.indexOf(queryLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: highlightStyle,
        ),
      );
      start = idx + query.length;
    }

    return Text.rich(
      TextSpan(children: spans, style: baseStyle),
      textDirection: textDirection,
      maxLines: maxLines,
      overflow:
          maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}

// ── Surah results ─────────────────────────────────────────────────────────────

class _SurahResults extends ConsumerWidget {
  final String query;

  const _SurahResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(surahSearchResultsProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (surahs) {
        if (surahs.isEmpty) {
          return _EmptyResults(
            message: 'لم يتم العثور على سور مطابقة لـ"$query"',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: surahs.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72, endIndent: 16),
          itemBuilder: (context, index) {
            final surah = surahs[index];
            return _SurahResultTile(
              surah: surah,
              onTap: () => context.pushNamed(
                RouteNames.quranReader,
                pathParameters: {
                  'surahNumber': surah.number.toString(),
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _SurahResultTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const _SurahResultTile({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '${surah.number}',
            style: AppTextStyles.arabicBody.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      title: Text(
        surah.nameArabic,
        style: AppTextStyles.arabicBody.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        '${surah.nameEnglish}  •  ${surah.ayahCount} آية  •  ${surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}',
        style: AppTextStyles.arabicCaption.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        textDirection: TextDirection.rtl,
      ),
      trailing: const Icon(
        Icons.arrow_back_ios,
        size: 14,
        color: AppColors.textTertiaryLight,
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyResults extends StatelessWidget {
  final String message;

  const _EmptyResults({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
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
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'حدث خطأ أثناء البحث',
              style: AppTextStyles.arabicBody.copyWith(
                color: AppColors.error,
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
