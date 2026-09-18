import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Navigate from the top-left to the bottom-right of a randomly
/// generated maze using swipe gestures. Score = max(0, 500 - moves*5).
class MazeEscapeGame extends StatefulWidget {
  final GameModel game;
  const MazeEscapeGame({super.key, required this.game});

  @override
  State<MazeEscapeGame> createState() => _MazeEscapeGameState();
}

class _MazeEscapeGameState extends State<MazeEscapeGame> {
  static const size = 9;
  late List<List<Set<int>>> _openSet; // openSet[r][c] = set of reachable neighbor indices (r*size+c)
  late Point<int> _player;
  late Point<int> _goal;
  int _moves = 0;
  bool _won = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _generateMaze();
    _player = const Point(0, 0);
    _goal = Point(size - 1, size - 1);
    _moves = 0;
    _won = false;
    setState(() {});
  }

  void _generateMaze() {
    // Recursive backtracker: carves a spanning tree over the grid, so
    // there's always exactly one path between any two cells (plus the
    // occasional extra connection isn't added — kept simple).
    _openSet = List.generate(size, (_) => List.generate(size, (_) => <int>{}));
    final visited = List.generate(size, (_) => List.filled(size, false));

    void carve(int r, int c) {
      visited[r][c] = true;
      final dirs = [
        [-1, 0], [1, 0], [0, -1], [0, 1],
      ]..shuffle(_rand);
      for (final d in dirs) {
        final nr = r + d[0], nc = c + d[1];
        if (nr >= 0 && nr < size && nc >= 0 && nc < size && !visited[nr][nc]) {
          _openSet[r][c].add(nr * size + nc);
          _openSet[nr][nc].add(r * size + c);
          carve(nr, nc);
        }
      }
    }

    carve(0, 0);
  }

  bool _canMove(Point<int> from, Point<int> to) {
    if (to.x < 0 || to.x >= size || to.y < 0 || to.y >= size) return false;
    return _openSet[from.x][from.y].contains(to.x * size + to.y);
  }

  void _move(int dr, int dc) async {
    if (_won) return;
    final next = Point(_player.x + dr, _player.y + dc);
    if (_canMove(_player, next)) {
      setState(() {
        _player = next;
        _moves++;
        if (_player == _goal) _won = true;
      });
      if (_won) {
        final score = (500 - _moves * 5).clamp(0, 500);
        await GameResultHandler.report(context, gameId: widget.game.id, score: score);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Moves: $_moves')),
      body: SafeArea(
        child: Column(
          children: [
            if (_won)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('You escaped! 🎉', style: Theme.of(context).textTheme.titleMedium),
              ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onVerticalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) > 0) {
                      _move(1, 0);
                    } else if ((d.primaryVelocity ?? 0) < 0) {
                      _move(-1, 0);
                    }
                  },
                  onHorizontalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) > 0) {
                      _move(0, 1);
                    } else if ((d.primaryVelocity ?? 0) < 0) {
                      _move(0, -1);
                    }
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size),
                        itemCount: size * size,
                        itemBuilder: (context, i) {
                          final r = i ~/ size, c = i % size;
                          final isPlayer = _player.x == r && _player.y == c;
                          final isGoal = _goal.x == r && _goal.y == c;
                          return Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: isPlayer
                                  ? Theme.of(context).colorScheme.primary
                                  : isGoal
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.surface,
                            ),
                            child: isPlayer
                                ? const Icon(Icons.circle, color: Colors.white, size: 10)
                                : (isGoal ? const Icon(Icons.flag, color: Colors.white, size: 14) : null),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ),
          ],
        ),
      ),
    );
  }
}
