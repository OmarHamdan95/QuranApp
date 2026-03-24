import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Splash screen shown at app launch.
///
/// Plays a layered animation (logo fade-in + scale, then text and tagline)
/// while initialising core services in parallel:
/// - SQLite database preparation (asset copy if needed)
/// - SharedPreferences read for onboarding completion flag
///
/// Then navigates to onboarding or home based on onboarding state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // ── Logo animation (0 → 800ms) ─────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // ── Text animation (starts at 400ms) ──────────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Pulse animation for loading indicator ─────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Sequence animations ────────────────────────────────────────
    _logoController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _textController.forward();
      });
    });

    // ── Initialise and navigate ────────────────────────────────────
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Run initialisation concurrently with the minimum splash duration.
    final results = await Future.wait([
      _initServices(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);

    if (!mounted) return;

    final onboardingDone = results[0] as bool;

    if (onboardingDone) {
      context.goNamed(RouteNames.home);
    } else {
      context.goNamed(RouteNames.onboarding);
    }
  }

  /// Initialises core services and returns whether onboarding is complete.
  Future<bool> _initServices() async {
    try {
      // Prepare the Quran SQLite database.
      await DatabaseHelper.instance.quranDatabase;

      // Check onboarding flag.
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // ── Background decorative circles ──────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: _DecorativeCircle(
              size: 220,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _DecorativeCircle(
              size: 260,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -20,
            child: _DecorativeCircle(
              size: 120,
              color: AppColors.secondary.withValues(alpha: 0.08),
            ),
          ),

          // ── Main content ──────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: _LogoWidget(),
                ),

                const SizedBox(height: 28),

                // App name
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'القرآن الكريم',
                        style: AppTextStyles.arabicHeadline.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Text(
                          'اقرأ · استمع · احفظ',
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 16,
                            letterSpacing: 3,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 64),

                // Loading indicator
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _pulse.value,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white.withValues(alpha: 0.8),
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Version label at bottom ────────────────────────────────
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _taglineFade.value,
                  child: child,
                );
              },
              child: Text(
                'v${AppConstants.appVersion}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo Widget ───────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
        ),

        // Middle ring
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),

        // Icon background
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),

        // Gold accent arc (top)
        Positioned(
          top: 4,
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Decorative Circle ─────────────────────────────────────────────────────────

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
