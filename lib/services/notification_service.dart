import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Real OS notifications (Android/iOS). No-ops on web.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _dailyId = 1001;
  static const String _channelId = 'budgetmo_alerts_v2';
  static bool _ready = false;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    _channelId,
    'BudgetMo Alerts',
    description: 'Reminders to log your spending',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  static AndroidNotificationDetails _android() => AndroidNotificationDetails(
        _channelId,
        'BudgetMo Alerts',
        channelDescription: 'Reminders to log your spending',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        vibrationPattern: Int64List.fromList([0, 600, 250, 600]),
      );

  static const DarwinNotificationDetails _ios = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static NotificationDetails _details() =>
      NotificationDetails(android: _android(), iOS: _ios);

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}
    try {
      const android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
          const InitializationSettings(android: android, iOS: ios));
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(_channel);
      _ready = true;
    } catch (_) {}
  }

  /// iOS permission prompt (no-op on Android — the iOS impl is null there).
  static Future<void> requestIOSPermissions() async {
    if (kIsWeb) return;
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  static Future<bool> areEnabled() async {
    if (kIsWeb) return false;
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return (await androidImpl.areNotificationsEnabled()) ?? false;
      }
      // iOS / others: assume enabled — the permission prompt governs it.
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> requestExactAlarms() async {
    if (kIsWeb) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  /// Immediate test notification. Returns null on success, else a readable
  /// reason it failed (so the UI can show what's wrong).
  static Future<String?> showNow() async {
    if (kIsWeb) return 'Notifications don\'t run on web — try on the phone.';
    if (!_ready) await init();
    if (!_ready) return 'Notification plugin failed to initialize.';
    if (!await areEnabled()) {
      return 'Notifications are turned OFF for BudgetMo in system settings.';
    }
    try {
      await _plugin.show(
        9999,
        '🔔 BudgetMo test',
        'Notifications are working! 🎉',
        _details(),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Schedules a daily notification at [hour]:[minute], even when closed.
  static Future<void> scheduleDaily(int hour, int minute) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    final body =
        "Time to log today's spending so your week stays accurate 💸";
    Future<void> schedule(AndroidScheduleMode mode) async {
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);
      if (!when.isAfter(now)) {
        when = when.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        _dailyId,
        '🔔 BudgetMo reminder',
        body,
        when,
        _details(),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    try {
      await _plugin.cancel(_dailyId);
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      // Exact alarms blocked → fall back to inexact.
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (_) {}
    }
  }

  static Future<void> cancel() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(_dailyId);
    } catch (_) {}
  }
}
