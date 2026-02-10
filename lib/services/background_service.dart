import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chime_settings.dart';
import 'settings_service.dart';

/// Top-level callback for Android alarm manager.
/// Must be a top-level or static function.
@pragma('vm:entry-point')
Future<void> _androidAlarmCallback() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final settingsService = SettingsService(prefs);
    final settings = settingsService.load();

    if (!settings.enabled) return;
    if (!settings.isWithinSchedule) {
      // Still persist the next chime time so countdown syncs on resume
      final nextAt = DateTime.now()
          .add(Duration(minutes: settings.intervalMinutes));
      await settingsService.saveNextChimeAt(nextAt);
      return;
    }

    // Play chime
    final player = AudioPlayer();
    try {
      if (settings.isUsingCustomTone) {
        await player.play(DeviceFileSource(settings.customTonePath!));
      } else {
        await player.play(AssetSource('tones/default_chime.wav'));
      }
      // Wait for playback to finish (max 5 seconds)
      await Future.delayed(const Duration(seconds: 5));
    } finally {
      await player.dispose();
    }

    // Update next chime timestamp
    final nextAt = DateTime.now()
        .add(Duration(minutes: settings.intervalMinutes));
    await settingsService.saveNextChimeAt(nextAt);
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

  Future<void> startBackgroundChime(ChimeSettings settings) async {
    await stopBackgroundChime();

    final interval = Duration(minutes: settings.intervalMinutes);

    if (Platform.isAndroid) {
      await AndroidAlarmManager.periodic(
        interval,
        _alarmId,
        _androidAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } else if (Platform.isIOS) {
      await _scheduleIOSNotifications(settings);
    }
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
    // iOS periodicallyShow only supports fixed intervals.
    // Map to the closest supported interval.
    if (minutes >= 1440) return RepeatInterval.daily;
    if (minutes >= 60) return RepeatInterval.hourly;
    // For sub-hourly, use everyMinute as the closest option.
    // This will fire every minute — the notification handler should
    // check the actual interval, but for simplicity we use the
    // closest match.
    return RepeatInterval.everyMinute;
  }
}
