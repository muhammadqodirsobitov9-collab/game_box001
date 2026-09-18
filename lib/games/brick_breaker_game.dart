import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';

/// Paddle-and-ball brick breaker. Drag horizontally to move the
/// paddle. Score = 10 per brick destroyed.
class BrickBreakerGame extends StatefulWidget {
  final GameModel game;
  const BrickBreakerGame({super.key, required this.game});

  @override
  State<BrickBreakerGame> createState() => _BrickBreakerGameState();
}

class _BrickBreakerGameState extends State<BrickBreakerGame>
    with SingleTickerProviderStateMixin {
  static const rows = 4;
  static const cols = 6;
  static const paddleWidthFrac = 0.22;
  static const ballRadius = 7.0;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;

  double _paddleX = 0.5; // center, 0..1
  Offset _ballPos = const Offset(0.5, 0.55);
  Offset _ballVel = const Offset(0.35, -0.55); // units/sec (fraction of size)
  late List<bool> _bricks;
  int _score = 0;
  bool _running = false;
  bool _gameOver = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _bricks = List.filled(rows * cols, true);
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _bricks = List.filled(rows * cols, true);
      _score = 0;
      _paddleX = 0.5;
      _ballPos = const Offset(0.5, 0.55);
      _ballVel = const Offset(0.35, -0.55);
      _running = true;
      _gameOver = false;
      _won = false;
      _lastTick = Duration.zero;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    var pos = _ballPos + _ballVel * dt;
    var vel = _ballVel;

    // Wall bounce (x in [0,1])
    if (pos.dx <= 0.02) {
      pos = Offset(0.02, pos.dy);
      vel = Offset(vel.dx.abs(), vel.dy);
    } else if (pos.dx >= 0.98) {
      pos = Offset(0.98, pos.dy);
      vel = Offset(-vel.dx.abs(), vel.dy);
    }
    if (pos.dy <= 0.02) {
      pos = Offset(pos.dx, 0.02);
      vel = Offset(vel.dx, vel.dy.abs());
    }

    // Paddle bounce (paddle sits at y = 0.92)
    const paddleY = 0.92;
    if (pos.dy >= paddleY - 0.02 && pos.dy <= paddleY + 0.02 && vel.dy > 0) {
      if ((pos.dx - _paddleX).abs() < paddleWidthFrac / 2 + 0.02) {
        final offset = (pos.dx - _paddleX) / (paddleWidthFrac / 2);
        vel = Offset(offset.clamp(-1, 1) * 0.6, -vel.dy.abs());
      }
    }

    // Brick collision
    const brickTop = 0.08, brickBottom = 0.45;
    if (pos.dy >= brickTop && pos.dy <= brickBottom) {
      final col = (pos.dx * cols).floor().clamp(0, cols - 1);
      final row = ((pos.dy - brickTop) / ((brickBottom - brickTop) / rows)).floor().clamp(0, rows - 1);
      final idx = row * cols + col;
      if (_bricks[idx]) {
        _bricks[idx] = false;
        _score += 10;
        vel = Offset(vel.dx, -vel.dy);
        if (!_bricks.contains(true)) {
          _finish(won: true);
        }
      }
    }

    // Fell below paddle -> lose
    if (pos.dy > 1.02) {
      _finish(won: false);
      return;
    }

    setState(() {
      _ballPos = pos;
      _ballVel = vel;
    });
  }

  void _finish({required bool won}) async {
    _running = false;
    setState(() {
      _gameOver = true;
      _won = won;
    });
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  void _onDrag(DragUpdateDetails details, BoxConstraints constraints) {
    if (!_running) return;
    setState(() {
      _paddleX = (_paddleX + details.delta.dx / constraints.maxWidth).clamp(0.06, 0.94);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onHorizontalDragUpdate: (d) => _onDrag(d, constraints),
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    // Bricks
                    for (var i = 0; i < _bricks.length; i++)
                      if (_bricks[i])
                        Positioned(
                          left: (i % cols) / cols * constraints.maxWidth + 2,
                          top: 0.08 * constraints.maxHeight +
                              (i ~/ cols) * ((0.45 - 0.08) / rows) * constraints.maxHeight + 2,
                          width: constraints.maxWidth / cols - 4,
                          height: ((0.45 - 0.08) / rows) * constraints.maxHeight - 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.primaries[i % Colors.primaries.length],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    // Ball
                    Positioned(
                      left: _ballPos.dx * constraints.maxWidth - ballRadius,
                      top: _ballPos.dy * constraints.maxHeight - ballRadius,
                      child: Container(
                        width: ballRadius * 2,
                        height: ballRadius * 2,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Paddle
                    Positioned(
                      left: _paddleX * constraints.maxWidth - (paddleWidthFrac * constraints.maxWidth) / 2,
                      top: 0.92 * constraints.maxHeight - 6,
                      width: paddleWidthFrac * constraints.maxWidth,
                      height: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    if (!_running)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black45,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_gameOver)
                                  Text(
                                    _won ? 'You cleared the board! 🎉' : strings.t('game_over'),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _start,
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(_gameOver ? strings.t('restart') : strings.t('play')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
