import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/local_storage_service.dart';
import '../services/theme_controller.dart';
import '../services/sound_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    final storage = context.read<LocalStorageService>();
    _sound = storage.getBool('sound_enabled') ?? true;
    _vibration = storage.getBool('vibration_enabled') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    final storage = context.read<LocalStorageService>();
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('settings'))),
      body: SafeArea(
        child: ListView(
          children: [
            SwitchListTile(
              title: Text(strings.t('dark_mode')),
              value: themeController.isDark,
              onChanged: (v) => themeController.setDark(v),
            ),
            const Divider(),
            ListTile(
              title: Text(strings.t('language')),
              trailing: DropdownButton<AppLanguage>(
                value: strings.language,
                onChanged: (lang) {
                  if (lang != null) strings.setLanguage(lang);
                },
                items: const [
                  DropdownMenuItem(value: AppLanguage.en, child: Text('English')),
                  DropdownMenuItem(value: AppLanguage.ru, child: Text('Русский')),
                  DropdownMenuItem(value: AppLanguage.uz, child: Text("O'zbekcha")),
                ],
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Sound'),
              value: _sound,
              onChanged: (v) {
                setState(() => _sound = v);
                storage.setBool('sound_enabled', v);
                SoundService.instance.loadPreferences(storage);
              },
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              value: _vibration,
              onChanged: (v) {
                setState(() => _vibration = v);
                storage.setBool('vibration_enabled', v);
                SoundService.instance.loadPreferences(storage);
              },
            ),
            ListTile(
              title: const Text('Test sound & vibration'),
              trailing: const Icon(Icons.volume_up),
              onTap: () => SoundService.instance.celebrate(),
            ),
            const Divider(),
            const ListTile(
              title: Text('About'),
              subtitle: Text('GameBox 1.0.0 — original offline mini-games'),
            ),
            ListTile(
              title: const Text('Reset all data'),
              subtitle: const Text('Clears favorites, high scores and settings'),
              trailing: const Icon(Icons.delete_outline),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset all data?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await storage.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data reset. Restart the app.')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
