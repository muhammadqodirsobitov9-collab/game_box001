import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_repository.dart';
import '../services/download_manager_service.dart';
import '../services/statistics_service.dart';
import '../services/progression_service.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../l10n/app_strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GameRepository>();
    final downloads = context.watch<DownloadManagerService>();
    final stats = context.watch<StatisticsService>();
    final progression = context.watch<ProgressionService>();
    final auth = context.watch<AuthService>();
    final leaderboard = context.read<LeaderboardService>();
    final strings = context.watch<AppStrings>();
    final games = [
      ...repo.getAll(),
      ...downloads.installedPackages.map((p) => p.toGameModel()),
    ];
    final theme = Theme.of(context);

    if (auth.isSignedIn) {
      leaderboard.adoptGoogleNameIfUnset(auth.user!.displayName);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (auth.isSignedIn && auth.user!.photoUrl != null)
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(auth.user!.photoUrl!),
                )
              else
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${progression.level}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.isSignedIn
                          ? '${auth.user!.displayName ?? 'Player'} · Level ${progression.level}'
                          : 'Player · Level ${progression.level}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progression.levelProgress.clamp(0, 1),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progression.xpIntoCurrentLevel} / ${progression.xpNeededForNextLevel} XP',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GoogleAccountRow(auth: auth),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.monetization_on,
                  color: Colors.amber[700]!,
                  label: 'Coins',
                  value: '${progression.coins}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.sports_esports,
                  color: theme.colorScheme.primary,
                  label: 'Games played',
                  value: '${progression.totalPlays}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Achievements (${progression.unlockedAchievementIds.length}/${ProgressionService.allAchievements.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final a in ProgressionService.allAchievements)
            _AchievementTile(
              title: a.title,
              description: a.description,
              coinReward: a.coinReward,
              unlocked: progression.unlockedAchievementIds.contains(a.id),
            ),
          const SizedBox(height: 24),
          Text('Game Statistics',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final g in games)
            Card(
              child: ListTile(
                title: Text(g.name),
                subtitle: Text('${strings.t('high_score')}: ${stats.highScoreFor(g.id)}'),
                trailing: Text('${stats.playsFor(g.id)}×'),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoogleAccountRow extends StatelessWidget {
  final AuthService auth;
  const _GoogleAccountRow({required this.auth});

  @override
  Widget build(BuildContext context) {
    if (auth.isSignedIn) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(auth.user!.email),
          subtitle: const Text('Signed in with Google'),
          trailing: TextButton(
            onPressed: () => auth.signOut(),
            child: const Text('Sign out'),
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.login),
        title: const Text('Sign in with Google'),
        subtitle: auth.lastError != null
            ? Text(
                'Last attempt failed — see README "Google Sign-In setup" if this '
                'keeps happening.',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              )
            : const Text('Optional — personalizes your profile and leaderboard name'),
        trailing: auth.isSigningIn
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : FilledButton(
                onPressed: () => auth.signIn(),
                child: const Text('Sign in'),
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String description;
  final int coinReward;
  final bool unlocked;

  const _AchievementTile({
    required this.title,
    required this.description,
    required this.coinReward,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: unlocked ? null : theme.colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Icon(
          unlocked ? Icons.emoji_events : Icons.lock_outline,
          color: unlocked ? Colors.amber[700] : theme.colorScheme.outline,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unlocked ? null : theme.colorScheme.outline,
          ),
        ),
        subtitle: Text(description),
        trailing: Text('+$coinReward \u{1FA99}'),
      ),
    );
  }
}
