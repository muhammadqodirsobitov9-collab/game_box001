import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'l10n/app_strings.dart';
import 'services/local_storage_service.dart';
import 'services/favorites_service.dart';
import 'services/statistics_service.dart';
import 'services/progression_service.dart';
import 'services/game_repository.dart';
import 'services/theme_controller.dart';
import 'services/download_manager_service.dart';
import 'services/sound_service.dart';
import 'services/leaderboard_service.dart';
import 'services/admin_auth_service.dart';
import 'services/auth_service.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = LocalStorageService.instance;
  await storage.init();
  SoundService.instance.loadPreferences(storage);
  runApp(GameBoxApp(storage: storage));
}

class GameBoxApp extends StatelessWidget {
  final LocalStorageService storage;
  const GameBoxApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final onboardingDone = storage.getBool('onboarding_done') ?? false;

    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: storage),
        Provider<GameRepository>(create: (_) => GameRepository()),
        ChangeNotifierProvider<FavoritesService>(
          create: (_) => FavoritesService(storage),
        ),
        ChangeNotifierProvider<StatisticsService>(
          create: (_) => StatisticsService(storage),
        ),
        ChangeNotifierProvider<ProgressionService>(
          create: (_) => ProgressionService(storage),
        ),
        ChangeNotifierProvider<AppStrings>(
          create: (_) => AppStrings(storage),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(storage),
        ),
        ChangeNotifierProvider<DownloadManagerService>(
          create: (_) => DownloadManagerService(storage),
        ),
        Provider<LeaderboardService>(
          create: (_) => LeaderboardService(storage),
        ),
        Provider<AdminAuthService>(
          create: (_) => AdminAuthService(storage),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService()..trySilentSignIn(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // ThemeMode is derived from a stored bool so it survives
          // restarts without needing its own dedicated screen state.
          return _ThemedApp(
            initialHome: onboardingDone ? const MainScaffold() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

class _ThemedApp extends StatefulWidget {
  final Widget initialHome;
  const _ThemedApp({required this.initialHome});

  @override
  State<_ThemedApp> createState() => _ThemedAppState();
}

class _ThemedAppState extends State<_ThemedApp> {
  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'GameBox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeController.isDark ? ThemeMode.dark : ThemeMode.light,
      home: widget.initialHome,
    );
  }
}
