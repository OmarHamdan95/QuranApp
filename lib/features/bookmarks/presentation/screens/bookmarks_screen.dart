import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bookmark_providers.dart';

/// Bookmarks screen with folder tabs, swipe-to-delete,
/// Arabic ayah preview, and create-folder dialog.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkListProvider);
    final folders = ref.watch(folderNamesProvider);
    final selectedFolder = ref.watch(selectedFolderProvider);
    final isDark = context.isDarkMode;

    final allFolders = ['الكل', ...folders];

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
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showCreateFolderDialog(context, ref),
            tooltip: 'إنشاء مجلد',
          ),
        ],
        bottom: folders.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _FolderTabBar(
                  folders: allFolders,
                  selected: selectedFolder,
                  onSelect: (f) =>
                      ref.read(selectedFolderProvider.notifier).state = f,
                ),
              )
            : null,
      ),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'حدث خطأ في تحميل الإشارات المرجعية',
                style: AppTextStyles.arabicBody.copyWith(
                  color: AppColors.error,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
        data: (bookmarks) {
          final filtered = selectedFolder == 'الكل'
              ? bookmarks
              : bookmarks.where((b) => b.folder == selectedFolder).toList();

          if (filtered.isEmpty) {
            return _EmptyState(isDark: isDark, folder: selectedFolder);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final bookmark = filtered[index];
              return _BookmarkCard(
                bookmark: bookmark,
                isDark: isDark,
                onDelete: () {
                  ref
                      .read(bookmarkListProvider.notifier)
                      .removeBookmark(bookmark.id);
                  context.showSnackBar('تم حذف الإشارة المرجعية');
                },
                onToggleFavorite: () => ref
                    .read(bookmarkListProvider.notifier)
                    .toggleFavorite(bookmark.id),
                onTap: () => context.pushNamed(
                  RouteNames.quranReader,
                  pathParameters: {
                    'surahNumber': bookmark.surahNumber.toString(),
                  },
                  queryParameters: {
                    'ayah': bookmark.ayahNumber.toString(),
                  },
                ),
                onEditNote: () =>
                    _showEditNoteDialog(context, ref, bookmark),
                onMoveFolder: () =>
                    _showMoveFolderDialog(context, ref, bookmark, folders),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateFolderDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إنشاء مجلد جديد',
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
          textDirection: TextDirection.rtl,
        ),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'اسم المجلد',
            hintStyle: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          style: AppTextStyles.arabicBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      // Folder is created implicitly when the first bookmark is moved into it.
      if (context.mounted) {
        context.showSnackBar('المجلد "$result" جاهز للاستخدام');
      }
    }
  }

  Future<void> _showEditNoteDialog(
    BuildContext context,
    WidgetRef ref,
    Bookmark bookmark,
  ) async {
    final controller = TextEditingController(text: bookmark.note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تعديل الملاحظة',
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
          textDirection: TextDirection.rtl,
        ),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'أضف ملاحظة...',
            hintStyle: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          style: AppTextStyles.arabicBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != null) {
      ref
          .read(bookmarkListProvider.notifier)
          .updateNote(bookmark.id, result);
    }
  }

  Future<void> _showMoveFolderDialog(
    BuildContext context,
    WidgetRef ref,
    Bookmark bookmark,
    List<String> folders,
  ) async {
    final available = ['عام', ...folders.where((f) => f != 'عام')];
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          'نقل إلى مجلد',
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
          textDirection: TextDirection.rtl,
        ),
        children: available
            .map(
              (folder) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(folder),
                child: Text(
                  folder,
                  style: AppTextStyles.arabicBody,
                  textDirection: TextDirection.rtl,
                ),
              ),
            )
            .toList(),
      ),
    );
    if (result != null) {
      ref
          .read(bookmarkListProvider.notifier)
          .moveToFolder(bookmark.id, result);
      if (context.mounted) {
        context.showSnackBar('تم النقل إلى "$result"');
      }
    }
  }
}

// ── Folder tab bar ────────────────────────────────────────────────────────────

class _FolderTabBar extends StatelessWidget {
  final List<String> folders;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FolderTabBar({
    required this.folders,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: folders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final folder = folders[index];
          final isSelected = folder == selected;
          return ChoiceChip(
            label: Text(
              folder,
              style: AppTextStyles.arabicCaption.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            onSelected: (_) => onSelect(folder),
          );
        },
      ),
    );
  }
}

// ── Bookmark card ─────────────────────────────────────────────────────────────

class _BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;
  final VoidCallback onEditNote;
  final VoidCallback onMoveFolder;

  const _BookmarkCard({
    required this.bookmark,
    required this.isDark,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onTap,
    required this.onEditNote,
    required this.onMoveFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(bookmark.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'حذف الإشارة المرجعية',
              style: AppTextStyles.arabicBody
                  .copyWith(fontWeight: FontWeight.w700),
              textDirection: TextDirection.rtl,
            ),
            content: Text(
              'هل تريد حذف إشارة "${bookmark.surahName} - آية ${bookmark.ayahNumber}"؟',
              style: AppTextStyles.arabicCaption,
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: isDark ? 0 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Row(
                  children: [
                    // Colour indicator
                    Container(
                      width: 6,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _colorForBookmark(bookmark.color),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            bookmark.surahName,
                            style: AppTextStyles.arabicBody.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            'آية ${bookmark.ayahNumber}  •  صفحة ${bookmark.page}  •  ${bookmark.folder}',
                            style: AppTextStyles.arabicCaption.copyWith(
                              color: AppColors.textTertiaryLight,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: Icon(
                            bookmark.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: bookmark.isFavorite
                                ? AppColors.error
                                : AppColors.textTertiaryLight,
                            size: 20,
                          ),
                          onPressed: onToggleFavorite,
                        ),
                        PopupMenuButton<String>(
                          padding: const EdgeInsets.all(4),
                          iconSize: 20,
                          onSelected: (action) {
                            if (action == 'note') onEditNote();
                            if (action == 'folder') onMoveFolder();
                            if (action == 'delete') onDelete();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'note',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_note, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تعديل الملاحظة',
                                    style: AppTextStyles.arabicCaption,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'folder',
                              child: Row(
                                children: [
                                  const Icon(Icons.folder_open, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'نقل إلى مجلد',
                                    style: AppTextStyles.arabicCaption,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'حذف',
                                    style: AppTextStyles.arabicCaption
                                        .copyWith(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Ayah text preview ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.quranPageBackgroundDark
                        : AppColors.quranPageBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    bookmark.ayahText,
                    style: AppTextStyles.quranAyah.copyWith(
                      fontSize: 18,
                      height: 1.8,
                      color: isDark
                          ? AppColors.quranTextColorDark
                          : AppColors.quranTextColor,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ── Note (if present) ──
                if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notes,
                          size: 14,
                          color: AppColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            bookmark.note!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForBookmark(BookmarkColor color) {
    switch (color) {
      case BookmarkColor.blue:
        return AppColors.info;
      case BookmarkColor.red:
        return AppColors.error;
      case BookmarkColor.yellow:
        return AppColors.warning;
      case BookmarkColor.purple:
        return const Color(0xFF7B1FA2);
      case BookmarkColor.green:
        return AppColors.primary;
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String folder;

  const _EmptyState({required this.isDark, required this.folder});

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
              size: 72,
              color: AppColors.textTertiaryLight.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              folder == 'الكل'
                  ? 'لا توجد إشارات مرجعية'
                  : 'لا توجد إشارات في "$folder"',
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
