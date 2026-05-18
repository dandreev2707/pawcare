import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String petName,
    required DateTime scheduledAt,
  }) async {
    await init();
    final scheduled = tz.TZDateTime.from(scheduledAt, tz.local);
    if (scheduled.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      '🐾 $petName',
      title,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pawcare_reminders',
          'Напоминания PawCare',
          channelDescription: 'Напоминания о процедурах для питомцев',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  static int idFromReminderId(String reminderId) =>
      reminderId.hashCode.abs() % 100000;
}
