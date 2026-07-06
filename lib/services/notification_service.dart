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

  static const int _baseId = 1001;
  static const int _reminderHour = 10;

  // Reminders fire around two periods a year: just before/after New Year, and
  // mid-year. [month, day] pairs, each recurs annually.
  static const List<List<int>> _reminderDates = [
    [12, 28], // before New Year
    [1, 2], // just after New Year
    [6, 28], // mid-year
    [7, 1], // mid-year
  ];

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

  /// Schedule the twice-a-year cleanup reminders. Re-scheduling replaces any
  /// previous ones (e.g. after a language change).
  Future<void> scheduleReminders({
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    for (int i = 0; i < _reminderDates.length; i++) {
      final d = _reminderDates[i];
      await _plugin.zonedSchedule(
        _baseId + i,
        title,
        body,
        _nextDate(d[0], d[1]),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cleanup_reminders',
            'Cleanup reminders',
            channelDescription: 'Seasonal reminder to clean up your photos',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Recur every year on this month/day/time.
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  /// Next occurrence of [month]/[day] at [_reminderHour], in the future.
  tz.TZDateTime _nextDate(int month, int day) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, month, day, _reminderHour);
    if (!scheduled.isAfter(now)) {
      scheduled =
          tz.TZDateTime(tz.local, now.year + 1, month, day, _reminderHour);
    }
    return scheduled;
  }
}
