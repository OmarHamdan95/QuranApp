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

/// Screen displaying only favourite-starred bookmarks.
///
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
      appBar: AppBar(
        title: Text(
          'المفضلة',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          // Toggle list / grid
          IconButton(
            icon: Icon(
              viewMode == _ViewMode.list
                  ? Icons.grid_view_rounded
                  : Icons.view_list_rounded,
            ),
            tooltip: viewMode == _ViewMode.list ? 'عرض شبكي' : 'عرض قائمة',
            onPressed: () {
              ref.read(_viewModeProvider.notifier).state =
                  viewMode == _ViewMode.list ? _ViewMode.grid : _ViewMode.list;
            },
          ),
        ],
      ),
      body: favorites.isEmpty
          ? _EmptyState(isDark: isDark)
          : viewMode == _ViewMode.list
              ? _ListView(favorites: favorites, isDark: isDark, ref: ref)
              : _GridView(favorites: favorites, isDark: isDark, ref: ref),
    );
  }
}

// ── List view ─────────────────────────────────────────────────────────────────

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
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 72, endIndent: 16),
      itemBuilder: (context, index) {
        final bookmark = favorites[index];
        return Dismissible(
          key: ValueKey('fav-${bookmark.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            color: AppColors.secondary.withValues(alpha: 0.9),
            child: const Icon(Icons.favorite_border, color: Colors.white),
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
            onTap: () => _navigateToReader(context, bookmark),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
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
      title: Text(
        bookmark.surahName,
        style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            bookmark.ayahText,
            style: AppTextStyles.quranAyah.copyWith(
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
          const SizedBox(height: 2),
          Text(
            'آية ${bookmark.ayahNumber}  •  صفحة ${bookmark.page}',
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
              fontSize: 12,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: AppColors.error, size: 22),
        tooltip: 'إزالة من المفضلة',
        onPressed: onUnfavorite,
      ),
    );
  }
}

// ── Grid view ─────────────────────────────────────────────────────────────────

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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          onTap: () => _navigateToReader(context, bookmark),
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
    return Card(
      elevation: isDark ? 0 : 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Surah name + unfavorite ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onUnfavorite,
                    child: const Icon(
                      Icons.favorite,
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
                      ),
                      textDirection: TextDirection.rtl,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'آية ${bookmark.ayahNumber}',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),

              const Divider(height: 16),

              // ── Ayah preview ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.quranPageBackgroundDark
                        : AppColors.quranPageBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bookmark.ayahText,
                    style: AppTextStyles.quranAyah.copyWith(
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

              // ── Quick play button ──
              SizedBox(
                width: double.infinity,
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed(
                      RouteNames.audioPlayer,
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: Text(
                    'استمع',
                    style: AppTextStyles.arabicCaption.copyWith(
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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

// ── Navigation helper ─────────────────────────────────────────────────────────

void _navigateToReader(BuildContext context, Bookmark bookmark) {
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

// ── Empty state ───────────────────────────────────────────────────────────────

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
            Icon(
              Icons.favorite_outline,
              size: 72,
              color: AppColors.error.withValues(alpha: 0.3),
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
