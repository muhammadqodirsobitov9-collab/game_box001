import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// 4x4 mini sudoku: fill every row, column and 2x2 box with 1-4.
/// A handful of cells are pre-filled and locked; the rest start
/// empty. Score = max(0, 100 - mistakes*10 - seconds elapsed/2).
class MiniSudokuGame extends StatefulWidget {
  final GameModel game;
  const MiniSudokuGame({super.key, required this.game});

  @override
  State<MiniSudokuGame> createState() => _MiniSudokuGameState();
}

class _MiniSudokuGameState extends State<MiniSudokuGame> {
  static const size = 4;
  late List<List<int>> _solution;
  late List<List<int>> _board; // 0 = empty
  late List<List<bool>> _locked;
  int _mistakes = 0;
  bool _solved = false;
  final _stopwatch = Stopwatch();
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _solution = _generateSolution();
    _board = List.generate(size, (r) => List.of(_solution[r]));
    _locked = List.generate(size, (_) => List.filled(size, true));

    // Blank out ~8 of 16 cells for the player to fill in.
    final cells = [for (var r = 0; r < size; r++) for (var c = 0; c < size; c++) Point(r, c)];
    cells.shuffle(_rand);
    for (final p in cells.take(8)) {
      _board[p.x][p.y] = 0;
      _locked[p.x][p.y] = false;
    }

    _mistakes = 0;
    _solved = false;
    _stopwatch
      ..reset()
      ..start();
    setState(() {});
  }

  List<List<int>> _generateSolution() {
    // One valid base pattern for a 4x4 sudoku, then shuffle rows
    // within bands and bands themselves, and relabel digits — this
    // yields a fresh valid solution each time cheaply.
    var grid = [
      [1, 2, 3, 4],
      [3, 4, 1, 2],
      [2, 1, 4, 3],
      [4, 3, 2, 1],
    ];

    // Relabel digits randomly.
    final mapping = [1, 2, 3, 4]..shuffle(_rand);
    grid = grid.map((row) => row.map((v) => mapping[v - 1]).toList()).toList();

    // Swap the two rows within each band (rows 0-1, rows 2-3).
    if (_rand.nextBool()) {
      final tmp = grid[0];
      grid[0] = grid[1];
      grid[1] = tmp;
    }
    if (_rand.nextBool()) {
      final tmp = grid[2];
      grid[2] = grid[3];
      grid[3] = tmp;
    }
    // Swap the two bands themselves.
    if (_rand.nextBool()) {
      final tmp = [grid[0], grid[1]];
      grid[0] = grid[2];
      grid[1] = grid[3];
      grid[2] = tmp[0];
      grid[3] = tmp[1];
    }
    return grid;
  }

  void _setCell(int r, int c, int value) async {
    if (_locked[r][c] || _solved) return;
    setState(() {
      _board[r][c] = value;
      if (value != 0 && value != _solution[r][c]) {
        _mistakes++;
      }
    });
    final filled = _board.every((row) => row.every((v) => v != 0));
    final correct = _boardMatchesSolution();
    if (filled && correct) {
      _stopwatch.stop();
      setState(() => _solved = true);
      final score = (100 - _mistakes * 10 - _stopwatch.elapsed.inSeconds ~/ 2).clamp(10, 100);
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    }
  }

  bool _boardMatchesSolution() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_board[r][c] != _solution[r][c]) return false;
      }
    }
    return true;
  }

  void _showNumberPicker(int r, int c) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            for (var v = 1; v <= 4; v++)
              ListTile(
                title: Text('$v'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setCell(r, c, v);
                },
              ),
            ListTile(
              title: const Text('Clear'),
              onTap: () {
                Navigator.pop(ctx);
                _setCell(r, c, 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Mistakes: $_mistakes')),
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
                width: 280,
                height: 280,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: size * size,
                  itemBuilder: (context, i) {
                    final r = i ~/ size, c = i % size;
                    final v = _board[r][c];
                    final locked = _locked[r][c];
                    return GestureDetector(
                      onTap: () => _showNumberPicker(r, c),
                      child: Container(
                        decoration: BoxDecoration(
                          color: locked
                              ? Theme.of(context).colorScheme.surfaceContainerHigh
                              : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            v == 0 ? '' : '$v',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: locked ? null : Theme.of(context).colorScheme.primary,
                            ),
                          ),
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
