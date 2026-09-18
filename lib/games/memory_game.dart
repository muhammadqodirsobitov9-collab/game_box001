import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Classic pairs-matching memory puzzle. Score = 1000 - (10 per move),
/// floored at 0, rewarding fewer tries. Uses Material icons instead of
/// external art so it needs no assets.
class MemoryGame extends StatefulWidget {
  final GameModel game;
  const MemoryGame({super.key, required this.game});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  static const _icons = [
    Icons.star, Icons.favorite, Icons.bolt, Icons.pets,
    Icons.anchor, Icons.local_fire_department, Icons.ac_unit, Icons.diamond,
  ];

  late List<IconData> _cards;
  late List<bool> _revealed;
  late List<bool> _matched;
  final List<int> _selected = [];
  int _moves = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final pairs = [..._icons, ..._icons];
    pairs.shuffle(Random());
    _cards = pairs;
    _revealed = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    _selected.clear();
    _moves = 0;
    _busy = false;
    setState(() {});
  }

  void _tap(int i) {
    if (_busy || _revealed[i] || _matched[i]) return;
    setState(() => _revealed[i] = true);
    _selected.add(i);

    if (_selected.length == 2) {
      _moves++;
      final a = _selected[0], b = _selected[1];
      if (_cards[a] == _cards[b]) {
        setState(() {
          _matched[a] = true;
          _matched[b] = true;
        });
        _selected.clear();
        if (_matched.every((m) => m)) _finish();
      } else {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            _revealed[a] = false;
            _revealed[b] = false;
            _busy = false;
          });
          _selected.clear();
        });
      }
    }
  }

  void _finish() async {
    final score = max(0, 1000 - _moves * 10);
    await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solved!'),
        content: Text('Moves: $_moves\nScore: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reset();
            },
            child: const Text('Play again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Moves: $_moves')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, i) {
              final shown = _revealed[i] || _matched[i];
              return GestureDetector(
                onTap: () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _matched[i]
                        ? Colors.green.withValues(alpha: 0.4)
                        : shown
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: shown
                        ? Icon(_cards[i], size: 28)
                        : Icon(Icons.help_outline,
                            size: 22,
                            color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reset,
        icon: const Icon(Icons.refresh),
        label: Text(strings.t('restart')),
      ),
    );
  }
}
