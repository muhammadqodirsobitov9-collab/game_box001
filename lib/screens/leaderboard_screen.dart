import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../services/leaderboard_service.dart';
import '../services/statistics_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final GameModel game;
  const LeaderboardScreen({super.key, required this.game});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _editName(LeaderboardService leaderboard) {
    _nameController.text = leaderboard.playerName == 'You' ? '' : leaderboard.playerName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your leaderboard name'),
        content: TextField(
          controller: _nameController,
          maxLength: 16,
          decoration: const InputDecoration(hintText: 'Enter a name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await leaderboard.setPlayerName(_nameController.text);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = context.read<LeaderboardService>();
    final stats = context.watch<StatisticsService>();
    final entries = leaderboard.getLeaderboard(widget.game.id, stats);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.game.name} — Leaderboard'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _editName(leaderboard)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo leaderboard — other players are simulated locally since '
                      'this app has no server yet. Your score is real.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: i == 0
                          ? Colors.amber
                          : i == 1
                              ? Colors.grey[400]
                              : i == 2
                                  ? Colors.brown[300]
                                  : Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      e.playerName,
                      style: TextStyle(fontWeight: e.isYou ? FontWeight.bold : FontWeight.normal),
                    ),
                    trailing: Text('${e.score}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    tileColor: e.isYou ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
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
