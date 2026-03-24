import 'package:flutter/material.dart';

/// Convenience extensions on [BuildContext] for quick access to
/// commonly used properties throughout the app.
extension BuildContextExtensions on BuildContext {
  // ── Theme ──
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // ── Media Query ──
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  double get topPadding => padding.top;
  double get bottomPadding => padding.bottom;
  Orientation get orientation => mediaQuery.orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;
  double get textScaleFactor => mediaQuery.textScaler.scale(1.0);

  // ── Responsive Breakpoints ──
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  bool get isLargeScreen => screenWidth >= 600 && screenWidth < 900;
  bool get isTablet => screenWidth >= 600;
  bool get isDesktop => screenWidth >= 900;

  // ── Directionality ──
  TextDirection get textDirection => Directionality.of(this);
  bool get isRtl => textDirection == TextDirection.rtl;
  bool get isLtr => textDirection == TextDirection.ltr;

  // ── Navigation ──
  NavigatorState get navigator => Navigator.of(this);
  void pop<T>([T? result]) => navigator.pop(result);
  bool get canPop => navigator.canPop();

  // ── Snack Bar ──
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show a success snackbar with green styling.
  void showSuccess(String message) {
    showSnackBar(
      message,
      backgroundColor: colorScheme.primary,
    );
  }

  /// Show an error snackbar with red styling.
  void showError(String message) {
    showSnackBar(
      message,
      backgroundColor: colorScheme.error,
    );
  }

  // ── Focus ──
  void unfocus() => FocusScope.of(this).unfocus();
}

/// Extensions on [String] for Arabic text utilities.
extension ArabicStringExtensions on String {
  /// Whether this string contains Arabic characters.
  bool get containsArabic => RegExp(r'[\u0600-\u06FF]').hasMatch(this);

  /// Returns the string with Arabic numerals replaced by Eastern Arabic numerals.
  String get toArabicNumerals {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = this;
    for (var i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], eastern[i]);
    }
    return result;
  }
}

/// Extensions on [int] for formatting.
extension IntExtensions on int {
  /// Convert an integer to Eastern Arabic numeral string.
  String get toArabicNumeral => toString().toArabicNumerals;

  /// Format duration from seconds to mm:ss.
  String get toTimerString {
    final minutes = this ~/ 60;
    final seconds = this % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Extensions on [Duration] for formatting.
extension DurationExtensions on Duration {
  /// Format as mm:ss.
  String get formatted {
    final mins = inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  /// Format as hh:mm:ss.
  String get formattedLong {
    final hours = inHours.toString().padLeft(2, '0');
    final mins = inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }
}
