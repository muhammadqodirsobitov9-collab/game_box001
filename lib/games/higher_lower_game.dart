import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Guess whether the next card is higher or lower than the current
/// one (1-13, ties are a free re-draw). Score = longest streak.
class HigherLowerGame extends StatefulWidget {
  final GameModel game;
  const HigherLowerGame({super.key, required this.game});

  @override
  State<HigherLowerGame> createState() => _HigherLowerGameState();
}

class _HigherLowerGameState extends State<HigherLowerGame> {
  static const _labels = {
    1: 'A', 11: 'J', 12: 'Q', 13: 'K',
  };

  late int _current;
  int _streak = 0;
  int _best = 0;
  bool _gameOver = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _current = 1 + _rand.nextInt(13);
  }

  String _label(int v) => _labels[v] ?? '$v';

  void _guess(bool higher) async {
    if (_gameOver) return;
    final next = 1 + _rand.nextInt(13);
    if (next == _current) {
      setState(() => _current = next); // push, redraw silently
      return;
    }
    final actuallyHigher = next > _current;
    if (actuallyHigher == higher) {
      setState(() {
        _streak++;
        if (_streak > _best) _best = _streak;
        _current = next;
      });
    } else {
      setState(() {
        _gameOver = true;
        _current = next;
      });
      await GameResultHandler.report(context, gameId: widget.game.id, score: _best);
    }
  }

  void _reset() {
    setState(() {
      _current = 1 + _rand.nextInt(13);
      _streak = 0;
      _gameOver = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Streak: $_streak (best $_best)')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 190,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Center(
                  child: Text(_label(_current), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              if (_gameOver) ...[
                Text('${strings.t('game_over')} · Best streak: $_best'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _guess(true),
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('Higher'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => _guess(false),
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('Lower'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
