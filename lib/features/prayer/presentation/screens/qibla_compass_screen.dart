import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/prayer_providers.dart';

/// Provider for compass heading (degrees from north).
/// In production, this reads from flutter_compass stream.
final compassHeadingProvider = StreamProvider<double>((ref) {
  // Placeholder: emit a static heading.
  // Will be replaced with FlutterCompass.events stream.
  return Stream.periodic(
    const Duration(milliseconds: 100),
    (_) => 0.0,
  );
});

/// Provider for calculated Qibla direction from user's position.
final qiblaDirectionProvider = Provider<double>((ref) {
  final location = ref.watch(userLocationProvider);

  // Calculate Qibla direction using the spherical law of cosines.
  // Kaaba coordinates: 21.4225 N, 39.8262 E
  const kaabaLat = 21.4225 * (math.pi / 180);
  const kaabaLng = 39.8262 * (math.pi / 180);
  final lat = location.lat * (math.pi / 180);
  final lng = location.lng * (math.pi / 180);

  final dLng = kaabaLng - lng;

  final y = math.sin(dLng) * math.cos(kaabaLat);
  final x = math.cos(lat) * math.sin(kaabaLat) -
      math.sin(lat) * math.cos(kaabaLat) * math.cos(dLng);

  var bearing = math.atan2(y, x) * (180 / math.pi);
  bearing = (bearing + 360) % 360;

  return bearing;
});

/// Full-screen Qibla compass showing the direction to the Kaaba.
class QiblaCompassScreen extends ConsumerWidget {
  const QiblaCompassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qiblaDirection = ref.watch(qiblaDirectionProvider);
    final compassAsync = ref.watch(compassHeadingProvider);
    final location = ref.watch(userLocationProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          // Location info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  location.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Direction degrees
          Text(
            '${qiblaDirection.toStringAsFixed(1)}\u00B0',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),

          // Compass
          compassAsync.when(
            data: (heading) {
              final rotation = -(heading * math.pi / 180);
              final qiblaRotation = (qiblaDirection - heading) * math.pi / 180;

              return SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Compass dial
                    Transform.rotate(
                      angle: rotation,
                      child: _CompassDial(isDark: isDark),
                    ),

                    // Qibla indicator
                    Transform.rotate(
                      angle: qiblaRotation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Kaaba icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mosque,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              width: 280,
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => SizedBox(
              width: 280,
              height: 280,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      'تعذر الوصول إلى البوصلة',
                      style: AppTextStyles.arabicBody.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'وجه الهاتف نحو الاتجاه المشار إليه للعثور على القبلة',
              style: AppTextStyles.arabicCaption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: context.bottomPadding + 32),
        ],
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  final bool isDark;

  const _CompassDial({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 2,
        ),
      ),
      child: CustomPaint(
        painter: _CompassPainter(isDark: isDark),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final bool isDark;

  _CompassPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw tick marks
    final tickPaint = Paint()
      ..color = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight
      ..strokeWidth = 1.5;

    final majorTickPaint = Paint()
      ..color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight
      ..strokeWidth = 2.5;

    for (var i = 0; i < 360; i += 5) {
      final angle = i * math.pi / 180;
      final isMajor = i % 90 == 0;
      final isMinor = i % 30 == 0;

      final innerRadius = radius - (isMajor ? 24 : (isMinor ? 16 : 10));
      final outerRadius = radius - 4;

      final start = Offset(
        center.dx + innerRadius * math.sin(angle),
        center.dy - innerRadius * math.cos(angle),
      );
      final end = Offset(
        center.dx + outerRadius * math.sin(angle),
        center.dy - outerRadius * math.cos(angle),
      );

      canvas.drawLine(start, end, isMajor ? majorTickPaint : tickPaint);
    }

    // Draw N indicator
    final nPaint = Paint()..color = AppColors.error;
    final nCenter = Offset(center.dx, center.dy - radius + 36);
    canvas.drawCircle(nCenter, 4, nPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
