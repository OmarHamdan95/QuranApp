import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../audio/data/models/reciter_model.dart';
import '../../../audio/presentation/providers/audio_providers.dart';

/// Represents a downloaded surah audio file.
class DownloadedItem {
  final int surahNumber;
  final String surahName;
  final String reciterName;
  final int fileSizeMb;
  final bool isDownloading;
  final double progress;

  const DownloadedItem({
    required this.surahNumber,
    required this.surahName,
    required this.reciterName,
    required this.fileSizeMb,
    this.isDownloading = false,
    this.progress = 1.0,
  });
}

/// In-memory state for downloaded items.
/// In production, this scans the file system for downloaded audio.
final downloadedItemsProvider = StateProvider<List<DownloadedItem>>((ref) {
  // Placeholder - no downloads initially
  return [];
});

/// Screen for managing downloaded audio files.
///
/// Shows downloaded surahs, allows deletion, and provides
/// batch download functionality.
class DownloadsManagerScreen extends ConsumerWidget {
  const DownloadsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadedItemsProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة التحميلات',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (downloads.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete_all') {
                  _showDeleteAllDialog(context, ref);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'حذف الكل',
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: downloads.isEmpty
          ? _EmptyDownloadsView(
              isDark: isDark,
              reciterName: selectedReciter.nameArabic,
              onDownloadSuggested: () {
                _showBatchDownloadSheet(context, ref);
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: downloads.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _StorageHeader(
                    downloadCount: downloads.length,
                    totalSizeMb: downloads.fold(0, (sum, d) => sum + d.fileSizeMb),
                  );
                }

                final item = downloads[index - 1];
                return _DownloadTile(
                  item: item,
                  isDark: isDark,
                  onDelete: () {
                    final current = ref.read(downloadedItemsProvider);
                    ref.read(downloadedItemsProvider.notifier).state =
                        current.where((d) => d.surahNumber != item.surahNumber).toList();
                    context.showSnackBar('تم حذف ${item.surahName}');
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBatchDownloadSheet(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.download, color: Colors.white),
        label: Text(
          'تحميل سور',
          style: AppTextStyles.arabicCaption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'حذف جميع التحميلات؟',
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'سيتم حذف جميع الملفات الصوتية المحملة. يمكنك إعادة تحميلها لاحقاً.',
          style: AppTextStyles.arabicCaption,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: AppTextStyles.arabicCaption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadedItemsProvider.notifier).state = [];
              Navigator.of(context).pop();
            },
            child: Text(
              'حذف الكل',
              style: AppTextStyles.arabicCaption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBatchDownloadSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BatchDownloadSheet(),
    );
  }
}

class _StorageHeader extends StatelessWidget {
  final int downloadCount;
  final int totalSizeMb;

  const _StorageHeader({
    required this.downloadCount,
    required this.totalSizeMb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$downloadCount سورة محملة ($totalSizeMb MB)',
              style: AppTextStyles.arabicCaption.copyWith(
                color: AppColors.primary,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadedItem item;
  final bool isDark;
  final VoidCallback onDelete;

  const _DownloadTile({
    required this.item,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.surahNumber),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${item.surahNumber}',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          item.surahName,
          style: AppTextStyles.arabicBody,
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          '${item.reciterName} - ${item.fileSizeMb} MB',
          style: AppTextStyles.arabicCaption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          textDirection: TextDirection.rtl,
        ),
        trailing: item.isDownloading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: item.progress,
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.textTertiaryLight,
                onPressed: onDelete,
              ),
      ),
    );
  }
}

class _EmptyDownloadsView extends StatelessWidget {
  final bool isDark;
  final String reciterName;
  final VoidCallback onDownloadSuggested;

  const _EmptyDownloadsView({
    required this.isDark,
    required this.reciterName,
    required this.onDownloadSuggested,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 64,
              color: AppColors.textTertiaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد تحميلات',
              style: AppTextStyles.arabicBody.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'حمّل السور للاستماع بدون إنترنت',
              style: AppTextStyles.arabicCaption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onDownloadSuggested,
              icon: const Icon(Icons.download, size: 18),
              label: Text(
                'تحميل سور مختارة',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchDownloadSheet extends StatelessWidget {
  /// Popular surahs that users commonly download.
  static const _suggestedSurahs = [
    (1, 'الفاتحة'),
    (2, 'البقرة'),
    (18, 'الكهف'),
    (36, 'يس'),
    (55, 'الرحمن'),
    (56, 'الواقعة'),
    (67, 'الملك'),
    (78, 'النبأ'),
    (112, 'الإخلاص'),
    (113, 'الفلق'),
    (114, 'الناس'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Text(
                    'اختر السور للتحميل',
                    style: AppTextStyles.arabicHeadline,
                    textDirection: TextDirection.rtl,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _suggestedSurahs.length,
                itemBuilder: (context, index) {
                  final (number, name) = _suggestedSurahs[index];
                  return CheckboxListTile(
                    title: Text(
                      '$number. $name',
                      style: AppTextStyles.arabicBody,
                      textDirection: TextDirection.rtl,
                    ),
                    value: false,
                    onChanged: (_) {
                      // TODO: Toggle selection
                    },
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // TODO: Start downloads
                  },
                  child: Text(
                    'بدء التحميل',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
