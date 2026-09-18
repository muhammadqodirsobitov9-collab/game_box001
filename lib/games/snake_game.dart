import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

enum _Dir { up, down, left, right }

/// Fully playable classic Snake on a fixed grid. Swipe to steer.
/// Original implementation — no assets, no external code copied.
class SnakeGame extends StatefulWidget {
  final GameModel game;
  const SnakeGame({super.key, required this.game});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int cols = 14;
  static const int rows = 20;

  late List<Point<int>> _snake;
  late Point<int> _food;
  _Dir _dir = _Dir.right;
  _Dir _pendingDir = _Dir.right;
  Timer? _timer;
  int _score = 0;
  bool _gameOver = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _snake = [
      const Point(6, 10),
      const Point(5, 10),
      const Point(4, 10),
    ];
    _dir = _Dir.right;
    _pendingDir = _Dir.right;
    _score = 0;
    _gameOver = false;
    _spawnFood();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 160), (_) => _tick());
  }

  void _spawnFood() {
    Point<int> p;
    do {
      p = Point(_rand.nextInt(cols), _rand.nextInt(rows));
    } while (_snake.contains(p));
    _food = p;
  }

  void _tick() {
    if (_gameOver) return;
    _dir = _pendingDir;
    final head = _snake.first;
    Point<int> newHead;
    switch (_dir) {
      case _Dir.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case _Dir.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case _Dir.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case _Dir.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    final hitWall =
        newHead.x < 0 || newHead.x >= cols || newHead.y < 0 || newHead.y >= rows;
    final hitSelf = _snake.contains(newHead);

    if (hitWall || hitSelf) {
      _endGame();
      return;
    }

    setState(() {
      _snake.insert(0, newHead);
      if (newHead == _food) {
        _score += 10;
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _endGame() async {
    _timer?.cancel();
    setState(() => _gameOver = true);
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  void _setDir(_Dir d) {
    // Prevent instantly reversing into yourself.
    final opposite = {
      _Dir.up: _Dir.down,
      _Dir.down: _Dir.up,
      _Dir.left: _Dir.right,
      _Dir.right: _Dir.left,
    };
    if (opposite[d] == _dir) return;
    _pendingDir = d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.game.name} · ${strings.t('score')}: $_score'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (d) {
            if (d.delta.dy > 6) _setDir(_Dir.down);
            if (d.delta.dy < -6) _setDir(_Dir.up);
          },
          onHorizontalDragUpdate: (d) {
            if (d.delta.dx > 6) _setDir(_Dir.right);
            if (d.delta.dx < -6) _setDir(_Dir.left);
          },
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: cols / rows,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellW = constraints.maxWidth / cols;
                        final cellH = constraints.maxHeight / rows;
                        return Stack(
                          children: [
                            Positioned(
                              left: _food.x * cellW,
                              top: _food.y * cellH,
                              width: cellW,
                              height: cellH,
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            for (final seg in _snake)
                              Positioned(
                                left: seg.x * cellW,
                                top: seg.y * cellH,
                                width: cellW,
                                height: cellH,
                                child: Container(
                                  margin: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_gameOver)
                _GameOverOverlay(
                  score: _score,
                  onRestart: () => setState(_reset),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;
  const _GameOverOverlay({required this.score, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Container(
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
                Text('${strings.t('score')}: $score'),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRestart, child: Text(strings.t('restart'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
