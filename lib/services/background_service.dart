import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chime_settings.dart';
import 'settings_service.dart';

/// Top-level callback for Android alarm manager.
/// Runs in a background isolate — cannot use audioplayers here.
/// Instead, shows a local notification with the chime sound.
@pragma('vm:entry-point')
Future<void> androidAlarmCallback() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final settingsService = SettingsService(prefs);
    final settings = settingsService.load();

    // Update next chime timestamp regardless
    final nextAt = DateTime.now().add(settings.interval);
    await settingsService.saveNextChimeAt(nextAt);

    if (!settings.enabled) return;
    if (!settings.isWithinSchedule) return;

    // Play chime via notification sound
    final notifications = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await notifications.initialize(initSettings);

    final androidDetails = AndroidNotificationDetails(
      'suzu_chime',
      'Chime',
      importance: Importance.high,
      priority: Priority.high,
      sound: settings.isUsingCustomTone
          ? UriAndroidNotificationSound(settings.customTonePath!)
          : const RawResourceAndroidNotificationSound('default_chime'),
      playSound: true,
      enableVibration: false,
      autoCancel: true,
      timeoutAfter: 5000,
    );
    final details = NotificationDetails(android: androidDetails);

    await notifications.show(
      0,
      'Suzu',
      'Chime',
      details,
    );
  } catch (e) {
    debugPrint('Background chime error: $e');
  }
}

class BackgroundService {
  static const _alarmId = 0;
  static const _notificationId = 0;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();

      // Initialize notifications for Android too (for permission request)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _notifications.initialize(initSettings);
    }

    if (Platform.isIOS) {
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(iOS: iosSettings);
      await _notifications.initialize(initSettings);
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    }

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Requests battery optimization exemption on Android.
  /// Shows a system dialog asking the user to allow unrestricted background usage.
  Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    try {
      const platform = MethodChannel('app.suzu/battery');
      await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('Battery optimization request failed: $e');
    }
  }

  Future<void> startBackgroundChime(ChimeSettings settings) async {
    await stopBackgroundChime();

    final interval = settings.interval;

    if (Platform.isAndroid) {
      await AndroidAlarmManager.periodic(
        interval,
        _alarmId,
        androidAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    } else if (Platform.isIOS) {
      await _scheduleIOSNotifications(settings);
    }
  }

  /// Cancel the current notification (suppress sound when foreground handles it).
  void cancelNotification() {
    _notifications.cancel(_notificationId);
  }

  Future<void> stopBackgroundChime() async {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(_alarmId);
    } else if (Platform.isIOS) {
      await _notifications.cancelAll();
    }
  }

  Future<void> _scheduleIOSNotifications(ChimeSettings settings) async {
    final interval = _toRepeatInterval(settings.intervalMinutes);

    const iosDetails = DarwinNotificationDetails(
      sound: 'default_chime.wav',
      presentAlert: true,
      presentSound: true,
    );
    const details = NotificationDetails(iOS: iosDetails);

    await _notifications.periodicallyShow(
      _notificationId,
      'Suzu',
      'Chime',
      interval,
      details,
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  RepeatInterval _toRepeatInterval(int minutes) {
    if (minutes >= 1440) return RepeatInterval.daily;
    if (minutes >= 60) return RepeatInterval.hourly;
    return RepeatInterval.everyMinute;
  }
}
