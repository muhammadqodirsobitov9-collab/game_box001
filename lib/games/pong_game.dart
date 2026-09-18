import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';

/// Classic Pong against a simple CPU paddle. Score = rallies won
/// (points scored against the CPU) before losing 5 points.
class PongGame extends StatefulWidget {
  final GameModel game;
  const PongGame({super.key, required this.game});

  @override
  State<PongGame> createState() => _PongGameState();
}

class _PongGameState extends State<PongGame> with SingleTickerProviderStateMixin {
  static const paddleHeightFrac = 0.18;
  static const paddleWidth = 12.0;
  static const winScore = 5;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;

  double _playerY = 0.5;
  double _cpuY = 0.5;
  double _ballX = 0.5;
  double _ballY = 0.5;
  double _ballVX = 0.4;
  double _ballVY = 0.3;
  int _playerScore = 0;
  int _cpuScore = 0;
  bool _running = false;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _playerScore = 0;
      _cpuScore = 0;
      _running = true;
      _gameOver = false;
      _resetBall();
      _lastTick = Duration.zero;
    });
  }

  void _resetBall() {
    _ballX = 0.5;
    _ballY = 0.5;
    _ballVX = _ballVX.isNegative ? 0.4 : -0.4;
    _ballVY = 0.25;
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    var x = _ballX + _ballVX * dt;
    var y = _ballY + _ballVY * dt;
    var vx = _ballVX;
    var vy = _ballVY;

    if (y <= 0.02) {
      y = 0.02;
      vy = vy.abs();
    } else if (y >= 0.98) {
      y = 0.98;
      vy = -vy.abs();
    }

    // CPU tracks the ball with limited speed
    final cpuTarget = y;
    final cpuSpeed = 0.9;
    if (_cpuY < cpuTarget) {
      _cpuY = (_cpuY + cpuSpeed * dt).clamp(0, cpuTarget);
    } else if (_cpuY > cpuTarget) {
      _cpuY = (_cpuY - cpuSpeed * dt).clamp(cpuTarget, 1.0);
    }

    // Player paddle at x=0.05, CPU paddle at x=0.95
    if (x <= 0.08 && vx < 0) {
      if ((y - _playerY).abs() < paddleHeightFrac / 2 + 0.03) {
        vx = vx.abs();
        vy += (y - _playerY) * 0.6;
      }
    }
    if (x >= 0.92 && vx > 0) {
      if ((y - _cpuY).abs() < paddleHeightFrac / 2 + 0.03) {
        vx = -vx.abs();
      }
    }

    if (x < 0) {
      _cpuScore++;
      x = 0.5;
      y = 0.5;
      vx = 0.4;
    } else if (x > 1) {
      _playerScore++;
      x = 0.5;
      y = 0.5;
      vx = -0.4;
    }

    if (_playerScore >= winScore || _cpuScore >= winScore) {
      setState(() {
        _ballX = x;
        _ballY = y;
        _ballVX = vx;
        _ballVY = vy;
      });
      _finish();
      return;
    }

    setState(() {
      _ballX = x;
      _ballY = y;
      _ballVX = vx;
      _ballVY = vy;
    });
  }

  void _finish() async {
    _running = false;
    setState(() => _gameOver = true);
    await GameResultHandler.report(context, gameId: widget.game.id, score: _playerScore);
  }

  void _onDrag(DragUpdateDetails details, BoxConstraints constraints) {
    if (!_running) return;
    setState(() {
      _playerY = (_playerY + details.delta.dy / constraints.maxHeight).clamp(0.1, 0.9);
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
      appBar: AppBar(title: Text('${widget.game.name} · $_playerScore - $_cpuScore')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onVerticalDragUpdate: (d) => _onDrag(d, constraints),
              child: Stack(
                children: [
                  Container(color: Theme.of(context).colorScheme.surfaceContainerLow, width: double.infinity, height: double.infinity),
                  Positioned(
                    left: 0.04 * constraints.maxWidth,
                    top: _playerY * constraints.maxHeight - (paddleHeightFrac * constraints.maxHeight) / 2,
                    width: paddleWidth,
                    height: paddleHeightFrac * constraints.maxHeight,
                    child: Container(color: Theme.of(context).colorScheme.primary),
                  ),
                  Positioned(
                    left: 0.96 * constraints.maxWidth - paddleWidth,
                    top: _cpuY * constraints.maxHeight - (paddleHeightFrac * constraints.maxHeight) / 2,
                    width: paddleWidth,
                    height: paddleHeightFrac * constraints.maxHeight,
                    child: Container(color: Colors.redAccent),
                  ),
                  Positioned(
                    left: _ballX * constraints.maxWidth - 8,
                    top: _ballY * constraints.maxHeight - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, shape: BoxShape.circle),
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
                                  _playerScore > _cpuScore ? 'You win! 🎉' : 'CPU wins.',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _start,
                                icon: const Icon(Icons.play_arrow),
                                label: Text(_gameOver ? strings.t('restart') : strings.t('play')),
                              ),
                              const SizedBox(height: 8),
                              const Text('Drag up/down to move your paddle', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
