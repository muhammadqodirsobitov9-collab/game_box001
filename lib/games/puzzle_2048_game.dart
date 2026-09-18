import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Classic 2048 sliding-tile merge puzzle on a 4x4 grid.
class Puzzle2048Game extends StatefulWidget {
  final GameModel game;
  const Puzzle2048Game({super.key, required this.game});

  @override
  State<Puzzle2048Game> createState() => _Puzzle2048GameState();
}

class _Puzzle2048GameState extends State<Puzzle2048Game> {
  static const size = 4;
  late List<List<int>> _grid;
  int _score = 0;
  bool _gameOver = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _grid = List.generate(size, (_) => List.filled(size, 0));
    _score = 0;
    _gameOver = false;
    _spawnTile();
    _spawnTile();
    setState(() {});
  }

  void _spawnTile() {
    final empties = <Point<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_grid[r][c] == 0) empties.add(Point(r, c));
      }
    }
    if (empties.isEmpty) return;
    final p = empties[_rand.nextInt(empties.length)];
    _grid[p.x][p.y] = _rand.nextDouble() < 0.9 ? 2 : 4;
  }

  bool _slideRowLeft(List<int> row) {
    final nonZero = row.where((v) => v != 0).toList();
    final merged = <int>[];
    var changed = nonZero.length != row.length;
    var i = 0;
    while (i < nonZero.length) {
      if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
        final value = nonZero[i] * 2;
        merged.add(value);
        _score += value;
        i += 2;
        changed = true;
      } else {
        merged.add(nonZero[i]);
        i++;
      }
    }
    while (merged.length < size) {
      merged.add(0);
    }
    for (var j = 0; j < size; j++) {
      if (row[j] != merged[j]) changed = true;
      row[j] = merged[j];
    }
    return changed;
  }

  List<List<int>> _rotate(List<List<int>> g) {
    final result = List.generate(size, (_) => List.filled(size, 0));
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        result[c][size - 1 - r] = g[r][c];
      }
    }
    return result;
  }

  void _move(String direction) {
    if (_gameOver) return;
    var g = _grid;
    var rotations = switch (direction) {
      'left' => 0,
      'up' => 3,
      'right' => 2,
      'down' => 1,
      _ => 0,
    };
    for (var i = 0; i < rotations; i++) {
      g = _rotate(g);
    }
    var changed = false;
    for (final row in g) {
      if (_slideRowLeft(row)) changed = true;
    }
    for (var i = 0; i < (4 - rotations) % 4; i++) {
      g = _rotate(g);
    }
    if (changed) {
      setState(() {
        _grid = g;
        _spawnTile();
        if (!_hasMoves()) _endGame();
      });
    }
  }

  bool _hasMoves() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_grid[r][c] == 0) return true;
        if (c + 1 < size && _grid[r][c] == _grid[r][c + 1]) return true;
        if (r + 1 < size && _grid[r][c] == _grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  void _endGame() async {
    setState(() => _gameOver = true);
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  Color _tileColor(int value, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (value == 0) return scheme.surfaceContainerHigh;
    final shades = {
      2: scheme.primaryContainer,
      4: scheme.primaryContainer,
      8: scheme.primary,
      16: scheme.primary,
      32: scheme.tertiary,
      64: scheme.tertiary,
    };
    return shades[value] ?? scheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score')),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 0) {
              _move('right');
            } else if ((d.primaryVelocity ?? 0) < 0) {
              _move('left');
            }
          },
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 0) {
              _move('down');
            } else if ((d.primaryVelocity ?? 0) < 0) {
              _move('up');
            }
          },
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: size * size,
                        itemBuilder: (context, i) {
                          final r = i ~/ size, c = i % size;
                          final v = _grid[r][c];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: _tileColor(v, context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: v == 0
                                  ? null
                                  : Text(
                                      '$v',
                                      style: TextStyle(
                                        fontSize: v >= 100 ? 20 : 26,
                                        fontWeight: FontWeight.bold,
                                        color: v <= 4 ? Colors.black87 : Colors.white,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (_gameOver)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(strings.t('game_over'),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('${strings.t('score')}: $_score'),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
