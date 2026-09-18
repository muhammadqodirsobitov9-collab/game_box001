import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Original tap-to-jump endless runner. A single square "runner"
/// jumps over approaching obstacles; score increases with survival
/// time. Fully offline, no external assets.
class RunnerGame extends StatefulWidget {
  final GameModel game;
  const RunnerGame({super.key, required this.game});

  @override
  State<RunnerGame> createState() => _RunnerGameState();
}

class _RunnerGameState extends State<RunnerGame> with SingleTickerProviderStateMixin {
  static const double groundY = 0; // relative, 0 = ground level
  static const double gravity = 2600;
  static const double jumpVelocity = -950;
  static const double obstacleSpeed = 260;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;

  double _playerY = 0; // 0 = on ground, negative = up
  double _velocity = 0;
  bool _jumping = false;

  final List<double> _obstacles = [1.2, 2.4];
  int _score = 0;
  bool _gameOver = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_gameOver) return;
    final dt = (_lastTick == Duration.zero)
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return; // skip first/huge frame

    setState(() {
      // Physics
      _velocity += gravity * dt;
      _playerY += _velocity * dt;
      if (_playerY > 0) {
        _playerY = 0;
        _velocity = 0;
        _jumping = false;
      }

      // Obstacles move left (in "world units" where 1.0 ~ screen width)
      for (var i = 0; i < _obstacles.length; i++) {
        _obstacles[i] -= obstacleSpeed * dt / 300;
      }
      _obstacles.removeWhere((x) => x < -0.1);
      while (_obstacles.length < 2) {
        final last = _obstacles.isEmpty ? 1.0 : _obstacles.reduce(max);
        _obstacles.add(last + 0.6 + _rand.nextDouble() * 0.5);
      }

      // Collision: obstacle near player's x (~0.12) and player not high enough
      for (final ox in _obstacles) {
        if (ox > 0.05 && ox < 0.19 && _playerY > -80) {
          _endGame();
          return;
        }
      }

      _score++;
    });
  }

  void _jump() {
    if (_jumping || _gameOver) return;
    _velocity = jumpVelocity;
    _jumping = true;
  }

  void _endGame() async {
    _gameOver = true;
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score ~/ 6);
  }

  void _reset() {
    setState(() {
      _playerY = 0;
      _velocity = 0;
      _jumping = false;
      _obstacles
        ..clear()
        ..addAll([1.2, 2.4]);
      _score = 0;
      _gameOver = false;
      _lastTick = Duration.zero;
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
    final displayScore = _score ~/ 6;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $displayScore')),
      body: SafeArea(
        child: GestureDetector(
          onTap: _jump,
          child: Stack(
            children: [
              Container(color: Theme.of(context).colorScheme.surfaceContainerHigh),
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final groundLevel = h * 0.75;
                  return Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: groundLevel,
                        child: Container(height: 2, color: Colors.grey),
                      ),
                      Positioned(
                        left: w * 0.12,
                        top: groundLevel - 40 + _playerY,
                        child: Container(
                          width: 36,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      for (final ox in _obstacles)
                        Positioned(
                          left: ox * w,
                          top: groundLevel - 34,
                          child: Container(
                            width: 24,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(child: Text('Tap to jump')),
              ),
              if (_gameOver)
                Container(
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
                            Text('${strings.t('score')}: $displayScore'),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
