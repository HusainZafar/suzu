import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chime_settings.dart';

class SettingsService {
  static const _keyInterval = 'interval_minutes';
  static const _keyTonePath = 'custom_tone_path';
  static const _keyEnabled = 'chime_enabled';
  static const _keyScheduleEnabled = 'schedule_enabled';
  static const _keyScheduleStartHour = 'schedule_start_hour';
  static const _keyScheduleStartMinute = 'schedule_start_minute';
  static const _keyScheduleEndHour = 'schedule_end_hour';
  static const _keyScheduleEndMinute = 'schedule_end_minute';
  static const _keyNextChimeAt = 'next_chime_at';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  ChimeSettings load() {
    return ChimeSettings(
      intervalMinutes: _prefs.getInt(_keyInterval) ?? 60,
      customTonePath: _prefs.getString(_keyTonePath),
      enabled: _prefs.getBool(_keyEnabled) ?? false,
      scheduleEnabled: _prefs.getBool(_keyScheduleEnabled) ?? false,
      scheduleStart: TimeOfDay(
        hour: _prefs.getInt(_keyScheduleStartHour) ?? 8,
        minute: _prefs.getInt(_keyScheduleStartMinute) ?? 0,
      ),
      scheduleEnd: TimeOfDay(
        hour: _prefs.getInt(_keyScheduleEndHour) ?? 23,
        minute: _prefs.getInt(_keyScheduleEndMinute) ?? 0,
      ),
    );
  }

  Future<void> save(ChimeSettings settings) async {
    await _prefs.setInt(_keyInterval, settings.intervalMinutes);
    await _prefs.setBool(_keyEnabled, settings.enabled);
    await _prefs.setBool(_keyScheduleEnabled, settings.scheduleEnabled);
    await _prefs.setInt(_keyScheduleStartHour, settings.scheduleStart.hour);
    await _prefs.setInt(_keyScheduleStartMinute, settings.scheduleStart.minute);
    await _prefs.setInt(_keyScheduleEndHour, settings.scheduleEnd.hour);
    await _prefs.setInt(_keyScheduleEndMinute, settings.scheduleEnd.minute);
    if (settings.customTonePath != null) {
      await _prefs.setString(_keyTonePath, settings.customTonePath!);
    } else {
      await _prefs.remove(_keyTonePath);
    }
  }

  DateTime? loadNextChimeAt() {
    final ms = _prefs.getInt(_keyNextChimeAt);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveNextChimeAt(DateTime? nextChimeAt) async {
    if (nextChimeAt != null) {
      await _prefs.setInt(_keyNextChimeAt, nextChimeAt.millisecondsSinceEpoch);
    } else {
      await _prefs.remove(_keyNextChimeAt);
    }
  }
}
