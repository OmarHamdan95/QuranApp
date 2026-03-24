import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../quran/presentation/providers/quran_providers.dart';

/// Search query state provider.
final _searchQueryProvider = StateProvider<String>((ref) => '');

/// Full-screen search for ayahs, surahs, and topics.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'ابحث في القرآن...',
            hintStyle: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
          ),
          style: AppTextStyles.arabicBody,
          onChanged: (value) {
            ref.read(_searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _controller.clear();
                ref.read(_searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? _SearchSuggestions()
          : _SearchResults(query: query),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final _suggestions = const [
    'الفاتحة',
    'آية الكرسي',
    'سورة يس',
    'سورة الملك',
    'الرحمن',
    'سورة الكهف',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'بحث مقترح',
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            textDirection: TextDirection.rtl,
            children: _suggestions.map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: AppTextStyles.arabicCaption,
                ),
                onPressed: () {
                  // Set search query
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;

  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchAyahsProvider(query));

    return resultsAsync.when(
      data: (ayahs) {
        if (ayahs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: AppColors.textTertiaryLight),
                const SizedBox(height: 12),
                Text(
                  'لم يتم العثور على نتائج',
                  style: AppTextStyles.arabicBody.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: ayahs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final ayah = ayahs[index];
            return ListTile(
              onTap: () {
                context.pushNamed(
                  RouteNames.quranReader,
                  pathParameters: {
                    'surahNumber': ayah.surahNumber.toString(),
                  },
                  queryParameters: {
                    'ayah': ayah.ayahNumber.toString(),
                  },
                );
              },
              title: Text(
                ayah.textUthmani,
                style: AppTextStyles.quranAyah.copyWith(fontSize: 18, height: 1.6),
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${ayah.surahNumber}:${ayah.ayahNumber} - صفحة ${ayah.page}',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}
