import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Classic 15-puzzle: arrange tiles 1-15 in order by sliding into the
/// empty slot. Score = max(0, 1000 - moves*5).
class SlidingPuzzleGame extends StatefulWidget {
  final GameModel game;
  const SlidingPuzzleGame({super.key, required this.game});

  @override
  State<SlidingPuzzleGame> createState() => _SlidingPuzzleGameState();
}

class _SlidingPuzzleGameState extends State<SlidingPuzzleGame> {
  static const size = 4;
  late List<int> _tiles; // 0 = empty
  int _moves = 0;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _tiles = List.generate(size * size, (i) => i);
    _shuffle();
    _moves = 0;
    _solved = false;
    setState(() {});
  }

  void _shuffle() {
    // Perform many valid random slides so the puzzle is always solvable.
    final rand = DateTime.now().millisecondsSinceEpoch;
    var seed = rand;
    int nextRand(int max) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed % max;
    }

    for (var i = 0; i < 300; i++) {
      final emptyIndex = _tiles.indexOf(0);
      final neighbors = _neighborIndices(emptyIndex);
      final swapWith = neighbors[nextRand(neighbors.length)];
      final tmp = _tiles[emptyIndex];
      _tiles[emptyIndex] = _tiles[swapWith];
      _tiles[swapWith] = tmp;
    }
  }

  List<int> _neighborIndices(int i) {
    final r = i ~/ size, c = i % size;
    final result = <int>[];
    if (r > 0) result.add(i - size);
    if (r < size - 1) result.add(i + size);
    if (c > 0) result.add(i - 1);
    if (c < size - 1) result.add(i + 1);
    return result;
  }

  void _tap(int i) async {
    if (_solved) return;
    final emptyIndex = _tiles.indexOf(0);
    if (_neighborIndices(i).contains(emptyIndex)) {
      setState(() {
        _tiles[emptyIndex] = _tiles[i];
        _tiles[i] = 0;
        _moves++;
        _solved = _checkSolved();
      });
      if (_solved) {
        final score = (1000 - _moves * 5).clamp(0, 1000);
        await GameResultHandler.report(context, gameId: widget.game.id, score: score);
      }
    }
  }

  bool _checkSolved() {
    for (var i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles.last == 0;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Moves: $_moves')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_solved)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Solved! 🎉', style: Theme.of(context).textTheme.titleLarge),
                ),
              SizedBox(
                width: 300,
                height: 300,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _tiles.length,
                  itemBuilder: (context, i) {
                    final v = _tiles[i];
                    return GestureDetector(
                      onTap: () => _tap(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: v == 0
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: v == 0
                              ? null
                              : Text('$v', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      ),
    );
  }
}
