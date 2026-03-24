import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ── Page Data ────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final List<String> features;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.features,
  });
}

const _pages = <_OnboardingPage>[
  _OnboardingPage(
    icon: Icons.menu_book_rounded,
    title: 'اقرأ القرآن الكريم',
    description:
        'تصفح القرآن الكريم بخط عثماني واضح مع الترجمة والتفسير.',
    accentColor: AppColors.primary,
    features: [
      'قراءة بالسورة والجزء والصفحة',
      'خط أميري الجميل',
      'تفسير مفصل لكل آية',
    ],
  ),
  _OnboardingPage(
    icon: Icons.headphones_rounded,
    title: 'استمع للتلاوة',
    description:
        'استمع إلى القرآن بأصوات أشهر القراء مع تتبع الآيات.',
    accentColor: AppColors.tertiary,
    features: [
      'أكثر من ١٠ قارئ مشهور',
      'تحكم كامل في التشغيل',
      'تحميل للاستماع دون إنترنت',
    ],
  ),
  _OnboardingPage(
    icon: Icons.school_rounded,
    title: 'احفظ القرآن',
    description:
        'أنشئ خطة حفظ مخصصة واختبر نفسك لمتابعة تقدمك يومياً.',
    accentColor: AppColors.secondary,
    features: [
      'خطة حفظ مرنة',
      'اختبار يومي للمراجعة',
      'إحصائيات تفصيلية للتقدم',
    ],
  ),
  _OnboardingPage(
    icon: Icons.mosque_rounded,
    title: 'مواقيت الصلاة والقبلة',
    description:
        'اعرف مواقيت الصلاة الدقيقة حسب موقعك وحدد اتجاه القبلة.',
    accentColor: AppColors.fajr,
    features: [
      'مواقيت دقيقة حسب الموقع',
      'بوصلة القبلة التفاعلية',
      'تنبيهات الصلاة الذكية',
    ],
  ),
  _OnboardingPage(
    icon: Icons.emoji_events_rounded,
    title: 'مسابقات قرآنية',
    description:
        'اختبر معرفتك بالقرآن وتحدَّ نفسك يومياً بمسابقات متنوعة.',
    accentColor: AppColors.info,
    features: [
      'مسابقات يومية متجددة',
      'مستويات صعوبة متعددة',
      'احتفظ بسلسلة انتصاراتك',
    ],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

/// Onboarding flow shown to first-time users.
///
/// Features:
/// - Swipeable page carousel with smooth transitions
/// - Per-page accent colour theming
/// - Feature bullet list per page
/// - Animated page indicators
/// - Skip button (jumps to home)
/// - Persists onboarding completion flag
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late AnimationController _buttonController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _buttonController.forward(from: 0);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    } catch (_) {
      // Non-critical; proceed even if prefs write fails.
    }
    if (!mounted) return;
    context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isLastPage = _currentPage == _pages.length - 1;
    final accentColor = _pages[_currentPage].accentColor;

    return Scaffold(
      body: Stack(
        children: [
          // ── Page view ─────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _OnboardingPageView(
                page: _pages[index],
                isDark: isDark,
                isActive: index == _currentPage,
              );
            },
          ),

          // ── Skip button (top-left in LTR / top-right in RTL) ──────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AnimatedOpacity(
                  opacity: isLastPage ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: TextButton(
                    onPressed: isLastPage ? null : _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'تخطي',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom controls ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicators
                    _PageIndicators(
                      count: _pages.length,
                      current: _currentPage,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Next / Start button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor:
                                accentColor.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? 'ابدأ الآن' : 'التالي',
                                style: AppTextStyles.arabicBody.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastPage
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_back_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page View ─────────────────────────────────────────────────────────────────

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final bool isDark;
  final bool isActive;

  const _OnboardingPageView({
    required this.page,
    required this.isDark,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Animated Icon ────────────────────────────────────────
          AnimatedScale(
            scale: isActive ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 350),
            curve: Curves.elasticOut,
            child: _FeatureIcon(page: page, isDark: isDark),
          ),

          const SizedBox(height: 40),

          // ── Title ────────────────────────────────────────────────
          Text(
            page.title,
            style: AppTextStyles.arabicHeadline.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          // ── Description ──────────────────────────────────────────
          Text(
            page.description,
            style: AppTextStyles.arabicBody.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.9,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // ── Feature bullets ───────────────────────────────────────
          ...page.features.map((f) => _FeatureBullet(
                text: f,
                color: page.accentColor,
                isDark: isDark,
              )),
        ],
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final _OnboardingPage page;
  final bool isDark;

  const _FeatureIcon({required this.page, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: page.accentColor.withValues(alpha: 0.06),
          ),
        ),
        // Inner container
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: page.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
            border: Border.all(
              color:
                  page.accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            page.icon,
            size: 58,
            color: page.accentColor,
          ),
        ),
      ],
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _FeatureBullet({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: AppTextStyles.arabicCaption.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page Indicators ───────────────────────────────────────────────────────────

class _PageIndicators extends StatelessWidget {
  final int count;
  final int current;
  final Color accentColor;
  final bool isDark;

  const _PageIndicators({
    required this.count,
    required this.current,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? accentColor
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
