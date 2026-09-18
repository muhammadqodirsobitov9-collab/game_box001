import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// A crosshair sweeps back and forth across the dartboard; tap to
/// throw when it's positioned where you want. 5 darts per game.
/// Score = sum of ring values hit (bullseye 50, inner 25, outer rings
/// scaled by distance).
class DartsGame extends StatefulWidget {
  final GameModel game;
  const DartsGame({super.key, required this.game});

  @override
  State<DartsGame> createState() => _DartsGameState();
}

class _DartsGameState extends State<DartsGame> with SingleTickerProviderStateMixin {
  static const totalDarts = 5;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _sweepAngle = 0;
  double _sweepRadius = 0.3;
  int _direction = 1;

  int _dartsThrown = 0;
  int _totalScore = 0;
  final List<Offset> _hits = [];
  bool _running = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _dartsThrown = 0;
      _totalScore = 0;
      _hits.clear();
      _running = true;
      _sweepRadius = _rand.nextDouble() * 0.35;
      _sweepAngle = 0;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;
    setState(() {
      _sweepAngle += _direction * 2.4 * dt;
      if (_sweepAngle > 2 * pi) _sweepAngle -= 2 * pi;
      _sweepRadius += 0.15 * dt * (_dartsThrown % 2 == 0 ? 1 : -1);
      _sweepRadius = _sweepRadius.clamp(0.02, 0.42);
    });
  }

  void _throwDart() async {
    if (!_running) return;
    final x = 0.5 + cos(_sweepAngle) * _sweepRadius;
    final y = 0.5 + sin(_sweepAngle) * _sweepRadius;
    final distance = _sweepRadius; // 0 = bullseye, 0.42 = edge
    int points;
    if (distance < 0.04) {
      points = 50;
    } else if (distance < 0.1) {
      points = 25;
    } else if (distance < 0.2) {
      points = 15;
    } else if (distance < 0.3) {
      points = 10;
    } else {
      points = 5;
    }
    setState(() {
      _hits.add(Offset(x, y));
      _totalScore += points;
      _dartsThrown++;
    });
    if (_dartsThrown >= totalDarts) {
      _running = false;
      await GameResultHandler.report(context, gameId: widget.game.id, score: _totalScore);
    }
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
      appBar: AppBar(title: Text('${widget.game.name} · Darts: $_dartsThrown/$totalDarts · ${strings.t('score')}: $_totalScore')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _throwDart,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: _DartboardPainter(
                      sweep: _running ? Offset(0.5 + cos(_sweepAngle) * _sweepRadius, 0.5 + sin(_sweepAngle) * _sweepRadius) : null,
                      hits: _hits,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!_running)
                Column(
                  children: [
                    if (_dartsThrown > 0) Text('Final score: $_totalScore'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_dartsThrown == 0 ? strings.t('play') : strings.t('restart')),
                    ),
                  ],
                )
              else
                const Text('Tap the board to throw!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DartboardPainter extends CustomPainter {
  final Offset? sweep;
  final List<Offset> hits;
  _DartboardPainter({required this.sweep, required this.hits});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final rings = [
      (1.0, Colors.green[800]!),
      (0.7, Colors.red[700]!),
      (0.48, Colors.green[600]!),
      (0.24, Colors.red[600]!),
      (0.1, Colors.amber),
    ];
    for (final ring in rings) {
      canvas.drawCircle(center, maxR * ring.$1, Paint()..color = ring.$2);
    }

    if (sweep != null) {
      canvas.drawCircle(
        Offset(sweep!.dx * size.width, sweep!.dy * size.height),
        6,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(sweep!.dx * size.width, sweep!.dy * size.height),
        6,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    for (final h in hits) {
      canvas.drawCircle(Offset(h.dx * size.width, h.dy * size.height), 4, Paint()..color = Colors.blueAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _DartboardPainter oldDelegate) => true;
}
