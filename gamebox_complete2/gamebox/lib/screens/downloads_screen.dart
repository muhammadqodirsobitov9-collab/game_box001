import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_repository.dart';
import '../services/download_manager_service.dart';
import '../l10n/app_strings.dart';
import 'game_detail_screen.dart';

/// Full download manager UI: built-in games are always "Installed";
/// packages from DownloadManagerService.catalog can be downloaded
/// (with a live progress bar), paused, resumed, cancelled, and
/// uninstalled once complete. Installed packages behave exactly like
/// built-in games everywhere else in the app (favorites, stats,
/// progression) because they're converted to the same GameModel.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GameRepository>();
    final downloads = context.watch<DownloadManagerService>();
    final strings = context.watch<AppStrings>();
    final builtIn = repo.getAll();
    final installedPackages = downloads.installedPackages;
    final availablePackages = downloads.availablePackages;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(strings.t('downloads'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Text('Installed', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final g in builtIn)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(g.name),
                subtitle: Text('${g.category} · ${g.sizeLabel} · Built-in'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameDetailScreen(game: g)),
                ),
              ),
            ),
          for (final pkg in installedPackages)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(pkg.name),
                subtitle: Text('${pkg.category} · ${pkg.sizeMB.toStringAsFixed(1)} MB · Downloaded'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameDetailScreen(game: pkg.toGameModel())),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Uninstall',
                  onPressed: () => _confirmUninstall(context, downloads, pkg.id, pkg.name),
                ),
              ),
            ),

          const SizedBox(height: 24),
          Text('Available for download',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (availablePackages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Everything in the current catalog is installed.'),
            )
          else
            for (final pkg in availablePackages)
              _DownloadableCard(packageId: pkg.id),
        ],
      ),
    );
  }

  void _confirmUninstall(BuildContext context, DownloadManagerService downloads, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uninstall game?'),
        content: Text('$name will be removed. Your high scores stay saved if you reinstall it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              downloads.uninstall(id);
              Navigator.pop(ctx);
            },
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}

class _DownloadableCard extends StatelessWidget {
  final String packageId;
  const _DownloadableCard({required this.packageId});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadManagerService>();
    final task = downloads.taskFor(packageId);
    final pkg = task.package;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${pkg.category} · ${pkg.sizeMB.toStringAsFixed(1)} MB',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _actionButton(context, downloads, task),
              ],
            ),
            const SizedBox(height: 6),
            Text(pkg.description, style: Theme.of(context).textTheme.bodySmall),
            if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.paused) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: task.progress, minHeight: 6),
              ),
              const SizedBox(height: 4),
              Text('${(task.progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, DownloadManagerService downloads, DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.notStarted:
      case DownloadStatus.failed:
        return FilledButton.icon(
          onPressed: () => downloads.startDownload(task.package.id),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Get'),
        );
      case DownloadStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause_circle_outline),
              onPressed: () => downloads.pauseDownload(task.package.id),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => downloads.cancelDownload(task.package.id),
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () => downloads.resumeDownload(task.package.id),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => downloads.cancelDownload(task.package.id),
            ),
          ],
        );
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }
}
