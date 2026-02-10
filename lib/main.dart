import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/chime_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = await SettingsService.create();
  final chimeService = ChimeService();

  runApp(ChimeApp(
    settingsService: settingsService,
    chimeService: chimeService,
  ));
}

class ChimeApp extends StatelessWidget {
  final SettingsService settingsService;
  final ChimeService chimeService;

  const ChimeApp({
    super.key,
    required this.settingsService,
    required this.chimeService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suzu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        settingsService: settingsService,
        chimeService: chimeService,
      ),
    );
  }
}
