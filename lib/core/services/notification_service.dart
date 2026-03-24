import 'package:flutter/foundation.dart';

/// Notification channel identifiers.
abstract final class NotificationChannels {
  static const String adhan = 'adhan_channel';
  static const String dailyAyah = 'daily_ayah_channel';
  static const String adhkar = 'adhkar_channel';
}

/// Represents a scheduled prayer notification.
class PrayerNotification {
  final int id;
  final String prayerName;
  final String prayerNameArabic;
  final DateTime scheduledTime;
  final bool isEnabled;

  const PrayerNotification({
    required this.id,
    required this.prayerName,
    required this.prayerNameArabic,
    required this.scheduledTime,
    this.isEnabled = true,
  });
}

/// Service for scheduling and managing prayer-time notifications.
///
/// Uses platform notifications (via flutter_local_notifications when integrated).
/// Currently provides the interface and logging stub for production readiness.
class NotificationService {
  static const _prayerIds = {
    'Fajr': 1,
    'Dhuhr': 2,
    'Asr': 3,
    'Maghrib': 4,
    'Isha': 5,
    'DailyAyah': 10,
    'MorningAdhkar': 11,
    'EveningAdhkar': 12,
  };

  /// Initialise notification channels and permissions.
  ///
  /// Must be called once during app startup.
  Future<void> initialize() async {
    debugPrint('[NotificationService] Initialized notification channels.');
    // TODO: Initialize flutter_local_notifications plugin.
    // final plugin = FlutterLocalNotificationsPlugin();
    // await plugin.initialize(initSettings, ...);
  }

  /// Schedule Adhan notifications for all enabled prayers today.
  Future<void> schedulePrayerNotifications(
    List<PrayerNotification> notifications,
  ) async {
    for (final notification in notifications) {
      if (!notification.isEnabled) {
        await cancelNotification(notification.id);
        continue;
      }

      final now = DateTime.now();
      if (notification.scheduledTime.isBefore(now)) continue;

      debugPrint(
        '[NotificationService] Scheduling ${notification.prayerNameArabic} '
        'at ${notification.scheduledTime}',
      );

      // TODO: Schedule via flutter_local_notifications
      // await plugin.zonedSchedule(
      //   notification.id,
      //   'حان وقت ${notification.prayerNameArabic}',
      //   'وقت الصلاة',
      //   tz.TZDateTime.from(notification.scheduledTime, tz.local),
      //   notificationDetails,
      //   ...
      // );
    }
  }

  /// Schedule the daily Ayah notification.
  Future<void> scheduleDailyAyah({
    required DateTime scheduledTime,
    required bool isEnabled,
  }) async {
    if (!isEnabled) {
      await cancelNotification(_prayerIds['DailyAyah']!);
      return;
    }

    debugPrint('[NotificationService] Scheduling daily Ayah at $scheduledTime');
    // TODO: Implement with flutter_local_notifications
  }

  /// Schedule morning and evening Adhkar reminders.
  Future<void> scheduleAdhkarReminders({
    required bool morningEnabled,
    required bool eveningEnabled,
  }) async {
    if (!morningEnabled) {
      await cancelNotification(_prayerIds['MorningAdhkar']!);
    } else {
      debugPrint('[NotificationService] Scheduling morning Adhkar.');
      // TODO: Schedule at ~6 AM local time
    }

    if (!eveningEnabled) {
      await cancelNotification(_prayerIds['EveningAdhkar']!);
    } else {
      debugPrint('[NotificationService] Scheduling evening Adhkar.');
      // TODO: Schedule at ~4 PM local time
    }
  }

  /// Cancel a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    debugPrint('[NotificationService] Cancelling notification $id.');
    // TODO: plugin.cancel(id);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    debugPrint('[NotificationService] Cancelling all notifications.');
    // TODO: plugin.cancelAll();
  }

  /// Request notification permission (iOS / Android 13+).
  Future<bool> requestPermission() async {
    debugPrint('[NotificationService] Requesting notification permission.');
    // TODO: Request via permission_handler or plugin.
    return true;
  }

  /// Returns the notification ID for a prayer name.
  int idForPrayer(String prayerName) {
    return _prayerIds[prayerName] ?? 0;
  }
}
