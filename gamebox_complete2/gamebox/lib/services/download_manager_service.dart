import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/game_package.dart';
import 'local_storage_service.dart';

enum DownloadStatus { notStarted, downloading, paused, completed, failed }

/// Snapshot of one package's download state. Immutable — every change
/// creates a new instance so `ChangeNotifier` listeners always see a
/// consistent value.
class DownloadTask {
  final GamePackage package;
  final DownloadStatus status;
  final double progress; // 0.0 - 1.0

  const DownloadTask({
    required this.package,
    this.status = DownloadStatus.notStarted,
    this.progress = 0.0,
  });

  DownloadTask copyWith({DownloadStatus? status, double? progress}) => DownloadTask(
        package: package,
        status: status ?? this.status,
        progress: progress ?? this.progress,
      );
}

/// Manages the game catalog and everything about getting a package
/// from "available" to "installed and playable" — download queue,
/// per-package progress, pause/resume/cancel, uninstall, and Admin
/// Panel publishing.
///
/// There is no real backend in this build (no server hosts actual
/// game packages yet), so downloading is simulated with a timer whose
/// duration scales with the package's declared size. The state
/// machine, persistence, and UI are all real and don't need to change
/// once a real download source exists — only `_tick()` would swap
/// from a simulated timer to actual byte-progress from an http stream.
///
/// The catalog itself is now two lists merged together: a hardcoded
/// demo list (`_staticCatalog`) and packages published locally through
/// the Admin Panel's ZIP import (`_customPackages`, persisted to
/// disk). Both are treated identically everywhere else in the app.
class DownloadManagerService extends ChangeNotifier {
  static const _installedKey = 'installed_package_ids';
  static const _customPackagesKey = 'admin_custom_packages';

  final LocalStorageService _storage;
  final Map<String, Timer> _timers = {};
  final Map<String, DownloadTask> _tasks = {};
  late Set<String> _installedIds;
  late List<GamePackage> _customPackages;

  DownloadManagerService(this._storage) {
    _installedIds = _storage.getStringList(_installedKey).toSet();
    _customPackages = _loadCustomPackages();
    for (final pkg in catalog) {
      if (_installedIds.contains(pkg.id)) {
        _tasks[pkg.id] = DownloadTask(package: pkg, status: DownloadStatus.completed, progress: 1.0);
      }
    }
  }

  List<GamePackage> _loadCustomPackages() {
    final raw = _storage.getString(_customPackagesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => GamePackage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveCustomPackages() async {
    final raw = jsonEncode(_customPackages.map((p) => p.toJson()).toList());
    await _storage.setString(_customPackagesKey, raw);
  }

  /// The demo remote catalog. In a later stage this would be fetched
  /// from a server; the rest of this class doesn't care where the
  /// list came from. Admin-published packages (see [publishPackage])
  /// are kept separately and merged in via [catalog].
  static const List<GamePackage> _staticCatalog = [
    GamePackage(
      id: 'mini_sudoku',
      name: 'Mini Sudoku',
      category: 'Puzzle',
      description: 'A fast 4x4 sudoku — fill every row, column and box with 1-4.',
      rating: 4.4,
      sizeMB: 3.2,
      engineKey: 'mini_sudoku',
    ),
    GamePackage(
      id: 'match_three',
      name: 'Match Three',
      category: 'Puzzle',
      description: 'Swap adjacent gems to line up 3 or more. Clear the board before you run out of moves.',
      rating: 4.6,
      sizeMB: 5.8,
      engineKey: 'match_three',
    ),
    GamePackage(
      id: 'typing_speed',
      name: 'Typing Speed',
      category: 'Brain',
      description: 'Type the shown sentence as fast and accurately as you can. Measures WPM.',
      rating: 4.2,
      sizeMB: 2.1,
      engineKey: 'typing_speed',
    ),
  ];

  /// Combined catalog: demo packages + anything published through the
  /// Admin Panel.
  List<GamePackage> get catalog => [..._staticCatalog, ..._customPackages];

  // ---- Read API -----------------------------------------------------

  DownloadTask taskFor(String packageId) {
    final pkg = catalog.firstWhere((p) => p.id == packageId);
    return _tasks[packageId] ?? DownloadTask(package: pkg);
  }

  List<GamePackage> get availablePackages =>
      catalog.where((p) => !_installedIds.contains(p.id)).toList();

  List<GamePackage> get installedPackages =>
      catalog.where((p) => _installedIds.contains(p.id)).toList();

  bool isInstalled(String packageId) => _installedIds.contains(packageId);

  // ---- Mutation API ---------------------------------------------------

  void startDownload(String packageId) {
    final pkg = catalog.firstWhere((p) => p.id == packageId);
    final existing = _tasks[packageId];
    if (existing?.status == DownloadStatus.downloading) return;

    _tasks[packageId] = (existing ?? DownloadTask(package: pkg)).copyWith(
      status: DownloadStatus.downloading,
    );
    notifyListeners();
    _tick(packageId);
  }

  void pauseDownload(String packageId) {
    _timers[packageId]?.cancel();
    final task = _tasks[packageId];
    if (task == null) return;
    _tasks[packageId] = task.copyWith(status: DownloadStatus.paused);
    notifyListeners();
  }

  void resumeDownload(String packageId) => startDownload(packageId);

  void cancelDownload(String packageId) {
    _timers[packageId]?.cancel();
    _tasks.remove(packageId);
    notifyListeners();
  }

  Future<void> uninstall(String packageId) async {
    _timers[packageId]?.cancel();
    _tasks.remove(packageId);
    _installedIds.remove(packageId);
    await _storage.setStringList(_installedKey, _installedIds.toList());
    notifyListeners();
  }

  void _tick(String packageId) {
    final task = _tasks[packageId];
    if (task == null) return;
    // Simulated ~1.2 MB/sec, ticking every 150ms.
    final increment = (1.2 * 0.15) / task.package.sizeMB;

    _timers[packageId]?.cancel();
    _timers[packageId] = Timer.periodic(const Duration(milliseconds: 150), (timer) async {
      final current = _tasks[packageId];
      if (current == null || current.status != DownloadStatus.downloading) {
        timer.cancel();
        return;
      }
      final next = (current.progress + increment).clamp(0.0, 1.0);
      if (next >= 1.0) {
        timer.cancel();
        _installedIds.add(packageId);
        await _storage.setStringList(_installedKey, _installedIds.toList());
        _tasks[packageId] = current.copyWith(status: DownloadStatus.completed, progress: 1.0);
      } else {
        _tasks[packageId] = current.copyWith(progress: next);
      }
      notifyListeners();
    });
  }

  // ---- Admin Panel API ------------------------------------------------

  /// Publishes a package parsed from an Admin Panel ZIP import. Unlike
  /// a normal catalog entry, a freshly published package is installed
  /// immediately — the admin already has the content locally, so
  /// there's nothing to simulate downloading.
  Future<void> publishPackage(GamePackage package) async {
    _customPackages.removeWhere((p) => p.id == package.id);
    _customPackages.add(package);
    await _saveCustomPackages();

    _installedIds.add(package.id);
    await _storage.setStringList(_installedKey, _installedIds.toList());
    _tasks[package.id] = DownloadTask(package: package, status: DownloadStatus.completed, progress: 1.0);
    notifyListeners();
  }

  /// Removes an Admin Panel-published package entirely (unlike
  /// [uninstall], which only affects built-in-catalog downloadables,
  /// this also drops it from the catalog so it stops appearing at all).
  Future<void> removePublishedPackage(String packageId) async {
    _timers[packageId]?.cancel();
    _tasks.remove(packageId);
    _installedIds.remove(packageId);
    _customPackages.removeWhere((p) => p.id == packageId);
    await _storage.setStringList(_installedKey, _installedIds.toList());
    await _saveCustomPackages();
    notifyListeners();
  }

  bool get hasCustomPackages => _customPackages.isNotEmpty;
  List<GamePackage> get customPackages => List.unmodifiable(_customPackages);

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}
