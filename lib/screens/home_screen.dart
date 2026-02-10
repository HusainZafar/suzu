import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chime_settings.dart';
import '../services/background_service.dart';
import '../services/chime_service.dart';
import '../services/settings_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settingsService;
  final ChimeService chimeService;
  final BackgroundService? backgroundService;

  const HomeScreen({
    super.key,
    required this.settingsService,
    required this.chimeService,
    this.backgroundService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late ChimeSettings _settings;
  Timer? _countdownTimer;
  Duration _timeUntilNext = Duration.zero;

  static const _intervalOptions = [1, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = widget.settingsService.load();
    if (_settings.enabled) {
      _startChiming();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _settings.enabled) {
      // Sync countdown from persisted timestamp to fix "stuck at 0s" bug
      widget.chimeService.syncFromPersistedTimestamp();
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _tickCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCountdown();
    });
  }

  void _tickCountdown() {
    if (!mounted) return;
    final next = widget.chimeService.nextChimeAt;
    if (next == null) return;
    setState(() {
      _timeUntilNext = next.difference(DateTime.now());
      if (_timeUntilNext.isNegative) {
        _timeUntilNext = Duration.zero;
      }
    });
  }

  void _toggleChime(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(enabled: enabled);
    });
    _save();
    if (enabled) {
      _startChiming();
    } else {
      widget.chimeService.stop();
      widget.backgroundService?.stopBackgroundChime();
      _countdownTimer?.cancel();
    }
  }

  void _selectInterval() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Chime interval',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ..._intervalOptions.map((m) => ListTile(
                  leading: Icon(
                    m == _settings.intervalMinutes
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: m == _settings.intervalMinutes
                        ? Theme.of(ctx).colorScheme.primary
                        : null,
                  ),
                  title: Text(_intervalLabel(m)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _setInterval(m);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _setInterval(int minutes) {
    setState(() {
      _settings = _settings.copyWith(intervalMinutes: minutes);
    });
    _save();
    if (_settings.enabled) {
      _startChiming();
    }
  }

  void _editSchedule() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ScheduleSheet(
        settings: _settings,
        onChanged: (updated) {
          Navigator.pop(ctx);
          setState(() => _settings = updated);
          _save();
          if (_settings.enabled) {
            _startChiming();
          }
        },
      ),
    );
  }

  void _save() {
    widget.settingsService.save(_settings);
  }

  void _startChiming() {
    widget.chimeService.start(_settings);
    widget.backgroundService?.startBackgroundChime(_settings);
    _startCountdown();
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.push<ChimeSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settings: _settings,
          chimeService: widget.chimeService,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _settings = updated);
      _save();
      if (_settings.enabled) {
        _startChiming();
      }
    }
  }

  String _intervalLabel(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      return 'Every $h hour${h > 1 ? 's' : ''}';
    }
    return 'Every $minutes minute${minutes > 1 ? 's' : ''}';
  }

  String _remainingLabel(Duration d) {
    final totalMin = d.inMinutes;
    final sec = d.inSeconds.remainder(60);
    if (totalMin >= 60) {
      final h = totalMin ~/ 60;
      final m = totalMin.remainder(60);
      return 'in ${h}h ${m}m';
    }
    if (totalMin > 0) {
      return 'in $totalMin min ${sec}s';
    }
    return 'in ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = _settings.enabled
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = _settings.enabled
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final dimColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suzu'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top status card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Interval + toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _selectInterval,
                        child: Row(
                          children: [
                            Text(
                              _intervalLabel(_settings.intervalMinutes),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.unfold_more, size: 18, color: dimColor),
                          ],
                        ),
                      ),
                      Switch(
                        value: _settings.enabled,
                        onChanged: _toggleChime,
                      ),
                    ],
                  ),

                  // Row 2: Schedule
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _editSchedule,
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: dimColor),
                        const SizedBox(width: 6),
                        Text(
                          _settings.scheduleLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: dimColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: dimColor),
                      ],
                    ),
                  ),

                  // Row 3: Countdown when active
                  if (_settings.enabled) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _settings.isWithinSchedule
                                ? Colors.green.shade400
                                : Colors.orange.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _settings.isWithinSchedule
                              ? 'Next chime ${_remainingLabel(_timeUntilNext)}'
                              : 'Outside schedule — paused',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

/// Bottom sheet for editing the schedule (enable/disable + start/end times).
class _ScheduleSheet extends StatefulWidget {
  final ChimeSettings settings;
  final ValueChanged<ChimeSettings> onChanged;

  const _ScheduleSheet({
    required this.settings,
    required this.onChanged,
  });

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late bool _enabled;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _enabled = widget.settings.scheduleEnabled;
    _start = widget.settings.scheduleStart;
    _end = widget.settings.scheduleEnd;
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  void _apply() {
    widget.onChanged(widget.settings.copyWith(
      scheduleEnabled: _enabled,
      scheduleStart: _start,
      scheduleEnd: _end,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Schedule', style: theme.textTheme.titleMedium),
                Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_enabled) ...[
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Start',
                      time: _fmt(_start),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
                      label: 'End',
                      time: _fmt(_end),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Chimes will only play between ${_fmt(_start)} and ${_fmt(_end)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              Text(
                'Chimes will play all day when enabled',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _apply,
                child: const Text('Done'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
