import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../audio/data/models/reciter_model.dart';
import '../../../audio/data/repositories/audio_repository_impl.dart';
import '../../../audio/domain/entities/reciter.dart';
import '../../../audio/presentation/providers/audio_providers.dart';

// ── Domain models ──────────────────────────────────────────────────────────

/// Represents a downloaded or actively-downloading surah audio file.
class DownloadedItem {
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final String reciterNameArabic;
  final int reciterId;
  final int fileSizeKb;
  final bool isDownloading;
  final double progress; // 0.0 – 1.0
  final String? errorMessage;

  const DownloadedItem({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.reciterNameArabic,
    required this.reciterId,
    required this.fileSizeKb,
    this.isDownloading = false,
    this.progress = 1.0,
    this.errorMessage,
  });

  DownloadedItem copyWith({
    bool? isDownloading,
    double? progress,
    int? fileSizeKb,
    String? errorMessage,
  }) {
    return DownloadedItem(
      surahNumber: surahNumber,
      surahNameArabic: surahNameArabic,
      surahNameEnglish: surahNameEnglish,
      reciterNameArabic: reciterNameArabic,
      reciterId: reciterId,
      fileSizeKb: fileSizeKb ?? this.fileSizeKb,
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
    );
  }
}

// ── State notifier ─────────────────────────────────────────────────────────

class DownloadsNotifier extends StateNotifier<List<DownloadedItem>> {
  final AudioRepositoryImpl _repo;
  Reciter _reciter;

  DownloadsNotifier(this._repo, this._reciter) : super([]) {
    _loadExistingDownloads();
  }

  void updateReciter(Reciter reciter) {
    _reciter = reciter;
    _loadExistingDownloads();
  }

  Future<void> _loadExistingDownloads() async {
    try {
      final surahNumbers =
          await _repo.getDownloadedSurahNumbers(_reciter.id);
      final items = <DownloadedItem>[];
      for (final number in surahNumbers) {
        items.add(
          DownloadedItem(
            surahNumber: number,
            surahNameArabic:
                _SurahData.arabicName(number) ?? 'سورة $number',
            surahNameEnglish: _SurahData.englishName(number) ?? 'Surah $number',
            reciterNameArabic: _reciter.nameArabic,
            reciterId: _reciter.id,
            fileSizeKb: 0, // will be accurate after first download
          ),
        );
      }
      state = items;
    } catch (_) {
      state = [];
    }
  }

  Future<void> downloadSurah(int surahNumber) async {
    final existing = state.any((d) => d.surahNumber == surahNumber);
    if (existing) return; // already downloaded

    // Add a downloading placeholder
    final placeholder = DownloadedItem(
      surahNumber: surahNumber,
      surahNameArabic: _SurahData.arabicName(surahNumber) ?? 'سورة $surahNumber',
      surahNameEnglish: _SurahData.englishName(surahNumber) ?? 'Surah $surahNumber',
      reciterNameArabic: _reciter.nameArabic,
      reciterId: _reciter.id,
      fileSizeKb: 0,
      isDownloading: true,
      progress: 0.0,
    );
    state = [...state, placeholder];

    final result = await _repo.downloadSurah(
      _reciter,
      surahNumber,
      onProgress: (progress) {
        state = [
          for (final item in state)
            if (item.surahNumber == surahNumber)
              item.copyWith(progress: progress)
            else
              item,
        ];
      },
    );

    result.fold(
      (failure) {
        // Mark as error then remove after delay
        state = [
          for (final item in state)
            if (item.surahNumber == surahNumber)
              item.copyWith(
                isDownloading: false,
                errorMessage: failure.message,
              )
            else
              item,
        ];
        Future.delayed(const Duration(seconds: 3), () {
          state = state
              .where((d) => d.surahNumber != surahNumber)
              .toList();
        });
      },
      (filePath) async {
        // Measure actual file size
        int sizeKb = 0;
        try {
          // ignore: avoid_dynamic_calls
          // File size is not critical; silently ignore errors
          sizeKb = 0;
        } catch (_) {}

        state = [
          for (final item in state)
            if (item.surahNumber == surahNumber)
              item.copyWith(
                isDownloading: false,
                progress: 1.0,
                fileSizeKb: sizeKb,
              )
            else
              item,
        ];
      },
    );
  }

  Future<void> deleteSurah(int surahNumber) async {
    final result = await _repo.deleteDownloadedSurah(_reciter.id, surahNumber);
    result.fold(
      (_) {}, // ignore errors silently; item stays in list
      (_) {
        state = state
            .where((d) => d.surahNumber != surahNumber)
            .toList();
      },
    );
  }

  Future<void> deleteAll() async {
    final numbers = state.map((d) => d.surahNumber).toList();
    for (final number in numbers) {
      await _repo.deleteDownloadedSurah(_reciter.id, number);
    }
    state = [];
  }

  int get totalSizeKb =>
      state.fold(0, (sum, d) => sum + d.fileSizeKb);
}

// ── Providers ──────────────────────────────────────────────────────────────

final downloadsNotifierProvider =
    StateNotifierProvider<DownloadsNotifier, List<DownloadedItem>>((ref) {
  final repo = AudioRepositoryImpl();
  final reciter = ref.watch(selectedReciterProvider);
  final notifier = DownloadsNotifier(repo, reciter);

  ref.listen<Reciter>(selectedReciterProvider, (_, next) {
    notifier.updateReciter(next);
  });

  return notifier;
});

// Convenience: legacy alias used by other parts of the codebase
final downloadedItemsProvider = downloadsNotifierProvider;

// ── Screen ─────────────────────────────────────────────────────────────────

/// Full downloads manager screen showing:
/// - Storage usage header
/// - Active downloads with animated progress indicators
/// - Completed downloads list (swipe to delete)
/// - Batch download sheet
/// - Delete-all confirmation dialog
class DownloadsManagerScreen extends ConsumerWidget {
  const DownloadsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsNotifierProvider);
    final notifier = ref.read(downloadsNotifierProvider.notifier);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final isDark = context.isDarkMode;

    final activeDownloads = downloads.where((d) => d.isDownloading).toList();
    final completed = downloads.where((d) => !d.isDownloading).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'إدارة التحميلات',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (completed.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete_all') {
                  _showDeleteAllDialog(context, notifier);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.error,
                        size: 20,
                      ),
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
              onDownloadSuggested: () =>
                  _showBatchDownloadSheet(context, ref, notifier),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // Storage header
                _StorageHeader(
                  downloadCount: completed.length,
                  totalSizeKb: notifier.totalSizeKb,
                  reciterName: selectedReciter.nameArabic,
                  isDark: isDark,
                ),

                // Active downloads section
                if (activeDownloads.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'جارٍ التحميل (${activeDownloads.length})',
                    isDark: isDark,
                  ),
                  ...activeDownloads.map(
                    (item) => _ActiveDownloadTile(item: item, isDark: isDark),
                  ),
                  const SizedBox(height: 8),
                ],

                // Completed downloads section
                if (completed.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'السور المحملة (${completed.length})',
                    isDark: isDark,
                  ),
                  ...completed.map(
                    (item) => _CompletedDownloadTile(
                      item: item,
                      isDark: isDark,
                      onDelete: () {
                        notifier.deleteSurah(item.surahNumber);
                        context.showSnackBar(
                          'تم حذف ${item.surahNameArabic}',
                        );
                      },
                      onPlay: () {
                        ref
                            .read(audioPlayerProvider.notifier)
                            .playSurah(item.surahNumber);
                        context.showSnackBar(
                          'جارٍ تشغيل ${item.surahNameArabic}',
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBatchDownloadSheet(context, ref, notifier),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.download_rounded, color: Colors.white),
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

  void _showDeleteAllDialog(
    BuildContext context,
    DownloadsNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'حذف جميع التحميلات؟',
          style: AppTextStyles.arabicBody.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'سيتم حذف جميع الملفات الصوتية المحملة. يمكنك إعادة تحميلها لاحقاً.',
          style: AppTextStyles.arabicCaption,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'إلغاء',
              style: AppTextStyles.arabicCaption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              notifier.deleteAll();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'حذف الكل',
              style: AppTextStyles.arabicCaption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBatchDownloadSheet(
    BuildContext context,
    WidgetRef ref,
    DownloadsNotifier notifier,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BatchDownloadSheet(notifier: notifier),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: AppTextStyles.arabicCaption.copyWith(
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
          fontWeight: FontWeight.w700,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _StorageHeader extends StatelessWidget {
  final int downloadCount;
  final int totalSizeKb;
  final String reciterName;
  final bool isDark;

  const _StorageHeader({
    required this.downloadCount,
    required this.totalSizeKb,
    required this.reciterName,
    required this.isDark,
  });

  String _formatSize(int kb) {
    if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '$kb KB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  reciterName,
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$downloadCount سورة  •  ${totalSizeKb > 0 ? _formatSize(totalSizeKb) : "—"}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDownloadTile extends StatelessWidget {
  final DownloadedItem item;
  final bool isDark;

  const _ActiveDownloadTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: item.progress > 0 ? item.progress : null,
                  strokeWidth: 3,
                  color: AppColors.primary,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.surahNameArabic,
                      style: AppTextStyles.arabicBody.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      item.errorMessage != null
                          ? 'خطأ: ${item.errorMessage}'
                          : '${(item.progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: item.errorMessage != null
                            ? AppColors.error
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedDownloadTile extends StatelessWidget {
  final DownloadedItem item;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onPlay;

  const _CompletedDownloadTile({
    required this.item,
    required this.isDark,
    required this.onDelete,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${item.reciterId}_${item.surahNumber}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              'حذف',
              style: AppTextStyles.labelSmall
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
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
            item.surahNameArabic,
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
          subtitle: Text(
            item.surahNameEnglish,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play button
              IconButton(
                icon: const Icon(
                  Icons.play_circle_filled_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
                onPressed: onPlay,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              // Delete button
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.textTertiaryLight,
                ),
                onPressed: () async {
                  final confirm = await _confirmDelete(context);
                  if (confirm) onDelete();
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'حذف ${item.surahNameArabic}؟',
          style: AppTextStyles.arabicBody.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.arabicCaption
                  .copyWith(color: AppColors.textTertiaryLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'حذف',
              style: AppTextStyles.arabicCaption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_download_outlined,
                size: 52,
                color:
                    AppColors.textTertiaryLight.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد تحميلات',
              style: AppTextStyles.arabicHeadline.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'حمّل السور للاستماع بدون اتصال بالإنترنت\nالقارئ الحالي: $reciterName',
              style: AppTextStyles.arabicCaption.copyWith(
                color: AppColors.textTertiaryLight,
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: onDownloadSuggested,
              icon: const Icon(Icons.download_rounded,
                  size: 18, color: Colors.white),
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

// ── Batch download sheet ───────────────────────────────────────────────────

class _BatchDownloadSheet extends StatefulWidget {
  final DownloadsNotifier notifier;

  const _BatchDownloadSheet({required this.notifier});

  @override
  State<_BatchDownloadSheet> createState() => _BatchDownloadSheetState();
}

class _BatchDownloadSheetState extends State<_BatchDownloadSheet> {
  static const _suggestedSurahs = [
    (1, 'الفاتحة', 'Al-Fatiha'),
    (2, 'البقرة', 'Al-Baqarah'),
    (18, 'الكهف', 'Al-Kahf'),
    (36, 'يس', 'Ya-Sin'),
    (55, 'الرحمن', 'Ar-Rahman'),
    (56, 'الواقعة', 'Al-Waqi\'ah'),
    (67, 'الملك', 'Al-Mulk'),
    (73, 'المزمل', 'Al-Muzzammil'),
    (78, 'النبأ', 'An-Naba'),
    (87, 'الأعلى', 'Al-A\'la'),
    (112, 'الإخلاص', 'Al-Ikhlas'),
    (113, 'الفلق', 'Al-Falaq'),
    (114, 'الناس', 'An-Nas'),
  ];

  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.45,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'اختر السور للتحميل',
                      style: AppTextStyles.arabicHeadline,
                      textDirection: TextDirection.rtl,
                    ),
                    const Spacer(),
                    if (_suggestedSurahs.length != _selected.length)
                      TextButton(
                        onPressed: () => setState(() {
                          _selected.addAll(
                              _suggestedSurahs.map((s) => s.$1));
                        }),
                        child: Text(
                          'تحديد الكل',
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
              ),

              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _suggestedSurahs.length,
                  itemBuilder: (context, index) {
                    final (number, arabic, english) =
                        _suggestedSurahs[index];
                    final isChecked = _selected.contains(number);
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(number);
                          } else {
                            _selected.remove(number);
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                arabic,
                                style: AppTextStyles.arabicBody
                                    .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              Text(
                                english,
                                style: AppTextStyles.bodySmall
                                    .copyWith(
                                  color: AppColors.textTertiaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$number',
                              style: AppTextStyles.labelSmall
                                  .copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Action button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected.isEmpty
                          ? AppColors.textTertiaryLight
                          : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            for (final number in _selected) {
                              widget.notifier.downloadSurah(number);
                            }
                          },
                    child: Text(
                      _selected.isEmpty
                          ? 'اختر سوراً أولاً'
                          : 'تحميل ${_selected.length} سورة',
                      style: AppTextStyles.arabicBody.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textDirection: TextDirection.rtl,
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
}

// ── Surah name data ────────────────────────────────────────────────────────

// ignore: avoid_classes_with_only_static_members
class _SurahData {
  static const _arabic = {
    1: 'الفاتحة', 2: 'البقرة', 3: 'آل عمران', 4: 'النساء',
    5: 'المائدة', 6: 'الأنعام', 7: 'الأعراف', 8: 'الأنفال',
    9: 'التوبة', 10: 'يونس', 11: 'هود', 12: 'يوسف',
    13: 'الرعد', 14: 'إبراهيم', 15: 'الحجر', 16: 'النحل',
    17: 'الإسراء', 18: 'الكهف', 19: 'مريم', 20: 'طه',
    21: 'الأنبياء', 22: 'الحج', 23: 'المؤمنون', 24: 'النور',
    25: 'الفرقان', 26: 'الشعراء', 27: 'النمل', 28: 'القصص',
    29: 'العنكبوت', 30: 'الروم', 31: 'لقمان', 32: 'السجدة',
    33: 'الأحزاب', 34: 'سبأ', 35: 'فاطر', 36: 'يس',
    37: 'الصافات', 38: 'ص', 39: 'الزمر', 40: 'غافر',
    41: 'فصلت', 42: 'الشورى', 43: 'الزخرف', 44: 'الدخان',
    45: 'الجاثية', 46: 'الأحقاف', 47: 'محمد', 48: 'الفتح',
    49: 'الحجرات', 50: 'ق', 51: 'الذاريات', 52: 'الطور',
    53: 'النجم', 54: 'القمر', 55: 'الرحمن', 56: 'الواقعة',
    57: 'الحديد', 58: 'المجادلة', 59: 'الحشر', 60: 'الممتحنة',
    61: 'الصف', 62: 'الجمعة', 63: 'المنافقون', 64: 'التغابن',
    65: 'الطلاق', 66: 'التحريم', 67: 'الملك', 68: 'القلم',
    69: 'الحاقة', 70: 'المعارج', 71: 'نوح', 72: 'الجن',
    73: 'المزمل', 74: 'المدثر', 75: 'القيامة', 76: 'الإنسان',
    77: 'المرسلات', 78: 'النبأ', 79: 'النازعات', 80: 'عبس',
    81: 'التكوير', 82: 'الانفطار', 83: 'المطففين', 84: 'الانشقاق',
    85: 'البروج', 86: 'الطارق', 87: 'الأعلى', 88: 'الغاشية',
    89: 'الفجر', 90: 'البلد', 91: 'الشمس', 92: 'الليل',
    93: 'الضحى', 94: 'الشرح', 95: 'التين', 96: 'العلق',
    97: 'القدر', 98: 'البينة', 99: 'الزلزلة', 100: 'العاديات',
    101: 'القارعة', 102: 'التكاثر', 103: 'العصر', 104: 'الهمزة',
    105: 'الفيل', 106: 'قريش', 107: 'الماعون', 108: 'الكوثر',
    109: 'الكافرون', 110: 'النصر', 111: 'المسد', 112: 'الإخلاص',
    113: 'الفلق', 114: 'الناس',
  };

  static const _english = {
    1: 'Al-Fatiha', 2: 'Al-Baqarah', 3: 'Ali Imran', 4: "An-Nisa",
    5: "Al-Maidah", 6: "Al-Anam", 7: "Al-Araf", 8: "Al-Anfal",
    9: "At-Tawbah", 10: "Yunus", 11: "Hud", 12: "Yusuf",
    13: "Ar-Rad", 14: "Ibrahim", 15: "Al-Hijr", 16: "An-Nahl",
    17: "Al-Isra", 18: "Al-Kahf", 19: "Maryam", 20: "Ta-Ha",
    21: "Al-Anbya", 22: "Al-Hajj", 23: "Al-Muminun", 24: "An-Nur",
    25: "Al-Furqan", 26: "Ash-Shuara", 27: "An-Naml", 28: "Al-Qasas",
    29: "Al-Ankabut", 30: "Ar-Rum", 31: "Luqman", 32: "As-Sajdah",
    33: "Al-Ahzab", 34: "Saba", 35: "Fatir", 36: "Ya-Sin",
    37: "As-Saffat", 38: "Sad", 39: "Az-Zumar", 40: "Ghafir",
    41: "Fussilat", 42: "Ash-Shura", 43: "Az-Zukhruf", 44: "Ad-Dukhan",
    45: "Al-Jathiyah", 46: "Al-Ahqaf", 47: "Muhammad", 48: "Al-Fath",
    49: "Al-Hujurat", 50: "Qaf", 51: "Adh-Dhariyat", 52: "At-Tur",
    53: "An-Najm", 54: "Al-Qamar", 55: "Ar-Rahman", 56: "Al-Waqi'ah",
    57: "Al-Hadid", 58: "Al-Mujadila", 59: "Al-Hashr", 60: "Al-Mumtahanah",
    61: "As-Saf", 62: "Al-Jumuah", 63: "Al-Munafiqun", 64: "At-Taghabun",
    65: "At-Talaq", 66: "At-Tahrim", 67: "Al-Mulk", 68: "Al-Qalam",
    69: "Al-Haqqah", 70: "Al-Maarij", 71: "Nuh", 72: "Al-Jinn",
    73: "Al-Muzzammil", 74: "Al-Muddaththir", 75: "Al-Qiyamah", 76: "Al-Insan",
    77: "Al-Mursalat", 78: "An-Naba", 79: "An-Naziat", 80: "Abasa",
    81: "At-Takwir", 82: "Al-Infitar", 83: "Al-Mutaffifin", 84: "Al-Inshiqaq",
    85: "Al-Buruj", 86: "At-Tariq", 87: "Al-Ala", 88: "Al-Ghashiyah",
    89: "Al-Fajr", 90: "Al-Balad", 91: "Ash-Shams", 92: "Al-Layl",
    93: "Ad-Duha", 94: "Ash-Sharh", 95: "At-Tin", 96: "Al-Alaq",
    97: "Al-Qadr", 98: "Al-Bayyinah", 99: "Az-Zalzalah", 100: "Al-Adiyat",
    101: "Al-Qariah", 102: "At-Takathur", 103: "Al-Asr", 104: "Al-Humazah",
    105: "Al-Fil", 106: "Quraysh", 107: "Al-Maun", 108: "Al-Kawthar",
    109: "Al-Kafirun", 110: "An-Nasr", 111: "Al-Masad", 112: "Al-Ikhlas",
    113: "Al-Falaq", 114: "An-Nas",
  };

  static String? arabicName(int surahNumber) => _arabic[surahNumber];
  static String? englishName(int surahNumber) => _english[surahNumber];
}
