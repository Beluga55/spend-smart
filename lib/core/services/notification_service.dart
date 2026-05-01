import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'daily_reminder';
  static const _notifId = 0;

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    // Request notification permission on Android 13+
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _plugin.cancelAll();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Daily Reminder',
      channelDescription: 'Reminds you to log expenses',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.periodicallyShow(
      _notifId,
      'Expense Tracker',
      "Don't forget to log today's expenses!",
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    final box = Hive.box('settings');
    await box.put('reminderHour', time.hour);
    await box.put('reminderMinute', time.minute);
    await box.put('reminderEnabled', true);
  }

  static Future<void> cancelReminder() async {
    await _plugin.cancelAll();
    await Hive.box('settings').put('reminderEnabled', false);
  }
}
