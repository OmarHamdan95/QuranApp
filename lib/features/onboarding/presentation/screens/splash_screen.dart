import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Splash screen shown at app launch.
///
/// Displays the app logo and name while initializing services
/// (database, preferences, etc.), then navigates to onboarding
/// or home based on whether the user has completed onboarding.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleUp;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Initialize app and navigate after delay.
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Allow splash animation to play.
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // TODO: Check SharedPreferences for onboarding completion.
    // final prefs = await SharedPreferences.getInstance();
    // final onboardingDone = prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;
    const onboardingDone = false;

    if (!mounted) return;

    if (onboardingDone) {
      context.goNamed(RouteNames.home);
    } else {
      context.goNamed(RouteNames.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeIn.value,
              child: Transform.scale(
                scale: _scaleUp.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // App name in Arabic
              Text(
                'القرآن الكريم',
                style: AppTextStyles.arabicHeadline.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'اقرأ · استمع · احفظ',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                textDirection: TextDirection.rtl,
              ),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.7),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
