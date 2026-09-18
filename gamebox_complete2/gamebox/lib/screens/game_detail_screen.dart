import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../services/favorites_service.dart';
import '../services/statistics_service.dart';
import '../l10n/app_strings.dart';
import '../games/game_registry.dart';
import 'leaderboard_screen.dart';

class GameDetailScreen extends StatelessWidget {
  final GameModel game;
  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final stats = context.watch<StatisticsService>();
    final strings = context.watch<AppStrings>();
    final isFav = favorites.isFavorite(game.id);

    return Scaffold(
      appBar: AppBar(title: Text(game.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.sports_esports, size: 56, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(label: Text(game.category)),
                const SizedBox(width: 8),
                Icon(Icons.star, size: 16, color: Colors.amber[700]),
                Text(' ${game.rating}'),
                const Spacer(),
                Text(game.sizeLabel),
              ],
            ),
            const SizedBox(height: 12),
            Text(game.description),
            const SizedBox(height: 8),
            Text('${strings.t('high_score')}: ${stats.highScoreFor(game.id)}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(strings.t('play')),
                    onPressed: () {
                      final builder = GameRegistry.widgetFor(game);
                      if (builder == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This game is not implemented yet.')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => builder),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                  label: const Text(''),
                  onPressed: () => favorites.toggle(game.id),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LeaderboardScreen(game: game)),
                  ),
                  child: const Icon(Icons.leaderboard),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
