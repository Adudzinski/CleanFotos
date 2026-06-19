import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local (on-device) notifications. Used for the monthly "clean up your photos"
/// reminder. No server / push service required.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _monthlyId = 1001;

  // Reminder fires on this day-of-month at this hour (local time).
  static const int _reminderDayOfMonth = 1;
  static const int _reminderHour = 10;

  bool _ready = false;

  /// Initialize the plugin and the timezone database. Call once at startup.
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final String tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // Falls back to the default location; monthly timing tolerates this.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  /// Ask the OS for notification permission (Android 13+, iOS). Returns true if
  /// granted (or not required).
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? true;
    }
    if (ios != null) {
      granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true) ??
              true;
    }
    return granted;
  }

  /// Schedule a repeating monthly reminder. Re-scheduling with the same id
  /// replaces the previous one (e.g. after a language change).
  Future<void> scheduleMonthlyReminder({
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      _monthlyId,
      title,
      body,
      _nextReminderDate(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cleanup_reminders',
          'Cleanup reminders',
          channelDescription: 'Monthly reminder to clean up your photos',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> cancelMonthlyReminder() => _plugin.cancel(_monthlyId);

  /// Next occurrence of [_reminderDayOfMonth] at [_reminderHour], in the future.
  tz.TZDateTime _nextReminderDate() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, _reminderDayOfMonth, _reminderHour);
    if (!scheduled.isAfter(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final year = now.month == 12 ? now.year + 1 : now.year;
      scheduled = tz.TZDateTime(
          tz.local, year, nextMonth, _reminderDayOfMonth, _reminderHour);
    }
    return scheduled;
  }
}
