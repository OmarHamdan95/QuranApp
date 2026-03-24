import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/reciter.dart';
import '../providers/audio_providers.dart';

/// Modal bottom sheet that presents all available reciters in a searchable
/// grid layout. Each card shows the reciter's name, style, country, and
/// selection state.
///
/// Usage:
/// ```dart
/// ReciterSelector.show(context);
/// ```
class ReciterSelector extends ConsumerStatefulWidget {
  const ReciterSelector({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReciterSelector(),
    );
  }

  @override
  ConsumerState<ReciterSelector> createState() => _ReciterSelectorState();
}

class _ReciterSelectorState extends ConsumerState<ReciterSelector> {
  String _searchQuery = '';
  String? _styleFilter; // null = all, 'Murattal', 'Mujawwad'

  @override
  Widget build(BuildContext context) {
    final recitersAsync = ref.watch(recitersProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final isDark = context.isDarkMode;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // ── Handle ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'اختر القارئ',
                      style: AppTextStyles.arabicHeadline.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ── Search bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن قارئ...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textTertiaryLight,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),

              // ── Style filter chips ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: _styleFilter == null,
                      onTap: () => setState(() => _styleFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'مرتّل',
                      selected: _styleFilter == 'Murattal',
                      onTap: () =>
                          setState(() => _styleFilter = 'Murattal'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'مجوّد',
                      selected: _styleFilter == 'Mujawwad',
                      onTap: () =>
                          setState(() => _styleFilter = 'Mujawwad'),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),

              // ── Reciter grid ────────────────────────────────────────
              Expanded(
                child: recitersAsync.when(
                  data: (reciters) {
                    final filtered = _filterReciters(reciters);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: AppTextStyles.arabicBody.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    }
                    return GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final reciter = filtered[index];
                        return _ReciterCard(
                          reciter: reciter,
                          isSelected: reciter.id == selectedReciter.id,
                          isDark: isDark,
                          onTap: () {
                            ref
                                .read(selectedReciterProvider.notifier)
                                .state = reciter;
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تعذّر تحميل قائمة القراء',
                          style: AppTextStyles.arabicBody,
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Reciter> _filterReciters(List<Reciter> reciters) {
    var result = reciters;

    if (_styleFilter != null) {
      result = result.where((r) => r.style == _styleFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where(
            (r) =>
                r.nameArabic.contains(_searchQuery) ||
                r.nameEnglish.toLowerCase().contains(query) ||
                (r.country?.contains(_searchQuery) ?? false),
          )
          .toList();
    }

    return result;
  }
}

// ── ReciterCard ────────────────────────────────────────────────────────────

class _ReciterCard extends StatelessWidget {
  final Reciter reciter;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ReciterCard({
    required this.reciter,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                )
              : null,
          color: isSelected
              ? null
              : (isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Arabic name
              Text(
                reciter.nameArabic,
                style: AppTextStyles.arabicCaption.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                  fontWeight: FontWeight.w700,
                  fontSize: reciter.nameArabic.length > 10 ? 12 : 14,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Style badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reciter.style == 'Mujawwad' ? 'مجوّد' : 'مرتّل',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontSize: 10,
                  ),
                ),
              ),

              if (reciter.country != null) ...[
                const SizedBox(height: 2),
                Text(
                  reciter.country!,
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textTertiaryLight,
                    fontSize: 10,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.arabicCaption.copyWith(
            color: selected ? Colors.white : AppColors.primary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
