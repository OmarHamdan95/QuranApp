import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/bookmark_providers.dart';

/// Screen showing only favorite (starred) bookmarks.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المفضلة',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_outline,
                    size: 64,
                    color: AppColors.textTertiaryLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد آيات مفضلة',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على أيقونة القلب لإضافة آيات إلى المفضلة',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final bookmark = favorites[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
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
                    leading: const Icon(
                      Icons.favorite,
                      color: AppColors.error,
                    ),
                    title: Text(
                      bookmark.surahName,
                      style: AppTextStyles.arabicBody.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    subtitle: Text(
                      bookmark.ayahText,
                      style: AppTextStyles.arabicCaption,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${bookmark.surahNumber}:${bookmark.ayahNumber}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
