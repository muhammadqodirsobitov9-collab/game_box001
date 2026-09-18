import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class _Pipe {
  double x; // 0..1+
  final double gapCenter; // 0..1
  bool scored = false;
  _Pipe({required this.x, required this.gapCenter});
}

/// Tap to flap a block through gaps between pipes. Score = pipes passed.
class FlappyBlockGame extends StatefulWidget {
  final GameModel game;
  const FlappyBlockGame({super.key, required this.game});

  @override
  State<FlappyBlockGame> createState() => _FlappyBlockGameState();
}

class _FlappyBlockGameState extends State<FlappyBlockGame> with SingleTickerProviderStateMixin {
  static const gravity = 2.6;
  static const flapVelocity = -0.85;
  static const gapHeight = 0.28;
  static const pipeSpeed = 0.28;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;

  double _birdY = 0.5;
  double _velocity = 0;
  final List<_Pipe> _pipes = [];
  int _score = 0;
  bool _running = false;
  bool _gameOver = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _birdY = 0.5;
      _velocity = 0;
      _pipes
        ..clear()
        ..addAll([
          _Pipe(x: 1.2, gapCenter: 0.3 + _rand.nextDouble() * 0.4),
          _Pipe(x: 1.8, gapCenter: 0.3 + _rand.nextDouble() * 0.4),
        ]);
      _score = 0;
      _running = true;
      _gameOver = false;
      _lastTick = Duration.zero;
    });
  }

  void _flap() {
    if (!_running) {
      _start();
      return;
    }
    _velocity = flapVelocity;
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    _velocity += gravity * dt;
    var newY = _birdY + _velocity * dt;

    for (final p in _pipes) {
      p.x -= pipeSpeed * dt;
    }
    _pipes.removeWhere((p) => p.x < -0.15);
    if (_pipes.isEmpty || _pipes.last.x < 0.7) {
      _pipes.add(_Pipe(x: 1.2, gapCenter: 0.25 + _rand.nextDouble() * 0.5));
    }

    // Collision with pipes at bird's x ~0.15
    for (final p in _pipes) {
      if (p.x > 0.08 && p.x < 0.22) {
        if (newY < p.gapCenter - gapHeight / 2 || newY > p.gapCenter + gapHeight / 2) {
          _finish();
          return;
        }
      }
      if (!p.scored && p.x < 0.15) {
        p.scored = true;
        _score++;
      }
    }

    if (newY < 0 || newY > 1) {
      _finish();
      return;
    }

    setState(() => _birdY = newY);
  }

  void _finish() async {
    _running = false;
    setState(() => _gameOver = true);
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
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
        child: GestureDetector(
          onTap: _flap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  Container(color: Theme.of(context).colorScheme.surfaceContainerLow),
                  for (final p in _pipes) ...[
                    Positioned(
                      left: p.x * w,
                      top: 0,
                      width: 40,
                      height: (p.gapCenter - gapHeight / 2) * h,
                      child: Container(color: Colors.green),
                    ),
                    Positioned(
                      left: p.x * w,
                      top: (p.gapCenter + gapHeight / 2) * h,
                      width: 40,
                      height: h - (p.gapCenter + gapHeight / 2) * h,
                      child: Container(color: Colors.green),
                    ),
                  ],
                  Positioned(
                    left: 0.15 * w - 16,
                    top: _birdY * h - 16,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
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
                                Text('${strings.t('game_over')} · ${strings.t('score')}: $_score',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _flap,
                                icon: const Icon(Icons.play_arrow),
                                label: Text(_gameOver ? strings.t('restart') : 'Tap to start'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
