import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Classic Minesweeper on an 8x8 board with 10 mines. Long-press to
/// flag. Score on win = 100 - seconds elapsed (min 10); 0 on loss.
class MinesweeperGame extends StatefulWidget {
  final GameModel game;
  const MinesweeperGame({super.key, required this.game});

  @override
  State<MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  static const size = 8;
  static const mineCount = 10;

  late List<bool> _mines;
  late List<int> _adjacent;
  late List<bool> _revealed;
  late List<bool> _flagged;
  bool _gameOver = false;
  bool _won = false;
  final _rand = Random();
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final total = size * size;
    _mines = List.filled(total, false);
    var placed = 0;
    while (placed < mineCount) {
      final i = _rand.nextInt(total);
      if (!_mines[i]) {
        _mines[i] = true;
        placed++;
      }
    }
    _adjacent = List.filled(total, 0);
    for (var i = 0; i < total; i++) {
      if (_mines[i]) continue;
      _adjacent[i] = _neighbors(i).where((n) => _mines[n]).length;
    }
    _revealed = List.filled(total, false);
    _flagged = List.filled(total, false);
    _gameOver = false;
    _won = false;
    _stopwatch
      ..reset()
      ..start();
    setState(() {});
  }

  List<int> _neighbors(int i) {
    final r = i ~/ size, c = i % size;
    final result = <int>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          result.add(nr * size + nc);
        }
      }
    }
    return result;
  }

  void _reveal(int start) {
    if (_gameOver || _revealed[start] || _flagged[start]) return;

    final toVisit = [start];
    var hitMine = false;

    while (toVisit.isNotEmpty) {
      final i = toVisit.removeLast();
      if (_revealed[i] || _flagged[i]) continue;
      _revealed[i] = true;
      if (_mines[i]) {
        hitMine = true;
        continue;
      }
      if (_adjacent[i] == 0) {
        for (final n in _neighbors(i)) {
          if (!_revealed[n] && !_mines[n]) toVisit.add(n);
        }
      }
    }

    setState(() {
      if (hitMine) {
        _gameOver = true;
        for (var j = 0; j < _mines.length; j++) {
          if (_mines[j]) _revealed[j] = true;
        }
      } else {
        final safeLeft =
            _revealed.asMap().entries.where((e) => !_mines[e.key] && !e.value).length;
        if (safeLeft == 0) {
          _gameOver = true;
          _won = true;
        }
      }
    });

    if (hitMine) {
      _finish(won: false);
    } else if (_gameOver && _won) {
      _finish(won: true);
    }
  }

  void _toggleFlag(int i) {
    if (_gameOver || _revealed[i]) return;
    setState(() => _flagged[i] = !_flagged[i]);
  }

  void _finish({required bool won}) async {
    _stopwatch.stop();
    final seconds = _stopwatch.elapsed.inSeconds;
    final score = won ? (100 - seconds).clamp(10, 100) : 0;
    await GameResultHandler.report(context, gameId: widget.game.id, score: score);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_gameOver)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _won ? 'You win! 🎉' : 'Boom! 💥 ${strings.t('restart')} above',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: size,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemCount: size * size,
                      itemBuilder: (context, i) {
                        final revealed = _revealed[i];
                        final flagged = _flagged[i];
                        return GestureDetector(
                          onTap: () => _reveal(i),
                          onLongPress: () => _toggleFlag(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: revealed
                                  ? (_mines[i]
                                      ? Colors.redAccent
                                      : Theme.of(context).colorScheme.surfaceContainerLow)
                                  : Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: revealed
                                  ? (_mines[i]
                                      ? const Icon(Icons.dangerous, size: 16, color: Colors.white)
                                      : (_adjacent[i] > 0
                                          ? Text('${_adjacent[i]}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _numberColor(_adjacent[i]),
                                              ))
                                          : null))
                                  : (flagged ? const Icon(Icons.flag, size: 14, color: Colors.orange) : null),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _numberColor(int n) {
    const colors = [
      Colors.blue, Colors.green, Colors.red, Colors.purple,
      Colors.brown, Colors.teal, Colors.black, Colors.grey,
    ];
    return colors[(n - 1).clamp(0, colors.length - 1)];
  }
}
