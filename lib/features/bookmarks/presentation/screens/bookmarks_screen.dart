import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/bookmark_providers.dart';

/// Screen showing all user bookmarks with sorting and filtering options.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkListProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإشارات المرجعية',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () => context.pushNamed(RouteNames.favorites),
            tooltip: 'المفضلة',
          ),
        ],
      ),
      body: bookmarks.isEmpty
          ? _EmptyState(isDark: isDark)
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return Dismissible(
                  key: ValueKey(bookmark.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    color: AppColors.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(bookmarkListProvider.notifier).removeBookmark(bookmark.id);
                    context.showSnackBar('تم حذف الإشارة المرجعية');
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: () {
                        context.pushNamed(
                          RouteNames.quranReader,
                          pathParameters: {
                            'surahNumber': bookmark.surahNumber.toString(),
                          },
                          queryParameters: {
                            'ayah': bookmark.ayahNumber.toString(),
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _bookmarkColorToColor(bookmark.color),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bookmark.surahName,
                                        style: AppTextStyles.arabicBody.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                      Text(
                                        'آية ${bookmark.ayahNumber} - صفحة ${bookmark.page}',
                                        style: AppTextStyles.arabicCaption.copyWith(
                                          color: AppColors.textTertiaryLight,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    bookmark.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                    color: bookmark.isFavorite
                                        ? AppColors.error
                                        : AppColors.textTertiaryLight,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(bookmarkListProvider.notifier)
                                        .toggleFavorite(bookmark.id);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bookmark.ayahText,
                              style: AppTextStyles.quranAyah.copyWith(
                                fontSize: 18,
                                height: 1.6,
                              ),
                              textDirection: TextDirection.rtl,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariantLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  bookmark.note!,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _bookmarkColorToColor(dynamic color) {
    // Handle the BookmarkColor enum
    switch (color.toString()) {
      case 'BookmarkColor.blue':
        return AppColors.info;
      case 'BookmarkColor.red':
        return AppColors.error;
      case 'BookmarkColor.yellow':
        return AppColors.warning;
      case 'BookmarkColor.purple':
        return const Color(0xFF7B1FA2);
      case 'BookmarkColor.green':
      default:
        return AppColors.primary;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: AppColors.textTertiaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشارات مرجعية',
              style: AppTextStyles.arabicBody.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'أضف إشارات مرجعية أثناء القراءة للوصول السريع',
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
