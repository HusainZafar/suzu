import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/chime_settings.dart';
import 'settings_service.dart';

class ChimeService {
  final AudioPlayer _player = AudioPlayer();
  final SettingsService _settingsService;
  Timer? _timer;
  DateTime? _nextChimeAt;

  ChimeService(this._settingsService);

  Future<void> playChime(ChimeSettings settings) async {
    try {
      if (settings.isUsingCustomTone) {
        await _player.play(DeviceFileSource(settings.customTonePath!));
      } else {
        await _player.play(AssetSource('tones/default_chime.wav'));
      }
    } catch (e) {
      debugPrint('Error playing chime: $e');
    }
  }

  Future<void> previewTone(String? customTonePath) async {
    try {
      if (customTonePath != null) {
        await _player.play(DeviceFileSource(customTonePath));
      } else {
        await _player.play(AssetSource('tones/default_chime.wav'));
      }
    } catch (e) {
      debugPrint('Error previewing tone: $e');
    }
  }

  /// Starts chiming with a full interval from now.
  /// Respects schedule — skips chime if outside active hours.
  void start(ChimeSettings settings, {VoidCallback? onChime}) {
    stop();
    final interval = Duration(minutes: settings.intervalMinutes);
    _nextChimeAt = DateTime.now().add(interval);
    _settingsService.saveNextChimeAt(_nextChimeAt);

    _timer = Timer.periodic(interval, (_) {
      _nextChimeAt = DateTime.now().add(interval);
      _settingsService.saveNextChimeAt(_nextChimeAt);
      if (settings.isWithinSchedule) {
        playChime(settings);
      }
      onChime?.call();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _nextChimeAt = null;
    _settingsService.saveNextChimeAt(null);
  }

  /// Syncs the countdown from the persisted nextChimeAt timestamp.
  /// Called on app resume to fix the "stuck at 0s" bug.
  void syncFromPersistedTimestamp() {
    final stored = _settingsService.loadNextChimeAt();
    if (stored != null) {
      _nextChimeAt = stored;
    }
  }

  DateTime? get nextChimeAt => _nextChimeAt;

  void dispose() {
    stop();
    _player.dispose();
  }
}
