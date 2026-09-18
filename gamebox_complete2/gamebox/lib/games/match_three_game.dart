import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Simple match-3: tap two adjacent gems to swap them. If the swap
/// creates a line of 3+ matching gems (row or column), they clear,
/// tiles above fall down, and new random gems fill the top. 20 moves
/// per round. Score = 10 per gem cleared.
class MatchThreeGame extends StatefulWidget {
  final GameModel game;
  const MatchThreeGame({super.key, required this.game});

  @override
  State<MatchThreeGame> createState() => _MatchThreeGameState();
}

class _MatchThreeGameState extends State<MatchThreeGame> {
  static const size = 6;
  static const colorCount = 5;
  static const startingMoves = 20;

  static const _gemColors = [
    Colors.redAccent, Colors.blueAccent, Colors.green,
    Colors.orange, Colors.purple,
  ];

  late List<List<int>> _grid;
  Point<int>? _selected;
  int _score = 0;
  int _movesLeft = startingMoves;
  bool _gameOver = false;
  bool _busy = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    do {
      _grid = List.generate(size, (_) => List.generate(size, (_) => _rand.nextInt(colorCount)));
    } while (_findMatches(_grid).isNotEmpty);
    _selected = null;
    _score = 0;
    _movesLeft = startingMoves;
    _gameOver = false;
    _busy = false;
    setState(() {});
  }

  Set<Point<int>> _findMatches(List<List<int>> g) {
    final matches = <Point<int>>{};
    // Rows
    for (var r = 0; r < size; r++) {
      var runStart = 0;
      for (var c = 1; c <= size; c++) {
        if (c < size && g[r][c] == g[r][runStart]) continue;
        if (c - runStart >= 3) {
          for (var k = runStart; k < c; k++) {
            matches.add(Point(r, k));
          }
        }
        runStart = c;
      }
    }
    // Columns
    for (var c = 0; c < size; c++) {
      var runStart = 0;
      for (var r = 1; r <= size; r++) {
        if (r < size && g[r][c] == g[runStart][c]) continue;
        if (r - runStart >= 3) {
          for (var k = runStart; k < r; k++) {
            matches.add(Point(k, c));
          }
        }
        runStart = r;
      }
    }
    return matches;
  }

  Future<void> _resolveMatches() async {
    while (true) {
      final matches = _findMatches(_grid);
      if (matches.isEmpty) break;
      setState(() {
        _score += matches.length * 10;
        for (final p in matches) {
          _grid[p.x][p.y] = -1; // mark cleared
        }
      });
      await Future.delayed(const Duration(milliseconds: 180));
      setState(() {
        for (var c = 0; c < size; c++) {
          final column = [for (var r = 0; r < size; r++) _grid[r][c]].where((v) => v != -1).toList();
          final missing = size - column.length;
          final refill = List.generate(missing, (_) => _rand.nextInt(colorCount));
          final newColumn = [...refill, ...column];
          for (var r = 0; r < size; r++) {
            _grid[r][c] = newColumn[r];
          }
        }
      });
      await Future.delayed(const Duration(milliseconds: 180));
    }
  }

  void _tap(int r, int c) async {
    if (_busy || _gameOver) return;
    final tapped = Point(r, c);
    if (_selected == null) {
      setState(() => _selected = tapped);
      return;
    }
    final a = _selected!;
    final adjacent = (a.x == r && (a.y - c).abs() == 1) || (a.y == c && (a.x - r).abs() == 1);
    if (!adjacent) {
      setState(() => _selected = tapped);
      return;
    }

    _busy = true;
    setState(() {
      final tmp = _grid[a.x][a.y];
      _grid[a.x][a.y] = _grid[r][c];
      _grid[r][c] = tmp;
      _selected = null;
    });

    final hasMatch = _findMatches(_grid).isNotEmpty;
    if (!hasMatch) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        final tmp = _grid[a.x][a.y];
        _grid[a.x][a.y] = _grid[r][c];
        _grid[r][c] = tmp;
      });
      _busy = false;
      return;
    }

    setState(() => _movesLeft--);
    await _resolveMatches();
    _busy = false;

    if (_movesLeft <= 0) {
      _gameOver = true;
      await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.game.name} · ${strings.t('score')}: $_score · Moves: $_movesLeft'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_gameOver)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
                ),
              SizedBox(
                width: 300,
                height: 300,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: size * size,
                  itemBuilder: (context, i) {
                    final r = i ~/ size, c = i % size;
                    final v = _grid[r][c];
                    final isSelected = _selected == Point(r, c);
                    return GestureDetector(
                      onTap: () => _tap(r, c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: v == -1 ? Colors.transparent : _gemColors[v],
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
