import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Result of a location request.
class LocationResult {
  final double latitude;
  final double longitude;
  final String locationName;
  final bool isDefault;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.isDefault = false,
  });

  /// Default location: Makkah Al-Mukarramah.
  static const LocationResult makkah = LocationResult(
    latitude: 21.4225,
    longitude: 39.8262,
    locationName: 'مكة المكرمة',
    isDefault: true,
  );
}

/// Failure type for location errors.
class LocationFailure {
  final String message;
  final bool isPermanentlyDenied;

  const LocationFailure({
    required this.message,
    this.isPermanentlyDenied = false,
  });
}

/// Service to retrieve the device's current GPS location.
///
/// Handles permission requests and falls back to Makkah coordinates
/// when location is unavailable.
class LocationService {
  /// Attempts to get the current device location.
  ///
  /// Returns a [LocationResult] on success, or a [LocationFailure] on error.
  Future<({LocationResult? result, LocationFailure? failure})> getCurrentLocation() async {
    try {
      // Check if location services are enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          result: null,
          failure: const LocationFailure(message: 'خدمات الموقع معطلة. يرجى تفعيلها من الإعدادات.'),
        );
      }

      // Check / request permission.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return (
            result: null,
            failure: const LocationFailure(message: 'تم رفض إذن الوصول إلى الموقع.'),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return (
          result: null,
          failure: const LocationFailure(
            message: 'تم رفض إذن الموقع بشكل دائم. يرجى السماح من إعدادات التطبيق.',
            isPermanentlyDenied: true,
          ),
        );
      }

      // Get position with a reasonable timeout.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      return (
        result: LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          locationName: _coordinatesToLabel(position.latitude, position.longitude),
        ),
        failure: null,
      );
    } catch (e) {
      debugPrint('LocationService error: $e');
      return (
        result: null,
        failure: LocationFailure(message: 'تعذر تحديد موقعك: $e'),
      );
    }
  }

  /// Opens the device app settings for manual permission grant.
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Opens location settings.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Returns a human-readable label for coordinates (simplified).
  String _coordinatesToLabel(double lat, double lng) {
    final latStr = lat.toStringAsFixed(2);
    final lngStr = lng.toStringAsFixed(2);
    return '$latStr° N, $lngStr° E';
  }
}
