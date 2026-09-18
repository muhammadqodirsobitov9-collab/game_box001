import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Simplified Tetris: 5 classic tetromino shapes, one 90° rotation
/// state, left/right/rotate buttons plus swipe-down soft drop. Score
/// = 100 per cleared line (multi-line clears score linearly, no combo
/// multiplier, kept simple) + 1 per piece placed.
class TetrisLiteGame extends StatefulWidget {
  final GameModel game;
  const TetrisLiteGame({super.key, required this.game});

  @override
  State<TetrisLiteGame> createState() => _TetrisLiteGameState();
}

typedef _Cell = Point<int>; // (row, col) relative offsets

class _TetrisLiteGameState extends State<TetrisLiteGame> {
  static const cols = 7;
  static const rows = 14;

  static final Map<String, List<_Cell>> _shapes = {
    'I': [const Point(0, 0), const Point(0, 1), const Point(0, 2), const Point(0, 3)],
    'O': [const Point(0, 0), const Point(0, 1), const Point(1, 0), const Point(1, 1)],
    'T': [const Point(0, 0), const Point(0, 1), const Point(0, 2), const Point(1, 1)],
    'L': [const Point(0, 0), const Point(1, 0), const Point(2, 0), const Point(2, 1)],
    'S': [const Point(1, 0), const Point(1, 1), const Point(0, 1), const Point(0, 2)],
  };
  static final _colors = {
    'I': Colors.cyan, 'O': Colors.yellow, 'T': Colors.purple,
    'L': Colors.orange, 'S': Colors.green,
  };

  late List<List<String?>> _board;
  late String _currentShape;
  late List<_Cell> _currentCells;
  late Point<int> _pos; // top-left anchor (row, col)
  int _score = 0;
  bool _gameOver = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(rows, (_) => List<String?>.filled(cols, null));
    _score = 0;
    _gameOver = false;
    _spawn();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 550), (_) => _tick());
  }

  void _spawn() {
    final keys = _shapes.keys.toList();
    _currentShape = keys[_rand.nextInt(keys.length)];
    _currentCells = _shapes[_currentShape]!;
    _pos = Point(0, (cols ~/ 2) - 1);
    if (_collides(_pos, _currentCells)) {
      _finish();
    }
  }

  bool _collides(Point<int> pos, List<_Cell> cells) {
    for (final c in cells) {
      final r = pos.x + c.x, col = pos.y + c.y;
      if (r < 0 || r >= rows || col < 0 || col >= cols) return true;
      if (_board[r][col] != null) return true;
    }
    return false;
  }

  void _lockPiece() {
    for (final c in _currentCells) {
      final r = _pos.x + c.x, col = _pos.y + c.y;
      if (r >= 0 && r < rows) _board[r][col] = _currentShape;
    }
    _score += 1;
    _clearLines();
    _spawn();
  }

  void _clearLines() {
    var cleared = 0;
    _board.removeWhere((row) {
      final full = row.every((cell) => cell != null);
      if (full) cleared++;
      return full;
    });
    while (_board.length < rows) {
      _board.insert(0, List<String?>.filled(cols, null));
    }
    _score += cleared * 100;
  }

  void _tick() {
    if (_gameOver) return;
    final next = Point(_pos.x + 1, _pos.y);
    setState(() {
      if (_collides(next, _currentCells)) {
        _lockPiece();
      } else {
        _pos = next;
      }
    });
  }

  void _move(int dc) {
    if (_gameOver) return;
    final next = Point(_pos.x, _pos.y + dc);
    if (!_collides(next, _currentCells)) {
      setState(() => _pos = next);
    }
  }

  void _rotate() {
    if (_gameOver) return;
    // Rotate 90° clockwise around the piece's local origin.
    final rotated = _currentCells.map((c) => Point(c.y, -c.x)).toList();
    final minX = rotated.map((c) => c.x).reduce(min);
    final minY = rotated.map((c) => c.y).reduce(min);
    final normalized = rotated.map((c) => Point(c.x - minX, c.y - minY)).toList();
    if (!_collides(_pos, normalized)) {
      setState(() => _currentCells = normalized);
    }
  }

  void _hardDrop() {
    if (_gameOver) return;
    var next = _pos;
    while (!_collides(Point(next.x + 1, next.y), _currentCells)) {
      next = Point(next.x + 1, next.y);
    }
    setState(() {
      _pos = next;
      _lockPiece();
    });
  }

  void _finish() async {
    _timer?.cancel();
    setState(() => _gameOver = true);
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    // Render board + current falling piece overlay.
    final display = List.generate(rows, (r) => List<String?>.of(_board[r]));
    for (final c in _currentCells) {
      final r = _pos.x + c.x, col = _pos.y + c.y;
      if (r >= 0 && r < rows && col >= 0 && col < cols) display[r][col] = _currentShape;
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 200) {
                    _move(1);
                  } else if ((d.primaryVelocity ?? 0) < -200) {
                    _move(-1);
                  }
                },
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 200) _hardDrop();
                },
                onTap: _rotate,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: cols / rows,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Stack(
                        children: [
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols),
                            itemCount: rows * cols,
                            itemBuilder: (context, i) {
                              final r = i ~/ cols, c = i % cols;
                              final shape = display[r][c];
                              return Container(
                                margin: const EdgeInsets.all(1),
                                color: shape == null ? Colors.transparent : _colors[shape],
                              );
                            },
                          ),
                          if (_gameOver)
                            Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(strings.t('game_over'),
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('${strings.t('score')}: $_score', style: const TextStyle(color: Colors.white)),
                                    const SizedBox(height: 12),
                                    FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filled(onPressed: () => _move(-1), icon: const Icon(Icons.arrow_back)),
                  IconButton.filled(onPressed: _rotate, icon: const Icon(Icons.rotate_right)),
                  IconButton.filled(onPressed: _hardDrop, icon: const Icon(Icons.arrow_downward)),
                  IconButton.filled(onPressed: () => _move(1), icon: const Icon(Icons.arrow_forward)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
