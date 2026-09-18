import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Tap a bubble to pop it along with every directly connected bubble
/// of the same color (flood fill). Groups of 2+ score size² × 5.
/// Game ends when no group of 2+ remains on the board.
class BubblePopMatchGame extends StatefulWidget {
  final GameModel game;
  const BubblePopMatchGame({super.key, required this.game});

  @override
  State<BubblePopMatchGame> createState() => _BubblePopMatchGameState();
}

class _BubblePopMatchGameState extends State<BubblePopMatchGame> {
  static const rows = 8;
  static const cols = 6;
  static const _colors = [Colors.red, Colors.blue, Colors.green, Colors.amber, Colors.purple];

  late List<List<int?>> _grid; // color index or null (empty)
  int _score = 0;
  bool _gameOver = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _grid = List.generate(rows, (_) => List.generate(cols, (_) => _rand.nextInt(_colors.length)));
    _score = 0;
    _gameOver = false;
    setState(() {});
  }

  List<Point<int>> _connectedGroup(int r, int c) {
    final color = _grid[r][c];
    if (color == null) return [];
    final visited = <Point<int>>{};
    final stack = [Point(r, c)];
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      if (visited.contains(p)) continue;
      if (p.x < 0 || p.x >= rows || p.y < 0 || p.y >= cols) continue;
      if (_grid[p.x][p.y] != color) continue;
      visited.add(p);
      stack.addAll([
        Point(p.x - 1, p.y), Point(p.x + 1, p.y),
        Point(p.x, p.y - 1), Point(p.x, p.y + 1),
      ]);
    }
    return visited.toList();
  }

  void _tap(int r, int c) async {
    if (_gameOver || _grid[r][c] == null) return;
    final group = _connectedGroup(r, c);
    if (group.length < 2) return;

    setState(() {
      for (final p in group) {
        _grid[p.x][p.y] = null;
      }
      _score += group.length * group.length * 5;
      _applyGravity();
    });

    if (!_anyMovesLeft()) {
      _gameOver = true;
      await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
      setState(() {});
    }
  }

  void _applyGravity() {
    for (var c = 0; c < cols; c++) {
      final colValues = <int>[];
      for (var r = 0; r < rows; r++) {
        if (_grid[r][c] != null) colValues.add(_grid[r][c]!);
      }
      for (var r = 0; r < rows; r++) {
        final fromBottomIndex = rows - colValues.length;
        _grid[r][c] = r < fromBottomIndex ? null : colValues[r - fromBottomIndex];
      }
    }
  }

  bool _anyMovesLeft() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_grid[r][c] == null) continue;
        if (_connectedGroup(r, c).length >= 2) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score')),
      body: SafeArea(
        child: Column(
          children: [
            if (_gameOver)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('No more moves · ${strings.t('score')}: $_score', style: Theme.of(context).textTheme.titleMedium),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: cols / rows,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols),
                      itemCount: rows * cols,
                      itemBuilder: (context, i) {
                        final r = i ~/ cols, c = i % cols;
                        final color = _grid[r][c];
                        return GestureDetector(
                          onTap: () => _tap(r, c),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: color == null ? Colors.transparent : _colors[color],
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
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
