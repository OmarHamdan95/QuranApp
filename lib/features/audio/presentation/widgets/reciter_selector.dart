import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/reciter.dart';
import '../providers/audio_providers.dart';

/// A bottom sheet or dialog for selecting a Quran reciter.
class ReciterSelector extends ConsumerWidget {
  const ReciterSelector({super.key});

  /// Shows the reciter selector as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ReciterSelector(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recitersAsync = ref.watch(recitersProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final isDark = context.isDarkMode;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Reciter list
            Expanded(
              child: recitersAsync.when(
                data: (reciters) => ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = reciters[index];
                    final isSelected = reciter.id == selectedReciter.id;

                    return _ReciterTile(
                      reciter: reciter,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () {
                        ref.read(selectedReciterProvider.notifier).state = reciter;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReciterTile extends StatelessWidget {
  final Reciter reciter;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ReciterTile({
    required this.reciter,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.1),
        child: Icon(
          Icons.person,
          color: isSelected ? Colors.white : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        reciter.nameArabic,
        style: AppTextStyles.arabicBody.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        '${reciter.nameEnglish} - ${reciter.style}',
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  }
}
