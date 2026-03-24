import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Onboarding page data.
class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.menu_book_rounded,
    title: 'اقرأ القرآن الكريم',
    description:
        'تصفح القرآن بخط عثماني واضح مع الترجمة والتفسير. اقرأ بالسورة أو الجزء أو الصفحة.',
    accentColor: AppColors.primary,
  ),
  _OnboardingPage(
    icon: Icons.headphones_rounded,
    title: 'استمع للتلاوة',
    description:
        'استمع إلى القرآن الكريم بأصوات أشهر القراء. حمّل التلاوات للاستماع بدون إنترنت.',
    accentColor: AppColors.tertiary,
  ),
  _OnboardingPage(
    icon: Icons.school_rounded,
    title: 'احفظ القرآن',
    description:
        'أنشئ خطة حفظ مخصصة واختبر نفسك. تابع تقدمك وحافظ على سلسلة المراجعة اليومية.',
    accentColor: AppColors.secondary,
  ),
  _OnboardingPage(
    icon: Icons.mosque_rounded,
    title: 'مواقيت الصلاة والقبلة',
    description:
        'اعرف مواقيت الصلاة حسب موقعك وحدد اتجاه القبلة بدقة باستخدام البوصلة.',
    accentColor: AppColors.fajr,
  ),
  _OnboardingPage(
    icon: Icons.emoji_events_rounded,
    title: 'مسابقات قرآنية',
    description:
        'اختبر معرفتك بالقرآن من خلال مسابقات متنوعة. تحدى نفسك يوميًا واكسب النقاط.',
    accentColor: AppColors.info,
  ),
];

/// Onboarding flow shown to first-time users.
///
/// Introduces the app's main features through a swipeable page carousel,
/// then navigates to the home screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    // TODO: Save onboarding completion to SharedPreferences.
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool(AppConstants.prefOnboardingComplete, true);

    context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'تخطي',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageView(
                    page: page,
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _pages[_currentPage].accentColor
                          : (isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isLastPage ? 'ابدأ الآن' : 'التالي',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: context.bottomPadding),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final bool isDark;

  const _OnboardingPageView({
    required this.page,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.accentColor,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: AppTextStyles.arabicHeadline.copyWith(
              fontSize: 26,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: AppTextStyles.arabicBody.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.8,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
