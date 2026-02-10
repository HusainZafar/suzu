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
      await _player.stop();
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
      await _player.stop();
      if (customTonePath != null) {
        await _player.play(DeviceFileSource(customTonePath));
      } else {
        await _player.play(AssetSource('tones/default_chime.wav'));
      }
    } catch (e) {
      debugPrint('Error previewing tone: $e');
    }
  }

  /// Foreground-only mode (web). Starts a timer that plays the chime.
  void startForeground(ChimeSettings settings, {VoidCallback? onChime}) {
    stop();
    final interval = settings.interval;
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

  /// Background mode (Android/iOS). No foreground timer — background service
  /// is the source of truth. We just record nextChimeAt for the countdown UI.
  void startWithBackground(ChimeSettings settings) {
    _timer?.cancel();
    _timer = null;
    _nextChimeAt = DateTime.now().add(settings.interval);
    _settingsService.saveNextChimeAt(_nextChimeAt);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _nextChimeAt = null;
    _settingsService.saveNextChimeAt(null);
  }

  /// Syncs the countdown from the persisted nextChimeAt timestamp.
  /// Called on app resume so the countdown reflects reality.
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
