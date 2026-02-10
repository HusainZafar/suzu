import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chime_settings.dart';
import '../services/chime_service.dart';

class SettingsScreen extends StatefulWidget {
  final ChimeSettings settings;
  final ChimeService chimeService;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.chimeService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ChimeSettings _settings;

  static const _maxToneSizeBytes = 500 * 1024; // 500 KB
  // TODO: Replace with your actual link
  static const _coffeeUrl = 'https://buymeacoffee.com/yourname';

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  Future<void> _pickCustomTone() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // Validate file size
    final fileSize = file.size;
    if (fileSize > _maxToneSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large. Max size is 500 KB.')),
        );
      }
      return;
    }

    // Copy to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final tonesDir = Directory('${appDir.path}/tones');
    if (!await tonesDir.exists()) {
      await tonesDir.create(recursive: true);
    }

    final sourcePath = file.path;
    if (sourcePath == null) return;

    final fileName = file.name;
    final destPath = '${tonesDir.path}/$fileName';
    await File(sourcePath).copy(destPath);

    setState(() {
      _settings = _settings.copyWith(customTonePath: destPath);
    });
  }

  void _resetToDefault() {
    setState(() {
      _settings = _settings.copyWith(clearCustomTone: true);
    });
  }

  void _previewTone() {
    widget.chimeService.previewTone(_settings.customTonePath);
  }

  Future<void> _openCoffeeLink() async {
    final uri = Uri.parse(_coffeeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _settings),
          ),
        ),
        body: ListView(
          children: [
            // --- Tone Section ---
            _SectionHeader(title: 'Chime Tone'),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(
                _settings.isUsingCustomTone ? _toneName() : 'Default chime',
              ),
              subtitle: _settings.isUsingCustomTone
                  ? const Text('Custom tone')
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: _previewTone,
                tooltip: 'Preview',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickCustomTone,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload tone'),
                    ),
                  ),
                  if (_settings.isUsingCustomTone) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetToDefault,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset default'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Supported: MP3, WAV, AAC. Max 500 KB.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const Divider(height: 32),

            // --- Support Section ---
            ListTile(
              leading: const Icon(Icons.coffee, color: Colors.brown),
              title: const Text('Buy me a coffee'),
              subtitle: const Text('Support the developer'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: _openCoffeeLink,
            ),
          ],
        ),
    );
  }

  String _toneName() {
    if (_settings.customTonePath == null) return 'Default';
    final parts = _settings.customTonePath!.split('/');
    return parts.last;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
