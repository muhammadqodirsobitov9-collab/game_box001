import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Push every box (B) onto a target (T) using swipe gestures. Three
/// small preset levels of increasing size. Score = 100 per level
/// cleared minus moves used on that level (floored at 10).
class SokobanMiniGame extends StatefulWidget {
  final GameModel game;
  const SokobanMiniGame({super.key, required this.game});

  @override
  State<SokobanMiniGame> createState() => _SokobanMiniGameState();
}

class _SokobanMiniGameState extends State<SokobanMiniGame> {
  // Legend: # wall, . floor, T target, B box, P player, X box-on-target, Y player-on-target
  static const _levels = [
    [
      '#####',
      '#P..#',
      '#.B.#',
      '#..T#',
      '#####',
    ],
    [
      '######',
      '#P...#',
      '#.BB.#',
      '#.TT.#',
      '#....#',
      '######',
    ],
    [
      '#######',
      '#..T..#',
      '#.BPB.#',
      '#..T..#',
      '#######',
    ],
  ];

  int _levelIndex = 0;
  late List<List<String>> _grid;
  late Point<int> _player;
  int _moves = 0;
  int _totalScore = 0;
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(0);
  }

  void _loadLevel(int index) {
    final raw = _levels[index];
    _grid = raw.map((row) => row.split('')).toList();
    for (var r = 0; r < _grid.length; r++) {
      for (var c = 0; c < _grid[r].length; c++) {
        if (_grid[r][c] == 'P') _player = Point(r, c);
      }
    }
    _levelIndex = index;
    _moves = 0;
    setState(() {});
  }

  bool _isTargetAt(int r, int c) => _grid[r][c] == 'T' || _grid[r][c] == 'X' || _grid[r][c] == 'Y';

  void _move(int dr, int dc) async {
    final r = _player.x, c = _player.y;
    final nr = r + dr, nc = c + dc;
    if (nr < 0 || nr >= _grid.length || nc < 0 || nc >= _grid[0].length) return;
    final target = _grid[nr][nc];
    if (target == '#') return;

    if (target == 'B' || target == 'X') {
      final br = nr + dr, bc = nc + dc;
      if (br < 0 || br >= _grid.length || bc < 0 || bc >= _grid[0].length) return;
      final beyond = _grid[br][bc];
      if (beyond == '#' || beyond == 'B' || beyond == 'X') return;
      // Move box
      _grid[br][bc] = _isTargetAt(br, bc) ? 'X' : 'B';
      _grid[nr][nc] = _isTargetAt(nr, nc) ? 'T' : '.';
    }

    // Move player
    _grid[r][c] = _isTargetAt(r, c) ? 'T' : '.';
    _grid[nr][nc] = _isTargetAt(nr, nc) ? 'Y' : 'P';
    _player = Point(nr, nc);
    _moves++;

    final solved = !_grid.any((row) => row.contains('B'));
    if (solved) {
      final levelScore = (100 - _moves).clamp(10, 100);
      _totalScore += levelScore;
      if (_levelIndex + 1 < _levels.length) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        _loadLevel(_levelIndex + 1);
      } else {
        setState(() => _allDone = true);
        await GameResultHandler.report(context, gameId: widget.game.id, score: _totalScore);
      }
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    if (_allDone) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.game.name)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('All levels cleared! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${strings.t('score')}: $_totalScore'),
              const SizedBox(height: 16),
              FilledButton(onPressed: () { setState(() { _allDone = false; _totalScore = 0; }); _loadLevel(0); }, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      );
    }

    final rows = _grid.length, cols = _grid[0].length;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Level ${_levelIndex + 1}/${_levels.length} · Moves: $_moves')),
      body: SafeArea(
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
              aspectRatio: cols / rows,
              child: Container(
                margin: const EdgeInsets.all(24),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols),
                  itemCount: rows * cols,
                  itemBuilder: (context, i) {
                    final r = i ~/ cols, c = i % cols;
                    final cell = _grid[r][c];
                    Color color;
                    Widget? icon;
                    switch (cell) {
                      case '#':
                        color = Colors.brown;
                        break;
                      case 'T':
                        color = Theme.of(context).colorScheme.surfaceContainerLow;
                        icon = const Icon(Icons.crop_square, size: 14, color: Colors.amber);
                        break;
                      case 'B':
                        color = Theme.of(context).colorScheme.surfaceContainerLow;
                        icon = const Icon(Icons.inventory_2, color: Colors.orange);
                        break;
                      case 'X':
                        color = Theme.of(context).colorScheme.surfaceContainerLow;
                        icon = const Icon(Icons.inventory_2, color: Colors.green);
                        break;
                      case 'P':
                      case 'Y':
                        color = Theme.of(context).colorScheme.surfaceContainerLow;
                        icon = Icon(Icons.person, color: Theme.of(context).colorScheme.primary);
                        break;
                      default:
                        color = Theme.of(context).colorScheme.surfaceContainerLow;
                    }
                    return Container(
                      margin: const EdgeInsets.all(1),
                      color: color,
                      child: Center(child: icon),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
