import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Classic 9x9 Sudoku. Ships with a small set of preset puzzles
/// (0 = empty cell) rather than a from-scratch generator. Validity is
/// checked live against standard Sudoku rules (no duplicate in any
/// row/column/3x3 box), not against a stored solution — so any valid
/// completion counts as solved. Score = max(0, 500 - seconds elapsed).
class SudokuClassicGame extends StatefulWidget {
  final GameModel game;
  const SudokuClassicGame({super.key, required this.game});

  @override
  State<SudokuClassicGame> createState() => _SudokuClassicGameState();
}

class _SudokuClassicGameState extends State<SudokuClassicGame> {
  static const _puzzles = [
    [
      [5,3,0, 0,7,0, 0,0,0],
      [6,0,0, 1,9,5, 0,0,0],
      [0,9,8, 0,0,0, 0,6,0],
      [8,0,0, 0,6,0, 0,0,3],
      [4,0,0, 8,0,3, 0,0,1],
      [7,0,0, 0,2,0, 0,0,6],
      [0,6,0, 0,0,0, 2,8,0],
      [0,0,0, 4,1,9, 0,0,5],
      [0,0,0, 0,8,0, 0,7,9],
    ],
    [
      [0,0,0, 2,6,0, 7,0,1],
      [6,8,0, 0,7,0, 0,9,0],
      [1,9,0, 0,0,4, 5,0,0],
      [8,2,0, 1,0,0, 0,4,0],
      [0,0,4, 6,0,2, 9,0,0],
      [0,5,0, 0,0,3, 0,2,8],
      [0,0,9, 3,0,0, 0,7,4],
      [0,4,0, 0,5,0, 0,3,6],
      [7,0,3, 0,1,8, 0,0,0],
    ],
  ];

  late List<List<int>> _fixed; // 0 = editable
  late List<List<int>> _grid;
  int? _selectedRow, _selectedCol;
  Duration _elapsed = Duration.zero;
  bool _solved = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _newPuzzle();
    _tick();
  }

  void _newPuzzle() {
    final puzzle = _puzzles[_rand.nextInt(_puzzles.length)];
    _fixed = puzzle.map((row) => List<int>.of(row)).toList();
    _grid = puzzle.map((row) => List<int>.of(row)).toList();
    _elapsed = Duration.zero;
    _solved = false;
    _selectedRow = null;
    _selectedCol = null;
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _solved) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      _tick();
    });
  }

  void _select(int r, int c) {
    if (_fixed[r][c] != 0) return;
    setState(() {
      _selectedRow = r;
      _selectedCol = c;
    });
  }

  void _enter(int value) async {
    if (_selectedRow == null || _selectedCol == null) return;
    setState(() => _grid[_selectedRow!][_selectedCol!] = value);
    if (_isComplete() && _isValid()) {
      setState(() => _solved = true);
      final score = (500 - _elapsed.inSeconds).clamp(0, 500);
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    }
  }

  bool _isComplete() => _grid.every((row) => row.every((v) => v != 0));

  bool _isValid() {
    for (var i = 0; i < 9; i++) {
      final row = <int>{}, col = <int>{};
      for (var j = 0; j < 9; j++) {
        if (!row.add(_grid[i][j])) return false;
        if (!col.add(_grid[j][i])) return false;
      }
    }
    for (var br = 0; br < 9; br += 3) {
      for (var bc = 0; bc < 9; bc += 3) {
        final box = <int>{};
        for (var r = 0; r < 3; r++) {
          for (var c = 0; c < 3; c++) {
            if (!box.add(_grid[br + r][bc + c])) return false;
          }
        }
      }
    }
    return true;
  }

  bool _hasConflict(int r, int c) {
    final v = _grid[r][c];
    if (v == 0) return false;
    for (var i = 0; i < 9; i++) {
      if (i != c && _grid[r][i] == v) return true;
      if (i != r && _grid[i][c] == v) return true;
    }
    final br = (r ~/ 3) * 3, bc = (c ~/ 3) * 3;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        final rr = br + i, cc = bc + j;
        if ((rr != r || cc != c) && _grid[rr][cc] == v) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${_elapsed.inMinutes}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}')),
      body: SafeArea(
        child: Column(
          children: [
            if (_solved)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Solved! 🎉', style: Theme.of(context).textTheme.titleMedium),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
                      itemCount: 81,
                      itemBuilder: (context, i) {
                        final r = i ~/ 9, c = i % 9;
                        final v = _grid[r][c];
                        final isFixed = _fixed[r][c] != 0;
                        final isSelected = _selectedRow == r && _selectedCol == c;
                        final conflict = _hasConflict(r, c);
                        return GestureDetector(
                          onTap: () => _select(r, c),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: (c + 1) % 3 == 0 && c != 8 ? 2 : 0.5,
                              bottom: (r + 1) % 3 == 0 && r != 8 ? 2 : 0.5,
                            ),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerLow,
                            child: Center(
                              child: Text(
                                v == 0 ? '' : '$v',
                                style: TextStyle(
                                  fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
                                  color: conflict ? Colors.red : (isFixed ? null : Theme.of(context).colorScheme.primary),
                                ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Wrap(
                spacing: 6,
                children: [
                  for (var n = 1; n <= 9; n++)
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: OutlinedButton(
                        onPressed: () => _enter(n),
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text('$n'),
                      ),
                    ),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => _enter(0),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Icon(Icons.backspace_outlined, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton(
                onPressed: () => setState(_newPuzzle),
                child: Text(strings.t('restart')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
