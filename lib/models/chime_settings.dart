import 'package:flutter/material.dart';

class ChimeSettings {
  final int intervalMinutes;
  final String? customTonePath;
  final bool enabled;
  final bool scheduleEnabled;
  final TimeOfDay scheduleStart;
  final TimeOfDay scheduleEnd;

  const ChimeSettings({
    this.intervalMinutes = 60,
    this.customTonePath,
    this.enabled = false,
    this.scheduleEnabled = false,
    this.scheduleStart = const TimeOfDay(hour: 8, minute: 0),
    this.scheduleEnd = const TimeOfDay(hour: 23, minute: 0),
  });

  bool get isUsingCustomTone => customTonePath != null;

  /// Whether a chime should fire right now based on schedule.
  bool get isWithinSchedule {
    if (!scheduleEnabled) return true;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = scheduleStart.hour * 60 + scheduleStart.minute;
    final endMin = scheduleEnd.hour * 60 + scheduleEnd.minute;

    if (startMin <= endMin) {
      // Normal range, e.g. 08:00–23:00
      return nowMin >= startMin && nowMin < endMin;
    } else {
      // Overnight range, e.g. 22:00–06:00
      return nowMin >= startMin || nowMin < endMin;
    }
  }

  String get scheduleLabel {
    if (!scheduleEnabled) return 'All day';
    return '${_formatTime(scheduleStart)} to ${_formatTime(scheduleEnd)}';
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  ChimeSettings copyWith({
    int? intervalMinutes,
    String? customTonePath,
    bool clearCustomTone = false,
    bool? enabled,
    bool? scheduleEnabled,
    TimeOfDay? scheduleStart,
    TimeOfDay? scheduleEnd,
  }) {
    return ChimeSettings(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      customTonePath: clearCustomTone ? null : (customTonePath ?? this.customTonePath),
      enabled: enabled ?? this.enabled,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
      scheduleStart: scheduleStart ?? this.scheduleStart,
      scheduleEnd: scheduleEnd ?? this.scheduleEnd,
    );
  }
}
