import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_repository.dart';
import '../services/favorites_service.dart';
import '../services/download_manager_service.dart';
import '../l10n/app_strings.dart';
import '../widgets/game_card.dart';
import 'game_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GameRepository>();
    final downloads = context.watch<DownloadManagerService>();
    final favorites = context.watch<FavoritesService>();
    final strings = context.watch<AppStrings>();

    final allGames = [
      ...repo.getAll(),
      ...downloads.installedPackages.map((p) => p.toGameModel()),
    ];
    final games = allGames.where((g) => favorites.isFavorite(g.id)).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(strings.t('favorites'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: games.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Center(
                      child: Text(
                        strings.t('no_favorites'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: games.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, i) {
                      final game = games[i];
                      return GameCard(
                        game: game,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GameDetailScreen(game: game)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
