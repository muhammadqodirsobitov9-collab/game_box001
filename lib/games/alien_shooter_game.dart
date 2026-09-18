import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

class _Bullet {
  double x, y;
  _Bullet(this.x, this.y);
}

/// Space-Invaders-style shooter: drag to move, tap to fire upward at
/// descending aliens. Aliens step down and speed up as their ranks
/// thin out. Score = 10 per alien destroyed.
class AlienShooterGame extends StatefulWidget {
  final GameModel game;
  const AlienShooterGame({super.key, required this.game});

  @override
  State<AlienShooterGame> createState() => _AlienShooterGameState();
}

class _AlienShooterGameState extends State<AlienShooterGame> with SingleTickerProviderStateMixin {
  static const alienCols = 6;
  static const alienRows = 3;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Duration _lastShot = Duration.zero;

  double _playerX = 0.5;
  final List<_Bullet> _bullets = [];
  late List<List<bool>> _aliens;
  double _alienOffsetX = 0;
  double _alienOffsetY = 0;
  int _alienDir = 1;
  int _score = 0;
  bool _running = false;
  bool _gameOver = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _playerX = 0.5;
      _bullets.clear();
      _aliens = List.generate(alienRows, (_) => List.filled(alienCols, true));
      _alienOffsetX = 0;
      _alienOffsetY = 0;
      _alienDir = 1;
      _score = 0;
      _running = true;
      _gameOver = false;
      _won = false;
      _lastTick = Duration.zero;
    });
  }

  void _fire() {
    if (!_running) return;
    _bullets.add(_Bullet(_playerX, 0.9));
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    final aliveCount = _aliens.expand((r) => r).where((a) => a).length;
    final speed = 0.15 + (alienRows * alienCols - aliveCount) * 0.01;

    _alienOffsetX += _alienDir * speed * dt;
    if (_alienOffsetX > 0.15 || _alienOffsetX < -0.15) {
      _alienDir *= -1;
      _alienOffsetY += 0.05;
    }

    for (final b in _bullets) {
      b.y -= 0.6 * dt;
    }
    _bullets.removeWhere((b) => b.y < 0);

    // Bullet-alien collision
    const cellW = 0.8 / alienCols;
    const cellH = 0.25 / alienRows;
    for (final b in List.of(_bullets)) {
      for (var r = 0; r < alienRows; r++) {
        for (var c = 0; c < alienCols; c++) {
          if (!_aliens[r][c]) continue;
          final ax = 0.1 + c * cellW + _alienOffsetX;
          final ay = 0.1 + r * cellH + _alienOffsetY;
          if (b.x > ax && b.x < ax + cellW && b.y > ay && b.y < ay + cellH) {
            _aliens[r][c] = false;
            _bullets.remove(b);
            _score += 10;
          }
        }
      }
    }

    if (!_aliens.expand((r) => r).any((a) => a)) {
      _finish(won: true);
      return;
    }
    if (_alienOffsetY > 0.65) {
      _finish(won: false);
      return;
    }

    setState(() {});
  }

  void _finish({required bool won}) async {
    _running = false;
    setState(() {
      _gameOver = true;
      _won = won;
    });
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  void _onDrag(DragUpdateDetails d, BoxConstraints constraints) {
    if (!_running) return;
    setState(() {
      _playerX = (_playerX + d.delta.dx / constraints.maxWidth).clamp(0.05, 0.95);
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
            final w = constraints.maxWidth, h = constraints.maxHeight;
            const cellW = 0.8 / alienCols;
            const cellH = 0.25 / alienRows;
            return GestureDetector(
              onHorizontalDragUpdate: (d) => _onDrag(d, constraints),
              onTap: _fire,
              child: Stack(
                children: [
                  Container(color: Theme.of(context).colorScheme.surfaceContainerLow, width: double.infinity, height: double.infinity),
                  for (var r = 0; r < alienRows; r++)
                    for (var c = 0; c < alienCols; c++)
                      if (_aliens[r][c])
                        Positioned(
                          left: (0.1 + c * cellW + _alienOffsetX) * w,
                          top: (0.1 + r * cellH + _alienOffsetY) * h,
                          width: cellW * w * 0.8,
                          height: cellH * h * 0.8,
                          child: Container(color: Colors.greenAccent, child: const Icon(Icons.android, color: Colors.black, size: 16)),
                        ),
                  for (final b in _bullets)
                    Positioned(
                      left: b.x * w - 2,
                      top: b.y * h,
                      child: Container(width: 4, height: 12, color: Colors.yellow),
                    ),
                  Positioned(
                    left: _playerX * w - 18,
                    top: 0.9 * h,
                    child: const Icon(Icons.arrow_drop_up, size: 36, color: Colors.white),
                  ),
                  if (!_running)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_gameOver)
                                Text(_won ? 'All cleared! 🎉' : strings.t('game_over'),
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _start,
                                icon: const Icon(Icons.play_arrow),
                                label: Text(_gameOver ? strings.t('restart') : strings.t('play')),
                              ),
                              const SizedBox(height: 8),
                              const Text('Drag to move, tap to fire', style: TextStyle(color: Colors.white70)),
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
