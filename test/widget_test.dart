import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamebox/main.dart';
import 'package:gamebox/services/local_storage_service.dart';
import 'package:gamebox/screens/onboarding_screen.dart';
import 'package:gamebox/widgets/main_scaffold.dart';

Future<LocalStorageService> freshStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorageService.instance;
  storage.resetForTesting();
  await storage.init();
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows onboarding on first launch', (tester) async {
    final storage = await freshStorage();

    await tester.pumpWidget(GameBoxApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('skips onboarding and shows the main scaffold once onboarding_done is set', (tester) async {
    final storage = await freshStorage();
    await storage.setBool('onboarding_done', true);

    await tester.pumpWidget(GameBoxApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.byType(MainScaffold), findsOneWidget);
    expect(find.text('GameBox'), findsWidgets);
  });

  testWidgets('bottom navigation has all 5 destinations', (tester) async {
    final storage = await freshStorage();
    await storage.setBool('onboarding_done', true);

    await tester.pumpWidget(GameBoxApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
}
