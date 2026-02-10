import 'package:flutter_test/flutter_test.dart';
import 'package:chime_app/main.dart';
import 'package:chime_app/services/settings_service.dart';
import 'package:chime_app/services/chime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsService = SettingsService(prefs);
    final chimeService = ChimeService();

    await tester.pumpWidget(ChimeApp(
      settingsService: settingsService,
      chimeService: chimeService,
    ));

    expect(find.text('Chime'), findsOneWidget);
    expect(find.text('Tap to start'), findsOneWidget);
  });
}
