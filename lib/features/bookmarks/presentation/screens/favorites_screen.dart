import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bookmark_providers.dart';

/// View mode for the favorites screen (list or grid).
enum _ViewMode { list, grid }

final _viewModeProvider = StateProvider<_ViewMode>((_) => _ViewMode.list);

/// Screen displaying only favourite-starred bookmarks with modern design.
/// Supports toggle between list and grid views, swipe-to-unfavourite,
/// and a quick "jump to reader" action.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final viewMode = ref.watch(_viewModeProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'المفضلة',
          style: AppTextStyles.arabicBody.copyWith(
            color: AppColors.primary,
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
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                viewMode == _ViewMode.list
                    ? Icons.grid_view_rounded
                    : Icons.view_list_rounded,
                size: 18,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            tooltip:
                viewMode == _ViewMode.list ? 'عرض شبكي' : 'عرض قائمة',
            onPressed: () {
              ref.read(_viewModeProvider.notifier).state =
                  viewMode == _ViewMode.list
                      ? _ViewMode.grid
                      : _ViewMode.list;
            },
          ),
        ],
      ),
      body: favorites.isEmpty
          ? _EmptyState(isDark: isDark)
          : viewMode == _ViewMode.list
              ? _ListView(
                  favorites: favorites, isDark: isDark, ref: ref)
              : _GridView(
                  favorites: favorites, isDark: isDark, ref: ref),
    );
  }
}

// ── List view ────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<Bookmark> favorites;
  final bool isDark;
  final WidgetRef ref;

  const _ListView({
    required this.favorites,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final bookmark = favorites[index];
        return Dismissible(
          key: ValueKey('fav-${bookmark.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.favorite_border_rounded,
                color: Colors.white),
          ),
          onDismissed: (_) {
            ref
                .read(bookmarkListProvider.notifier)
                .toggleFavorite(bookmark.id);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم إزالة "${bookmark.surahName}" من المفضلة',
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                action: SnackBarAction(
                  label: 'تراجع',
                  onPressed: () {
                    ref
                        .read(bookmarkListProvider.notifier)
                        .toggleFavorite(bookmark.id);
                  },
                ),
              ),
            );
          },
          child: _FavoriteListTile(
            bookmark: bookmark,
            isDark: isDark,
            onTap: () =>
                _navigateToReader(context, bookmark),
            onUnfavorite: () => ref
                .read(bookmarkListProvider.notifier)
                .toggleFavorite(bookmark.id),
          ),
        );
      },
    );
  }
}

class _FavoriteListTile extends StatelessWidget {
  final Bookmark bookmark;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  const _FavoriteListTile({
    required this.bookmark,
    required this.isDark,
    required this.onTap,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.dividerDark
              : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Surah number badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${bookmark.surahNumber}',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bookmark.surahName,
                      style: AppTextStyles.arabicBody.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookmark.ayahText,
                      style:
                          AppTextStyles.quranAyah.copyWith(
                        fontSize: 15,
                        height: 1.7,
                        color: isDark
                            ? AppColors.quranTextColorDark
                            : AppColors.quranTextColor,
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'آية ${bookmark.ayahNumber}  ·  صفحة ${bookmark.page}',
                      style:
                          AppTextStyles.arabicCaption.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                        fontSize: 11,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.favorite_rounded,
                    color: AppColors.error, size: 22),
                tooltip: 'إزالة من المفضلة',
                onPressed: onUnfavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Grid view ────────────────────────────────────────────────────────────────

class _GridView extends StatelessWidget {
  final List<Bookmark> favorites;
  final bool isDark;
  final WidgetRef ref;

  const _GridView({
    required this.favorites,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final bookmark = favorites[index];
        return _FavoriteGridCard(
          bookmark: bookmark,
          isDark: isDark,
          onTap: () =>
              _navigateToReader(context, bookmark),
          onUnfavorite: () => ref
              .read(bookmarkListProvider.notifier)
              .toggleFavorite(bookmark.id),
        );
      },
    );
  }
}

class _FavoriteGridCard extends StatelessWidget {
  final Bookmark bookmark;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  const _FavoriteGridCard({
    required this.bookmark,
    required this.isDark,
    required this.onTap,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.dividerDark
              : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Surah name + unfavorite
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onUnfavorite,
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      bookmark.surahName,
                      style: AppTextStyles.arabicBody.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'آية ${bookmark.ayahNumber}',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontSize: 12,
                ),
                textDirection: TextDirection.rtl,
              ),
              Divider(
                height: 16,
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
              ),
              // Ayah preview
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.quranPageBackgroundDark
                        : AppColors.quranPageBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bookmark.ayahText,
                    style:
                        AppTextStyles.quranAyah.copyWith(
                      fontSize: 15,
                      height: 1.8,
                      color: isDark
                          ? AppColors.quranTextColorDark
                          : AppColors.quranTextColor,
                    ),
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Quick play button
              SizedBox(
                width: double.infinity,
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed(RouteNames.audioPlayer);
                  },
                  icon: const Icon(Icons.play_arrow_rounded,
                      size: 16),
                  label: Text(
                    'استمع',
                    style:
                        AppTextStyles.arabicCaption.copyWith(
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                        color: AppColors.primary, width: 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Navigation helper ────────────────────────────────────────────────────────

void _navigateToReader(
    BuildContext context, Bookmark bookmark) {
  context.pushNamed(
    RouteNames.quranReader,
    pathParameters: {
      'surahNumber': bookmark.surahNumber.toString(),
    },
    queryParameters: {
      'ayah': bookmark.ayahNumber.toString(),
    },
  );
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 40,
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد آيات مفضلة',
              style: AppTextStyles.arabicBody.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'اضغط على أيقونة القلب في أي إشارة مرجعية لإضافتها هنا',
              style: AppTextStyles.arabicCaption.copyWith(
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
