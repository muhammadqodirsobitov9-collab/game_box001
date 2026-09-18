import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_repository.dart';
import '../services/download_manager_service.dart';
import '../l10n/app_strings.dart';
import '../widgets/game_card.dart';
import 'game_detail_screen.dart';
import 'games_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GameRepository>();
    final downloads = context.watch<DownloadManagerService>();
    final strings = context.watch<AppStrings>();

    final installed = downloads.installedPackages.map((p) => p.toGameModel()).toList();
    final popular = [...repo.getPopular(), ...installed.where((g) => g.rating >= 4.5)];
    // Newly-downloaded games count as "new" alongside built-in ones
    // flagged isNew, so a fresh install shows up right where players
    // expect it without any separate "recently added" section.
    final fresh = [
      ...repo.getNew(),
      ...downloads.installedPackages.map((p) => p.toGameModel(isNew: true)),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GamesScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 10),
                  Text(strings.t('search_hint'),
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: strings.t('popular')),
          const SizedBox(height: 8),
          _GameGrid(games: popular),
          const SizedBox(height: 20),
          _SectionHeader(title: strings.t('new_games')),
          const SizedBox(height: 8),
          _GameGrid(games: fresh),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _GameGrid extends StatelessWidget {
  final List games;
  const _GameGrid({required this.games});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('—'),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
          ),
        );
      },
    );
  }
}
