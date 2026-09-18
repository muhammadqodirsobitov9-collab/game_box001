import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

class _Target {
  double x, y;
  final double vx, vy;
  final bool isBonus;
  _Target({required this.x, required this.y, required this.vx, required this.vy, required this.isBonus});
}

/// Moving targets drift across the screen; tap them before they leave.
/// Missing a target (letting it exit) costs a life. 3 lives, game ends
/// when lives run out. Score = 10 per normal hit, 30 per bonus (gold) hit.
class TargetShooterGame extends StatefulWidget {
  final GameModel game;
  const TargetShooterGame({super.key, required this.game});

  @override
  State<TargetShooterGame> createState() => _TargetShooterGameState();
}

class _TargetShooterGameState extends State<TargetShooterGame> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Duration _lastSpawn = Duration.zero;

  final List<_Target> _targets = [];
  int _score = 0;
  int _lives = 3;
  bool _running = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _targets.clear();
      _score = 0;
      _lives = 3;
      _running = true;
      _lastTick = Duration.zero;
      _lastSpawn = Duration.zero;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    if (_lastSpawn == Duration.zero || (elapsed - _lastSpawn).inMilliseconds > 900) {
      _lastSpawn = elapsed;
      final fromLeft = _rand.nextBool();
      _targets.add(_Target(
        x: fromLeft ? -0.05 : 1.05,
        y: 0.1 + _rand.nextDouble() * 0.7,
        vx: (fromLeft ? 1 : -1) * (0.15 + _rand.nextDouble() * 0.15),
        vy: 0,
        isBonus: _rand.nextDouble() < 0.15,
      ));
    }

    final toRemove = <_Target>[];
    for (final t in _targets) {
      t.x += t.vx * dt;
      if (t.x < -0.1 || t.x > 1.1) toRemove.add(t);
    }
    if (toRemove.isNotEmpty) {
      _lives -= toRemove.length;
      for (final t in toRemove) {
        _targets.remove(t);
      }
      if (_lives <= 0) {
        _finish();
        return;
      }
    }
    setState(() {});
  }

  void _tapTarget(_Target t) {
    if (!_running) return;
    setState(() {
      _targets.remove(t);
      _score += t.isBonus ? 30 : 10;
    });
  }

  void _finish() async {
    _running = false;
    setState(() {});
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
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score · ❤️$_lives')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(color: Theme.of(context).colorScheme.surfaceContainerLow),
                for (final t in List.of(_targets))
                  Positioned(
                    left: t.x * constraints.maxWidth - 22,
                    top: t.y * constraints.maxHeight - 22,
                    child: GestureDetector(
                      onTap: () => _tapTarget(t),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: t.isBonus ? Colors.amber : Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.adjust, color: Colors.white, size: 20),
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
                            if (_lives <= 0)
                              Text('${strings.t('game_over')} · ${strings.t('score')}: $_score',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _start,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(_lives <= 0 ? strings.t('restart') : strings.t('play')),
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
    );
  }
}
