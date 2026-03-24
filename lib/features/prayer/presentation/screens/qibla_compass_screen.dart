import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/prayer_providers.dart';

// ── Compass heading provider (real flutter_compass stream) ─────────────────

/// Streams the device's compass heading in degrees (0-360, clockwise from N).
final compassHeadingProvider = StreamProvider<double>((ref) {
  return FlutterCompass.events!
      .where((event) => event.heading != null)
      .map((event) => event.heading!);
});

// ── Qibla Compass Screen ────────────────────────────────────────────────────

class QiblaCompassScreen extends ConsumerStatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  ConsumerState<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends ConsumerState<QiblaCompassScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _wasAligned = false;
  bool _showCalibrationOverlay = false;
  PermissionStatus _permissionStatus = PermissionStatus.granted;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _checkSensorPermission();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkSensorPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (mounted) {
      setState(() => _permissionStatus = status);
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (mounted) {
      setState(() => _permissionStatus = status);
    }
  }

  void _onCompassUpdate(double heading, double qiblaDir) {
    final diff = ((heading - qiblaDir + 360) % 360);
    final alignedDiff = diff > 180 ? 360 - diff : diff;
    final isAligned = alignedDiff < 2.0;

    if (isAligned && !_wasAligned) {
      HapticFeedback.heavyImpact();
    }
    _wasAligned = isAligned;
  }

  @override
  Widget build(BuildContext context) {
    final qiblaDir = ref.watch(qiblaDirectionProvider);
    final distanceKm = ref.watch(distanceToMakkahProvider);
    final compassAsync = ref.watch(compassHeadingProvider);
    final location = ref.watch(userLocationProvider);
    final isDark = context.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCalibrationOverlay
                  ? Icons.explore
                  : Icons.explore_off_outlined,
              color: colorScheme.primary,
            ),
            tooltip: 'معايرة البوصلة',
            onPressed: () => setState(
              () => _showCalibrationOverlay = !_showCalibrationOverlay,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(
            context, qiblaDir, distanceKm, compassAsync, location,
            isDark, colorScheme,
          ),
          if (_showCalibrationOverlay)
            _CalibrationOverlay(
              onDismiss: () {
                setState(() => _showCalibrationOverlay = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    double qiblaDir,
    double distanceKm,
    AsyncValue<double> compassAsync,
    UserLocation location,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ── Location pill ──
          _LocationPill(name: location.name),

          const SizedBox(height: 12),

          // ── Qibla bearing info card ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${qiblaDir.toStringAsFixed(1)}\u00B0',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'اتجاه القبلة من موقعك',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Compass widget ──
          compassAsync.when(
            data: (heading) {
              _onCompassUpdate(heading, qiblaDir);
              final diff = ((qiblaDir - heading + 360) % 360);
              final alignedDiff = diff > 180 ? 360 - diff : diff;
              final isAligned = alignedDiff < 2.0;

              return _CompassWidget(
                heading: heading,
                qiblaDirection: qiblaDir,
                isAligned: isAligned,
                pulseAnimation: _pulseController,
                isDark: isDark,
              );
            },
            loading: () => _buildPermissionOrLoading(isDark),
            error: (error, _) {
              if (_permissionStatus.isDenied ||
                  _permissionStatus.isPermanentlyDenied) {
                return _PermissionWidget(
                  isPermanent: _permissionStatus.isPermanentlyDenied,
                  onRequest: _requestPermission,
                );
              }
              return _ErrorWidget(message: error.toString());
            },
          ),

          const Spacer(),

          // ── Distance to Makkah ──
          if (distanceKm > 0)
            _DistanceBadge(distanceKm: distanceKm),

          const SizedBox(height: 16),

          // ── Instructions ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'وجه الهاتف نحو الاتجاه المشار إليه بالسهم الأخضر للعثور على القبلة',
              style: AppTextStyles.arabicCaption.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: context.bottomPadding + 24),
        ],
      ),
    );
  }

  Widget _buildPermissionOrLoading(bool isDark) {
    if (_permissionStatus.isDenied || _permissionStatus.isPermanentlyDenied) {
      return _PermissionWidget(
        isPermanent: _permissionStatus.isPermanentlyDenied,
        onRequest: _requestPermission,
      );
    }
    return const SizedBox(
      width: 300,
      height: 300,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ── Compass Widget ──────────────────────────────────────────────────────────

class _CompassWidget extends StatelessWidget {
  final double heading;
  final double qiblaDirection;
  final bool isAligned;
  final AnimationController pulseAnimation;
  final bool isDark;

  const _CompassWidget({
    required this.heading,
    required this.qiblaDirection,
    required this.isAligned,
    required this.pulseAnimation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dialAngle = -(heading * math.pi / 180);
    final qiblaAngle = (qiblaDirection - heading) * math.pi / 180;
    final dialColor = isAligned ? AppColors.success : AppColors.primary;

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer glow when aligned ──
          if (isAligned)
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(
                        alpha: 0.15 + 0.15 * pulseAnimation.value,
                      ),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),

          // ── Compass dial (rotates with device heading) ──
          TweenAnimationBuilder<double>(
            tween: Tween(begin: dialAngle, end: dialAngle),
            duration: const Duration(milliseconds: 150),
            builder: (_, angle, __) => Transform.rotate(
              angle: angle,
              child: _CompassDial(isDark: isDark, dialColor: dialColor),
            ),
          ),

          // ── Qibla needle (always points to Makkah) ──
          Transform.rotate(
            angle: qiblaAngle,
            child: _QiblaNeedle(
              isAligned: isAligned,
              pulseAnimation: pulseAnimation,
            ),
          ),

          // ── Center Kaaba icon ──
          _CenterIcon(isDark: isDark, isAligned: isAligned),
        ],
      ),
    );
  }
}

class _QiblaNeedle extends StatelessWidget {
  final bool isAligned;
  final AnimationController pulseAnimation;

  const _QiblaNeedle({
    required this.isAligned,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAligned ? AppColors.success : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arrow head
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (_, __) => Icon(
            Icons.navigation,
            color: color,
            size: isAligned ? (26 + 4 * pulseAnimation.value) : 26,
          ),
        ),
        // Needle body
        Container(
          width: 3,
          height: 95,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _CenterIcon extends StatelessWidget {
  final bool isDark;
  final bool isAligned;

  const _CenterIcon({required this.isDark, required this.isAligned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isAligned
              ? AppColors.success
              : colorScheme.primary.withValues(alpha: 0.3),
          width: isAligned ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAligned ? AppColors.success : Colors.black)
                .withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.mosque,
        color: isAligned ? AppColors.success : colorScheme.primary,
        size: 30,
      ),
    );
  }
}

// ── Compass Dial ────────────────────────────────────────────────────────────

class _CompassDial extends StatelessWidget {
  final bool isDark;
  final Color dialColor;

  const _CompassDial({required this.isDark, required this.dialColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CompassPainter(isDark: isDark, accentColor: dialColor),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final bool isDark;
  final Color accentColor;

  _CompassPainter({required this.isDark, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = isDark
          ? AppColors.textTertiaryDark
          : AppColors.textTertiaryLight
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final northPaint = Paint()
      ..color = AppColors.error
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 360; i += 5) {
      final angle = i * math.pi / 180;
      final isMajor = i % 90 == 0;
      final is30 = i % 30 == 0;

      final tickLen = isMajor ? 22.0 : (is30 ? 14.0 : 8.0);
      final outerR = radius - 5;
      final innerR = outerR - tickLen;

      final start = Offset(
        center.dx + innerR * math.sin(angle),
        center.dy - innerR * math.cos(angle),
      );
      final end = Offset(
        center.dx + outerR * math.sin(angle),
        center.dy - outerR * math.cos(angle),
      );

      final paint =
          i == 0 ? northPaint : (isMajor ? majorTickPaint : tickPaint);
      canvas.drawLine(start, end, paint);
    }

    // Draw cardinal direction labels
    _drawLabel(canvas, center, radius, 'N', 0, AppColors.error, isDark);
    _drawLabel(canvas, center, radius, 'E', 90, null, isDark);
    _drawLabel(canvas, center, radius, 'S', 180, null, isDark);
    _drawLabel(canvas, center, radius, 'W', 270, null, isDark);
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String label,
    double angleDeg,
    Color? overrideColor,
    bool isDark,
  ) {
    final angle = angleDeg * math.pi / 180;
    final r = radius - 36;
    final pos = Offset(
      center.dx + r * math.sin(angle),
      center.dy - r * math.cos(angle),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: overrideColor ??
              (isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.accentColor != accentColor;
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _LocationPill extends StatelessWidget {
  final String name;

  const _LocationPill({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              style: AppTextStyles.titleSmall.copyWith(
                color: colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  final double distanceKm;

  const _DistanceBadge({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final distStr = distanceKm >= 1000
        ? '${(distanceKm / 1000).toStringAsFixed(1)} ألف كم'
        : '${distanceKm.toStringAsFixed(0)} كم';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mosque_outlined,
            color: AppColors.secondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            'المسافة إلى مكة المكرمة: $distStr',
            style: AppTextStyles.arabicBody.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _PermissionWidget extends StatelessWidget {
  final bool isPermanent;
  final VoidCallback onRequest;

  const _PermissionWidget({
    required this.isPermanent,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 300,
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off,
              size: 32,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPermanent
                ? 'إذن الموقع مرفوض بشكل دائم'
                : 'مطلوب إذن الوصول إلى الموقع',
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'يلزم إذن الموقع للحصول على البوصلة الدقيقة',
            style: AppTextStyles.arabicCaption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isPermanent ? () => openAppSettings() : onRequest,
            icon: Icon(isPermanent ? Icons.settings : Icons.location_on),
            label: Text(
              isPermanent ? 'فتح الإعدادات' : 'السماح بالوصول',
              style: AppTextStyles.arabicBody.copyWith(color: Colors.white),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 300,
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 32,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تعذر الوصول إلى البوصلة',
            style: AppTextStyles.arabicBody.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            'تأكد من أن جهازك يدعم البوصلة وأن الإذن ممنوح',
            style: AppTextStyles.arabicCaption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Calibration overlay ─────────────────────────────────────────────────────

class _CalibrationOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const _CalibrationOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'معايرة البوصلة',
                  style: AppTextStyles.arabicHeadline.copyWith(
                    color: Colors.white,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                Text(
                  'لمعايرة البوصلة، حرك الهاتف في حركة رقم ٨ عدة مرات بشكل أفقي.',
                  style: AppTextStyles.arabicBody.copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _FigureEightAnimation(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onDismiss,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'فهمت',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: Colors.white,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FigureEightAnimation extends StatefulWidget {
  @override
  State<_FigureEightAnimation> createState() => _FigureEightAnimationState();
}

class _FigureEightAnimationState extends State<_FigureEightAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _anim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        final x =
            40 * math.cos(t) / (1 + math.sin(t) * math.sin(t));
        final y =
            40 * math.sin(t) * math.cos(t) / (1 + math.sin(t) * math.sin(t));

        return SizedBox(
          width: 100,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(100, 60),
                painter: _Figure8TrailPainter(),
              ),
              Transform.translate(
                offset: Offset(x, y),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
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

class _Figure8TrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    const steps = 200;

    for (var i = 0; i <= steps; i++) {
      final t = 2 * math.pi * i / steps;
      final x =
          cx + 40 * math.cos(t) / (1 + math.sin(t) * math.sin(t));
      final y =
          cy + 40 * math.sin(t) * math.cos(t) / (1 + math.sin(t) * math.sin(t));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
