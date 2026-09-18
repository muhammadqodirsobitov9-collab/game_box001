import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

enum _Choice { rock, paper, scissors }

extension on _Choice {
  IconData get icon => switch (this) {
        _Choice.rock => Icons.circle,
        _Choice.paper => Icons.square_outlined,
        _Choice.scissors => Icons.content_cut,
      };
  String get label => switch (this) {
        _Choice.rock => 'Rock',
        _Choice.paper => 'Paper',
        _Choice.scissors => 'Scissors',
      };
}

/// Best-of-session Rock-Paper-Scissors vs a random CPU. Score = wins
/// this session (reported after every round so the running tally is
/// always saved).
class RockPaperScissorsGame extends StatefulWidget {
  final GameModel game;
  const RockPaperScissorsGame({super.key, required this.game});

  @override
  State<RockPaperScissorsGame> createState() => _RockPaperScissorsGameState();
}

class _RockPaperScissorsGameState extends State<RockPaperScissorsGame> {
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;
  _Choice? _playerChoice;
  _Choice? _cpuChoice;
  String _resultText = 'Choose your move';
  final _rand = Random();

  void _play(_Choice choice) async {
    final cpu = _Choice.values[_rand.nextInt(3)];
    String result;
    if (choice == cpu) {
      _draws++;
      result = "It's a draw!";
    } else if ((choice == _Choice.rock && cpu == _Choice.scissors) ||
        (choice == _Choice.paper && cpu == _Choice.rock) ||
        (choice == _Choice.scissors && cpu == _Choice.paper)) {
      _wins++;
      result = 'You win!';
    } else {
      _losses++;
      result = 'You lose!';
    }
    setState(() {
      _playerChoice = choice;
      _cpuChoice = cpu;
      _resultText = result;
    });
    await GameResultHandler.report(context, gameId: widget.game.id, score: _wins);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · $_wins-$_losses-$_draws')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_playerChoice != null && _cpuChoice != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(children: [
                      Icon(_playerChoice!.icon, size: 48),
                      const Text('You'),
                    ]),
                    const SizedBox(width: 32),
                    const Text('vs', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 32),
                    Column(children: [
                      Icon(_cpuChoice!.icon, size: 48),
                      const Text('CPU'),
                    ]),
                  ],
                ),
              const SizedBox(height: 16),
              Text(_resultText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                children: _Choice.values
                    .map((c) => FilledButton.icon(
                          onPressed: () => _play(c),
                          icon: Icon(c.icon),
                          label: Text(c.label),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text('${strings.t('score')} (wins): $_wins'),
            ],
          ),
        ),
      ),
    );
  }
}
