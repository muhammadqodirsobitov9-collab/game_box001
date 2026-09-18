import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_repository.dart';
import '../services/download_manager_service.dart';
import '../models/game_model.dart';
import '../l10n/app_strings.dart';
import '../widgets/game_card.dart';
import 'game_detail_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GameRepository>();
    final downloads = context.watch<DownloadManagerService>();
    final strings = context.watch<AppStrings>();

    final allGames = <GameModel>[
      ...repo.getAll(),
      ...downloads.installedPackages.map((p) => p.toGameModel()),
    ];
    final categories = allGames.map((g) => g.category).toSet().toList()..sort();

    final q = _query.trim().toLowerCase();
    var results = q.isEmpty
        ? allGames
        : allGames
            .where((g) => g.name.toLowerCase().contains(q) || g.category.toLowerCase().contains(q))
            .toList();
    if (_category != null) {
      results = results.where((g) => g.category == _category).toList();
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('games'))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: strings.t('search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                  ),
                  for (final c in categories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(
                          () => _category = _category == c ? null : c,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('No games found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (context, i) {
                        final game = results[i];
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
      ),
    );
  }
}
