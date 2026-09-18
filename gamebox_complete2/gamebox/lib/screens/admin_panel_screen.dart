import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../services/admin_auth_service.dart';
import '../services/download_manager_service.dart';
import '../services/game_repository.dart';
import '../services/statistics_service.dart';
import '../services/progression_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _unlocked = false;
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _pinError;
  Timer? _lockoutTicker;

  void _tryUnlock(AdminAuthService auth) {
    if (auth.isLockedOut) return;
    if (auth.verifyPin(_pinController.text.trim())) {
      setState(() {
        _unlocked = true;
        _pinError = null;
      });
    } else {
      setState(() {
        _pinError = auth.isLockedOut
            ? 'Too many attempts. Locked for ${auth.lockoutSecondsRemaining}s.'
            : 'Incorrect PIN (${auth.attemptsRemaining} attempts left)';
      });
      _startLockoutTickerIfNeeded(auth);
    }
  }

  void _startLockoutTickerIfNeeded(AdminAuthService auth) {
    if (!auth.isLockedOut) return;
    _lockoutTicker?.cancel();
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (!auth.isLockedOut) {
        t.cancel();
        setState(() => _pinError = null);
      } else {
        setState(() => _pinError = 'Too many attempts. Locked for ${auth.lockoutSecondsRemaining}s.');
      }
    });
  }

  void _setupPin(AdminAuthService auth) async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pin.length < 4) {
      setState(() => _pinError = 'PIN must be at least 4 digits');
      return;
    }
    if (pin != confirm) {
      setState(() => _pinError = "PINs don't match");
      return;
    }
    await auth.setPin(pin);
    setState(() {
      _unlocked = true;
      _pinError = null;
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _lockoutTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: SafeArea(
        child: _unlocked
            ? const _AdminDashboard()
            : (auth.hasPin ? _buildUnlockGate(auth) : _buildSetupGate(auth)),
      ),
    );
  }

  Widget _buildSetupGate(AdminAuthService auth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings_outlined, size: 48),
            const SizedBox(height: 16),
            const Text('Set up an admin PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'This PIN is stored only on this device, hashed — not in plaintext.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'New PIN (min 4 digits)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onSubmitted: (_) => _setupPin(auth),
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Confirm PIN'),
              ),
            ),
            if (_pinError != null) ...[
              const SizedBox(height: 8),
              Text(_pinError!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: () => _setupPin(auth), child: const Text('Set PIN & continue')),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockGate(AdminAuthService auth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            const Text('Enter admin PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                enabled: !auth.isLockedOut,
                onSubmitted: (_) => _tryUnlock(auth),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: _pinError,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: auth.isLockedOut ? null : () => _tryUnlock(auth),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  Future<void> _importZip(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final fileData = result.files.first.bytes;
    if (fileData == null) {
      if (context.mounted) {
        _showSnack(context, 'Could not read the selected file.', isError: true);
      }
      return;
    }

    final manager = context.read<DownloadManagerService>();
    try {
      final package = await AdminService.importAndPublish(Uint8List.fromList(fileData), manager);
      if (context.mounted) {
        _showSnack(context, 'Published "${package.name}" — it\'s now installed and playable.');
      }
    } on PackageImportException catch (e) {
      if (context.mounted) _showSnack(context, e.message, isError: true);
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Import failed: $e', isError: true);
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final auth = context.read<AdminAuthService>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change admin PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Current PIN'),
              ),
              TextField(
                controller: newController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'New PIN'),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Confirm new PIN'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!auth.verifyPin(currentController.text.trim())) {
                  setDialogState(() => error = 'Current PIN is incorrect');
                  return;
                }
                if (newController.text.trim().length < 4) {
                  setDialogState(() => error = 'New PIN must be at least 4 digits');
                  return;
                }
                if (newController.text.trim() != confirmController.text.trim()) {
                  setDialogState(() => error = "New PINs don't match");
                  return;
                }
                await auth.setPin(newController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN updated.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GameRepository>();
    final downloads = context.watch<DownloadManagerService>();
    final stats = context.watch<StatisticsService>();
    final progression = context.watch<ProgressionService>();

    final allGames = [
      ...repo.getAll(),
      ...downloads.installedPackages.map((p) => p.toGameModel()),
    ];
    final totalPlays = allGames.fold<int>(0, (sum, g) => sum + stats.playsFor(g.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              onPressed: () => _showChangePinDialog(context),
              icon: const Icon(Icons.key, size: 16),
              label: const Text('Change PIN'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Total games', value: '${allGames.length}')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Total plays', value: '$totalPlays')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Custom packages', value: '${downloads.customPackages.length}')),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Achievements unlocked',
                    value: '${progression.unlockedAchievementIds.length}')),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Publish a game package',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Import a .zip containing a manifest.json (see README) to publish a new '
          'catalog listing backed by one of the built-in engines. It becomes '
          'installed immediately.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _importZip(context),
          icon: const Icon(Icons.upload_file),
          label: const Text('Import ZIP package'),
        ),
        const SizedBox(height: 24),
        const Text('Published packages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (downloads.customPackages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No custom packages published yet.'),
          )
        else
          for (final pkg in downloads.customPackages)
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(pkg.name),
                subtitle: Text('${pkg.category} · engine: ${pkg.engineKey} · v${pkg.version}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Unpublish',
                  onPressed: () => downloads.removePublishedPackage(pkg.id),
                ),
              ),
            ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
