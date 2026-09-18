import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

class _Note {
  final int lane;
  double y; // 0 = spawn, 1 = target line
  bool hit = false;
  bool missed = false;
  _Note(this.lane, this.y);
}

/// 3-lane rhythm game: notes fall toward a target line; tap the
/// matching lane button as each note crosses it. Score = 10 per
/// perfect/good hit, missed notes score 0 and don't end the game.
class RhythmTapGame extends StatefulWidget {
  final GameModel game;
  const RhythmTapGame({super.key, required this.game});

  @override
  State<RhythmTapGame> createState() => _RhythmTapGameState();
}

class _RhythmTapGameState extends State<RhythmTapGame> with SingleTickerProviderStateMixin {
  static const lanes = 3;
  static const roundSeconds = 30;
  static const targetY = 0.85;
  static const hitWindow = 0.08;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Duration _lastSpawn = Duration.zero;
  Duration _elapsedTotal = Duration.zero;

  final List<_Note> _notes = [];
  int _score = 0;
  int _combo = 0;
  bool _running = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _notes.clear();
      _score = 0;
      _combo = 0;
      _running = true;
      _lastTick = Duration.zero;
      _lastSpawn = Duration.zero;
      _elapsedTotal = Duration.zero;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;
    _elapsedTotal += Duration(microseconds: (dt * 1e6).round());

    if (_elapsedTotal.inSeconds >= roundSeconds) {
      _finish();
      return;
    }

    if (_lastSpawn == Duration.zero || (elapsed - _lastSpawn).inMilliseconds > 650) {
      _lastSpawn = elapsed;
      _notes.add(_Note(_rand.nextInt(lanes), 0));
    }

    for (final n in _notes) {
      n.y += 0.55 * dt;
      if (n.y > targetY + hitWindow && !n.hit && !n.missed) {
        n.missed = true;
        _combo = 0;
      }
    }
    _notes.removeWhere((n) => n.y > 1.1);

    setState(() {});
  }

  void _tapLane(int lane) {
    if (!_running) return;
    _Note? best;
    for (final n in _notes) {
      if (n.lane == lane && !n.hit && !n.missed && (n.y - targetY).abs() < hitWindow) {
        if (best == null || (n.y - targetY).abs() < (best.y - targetY).abs()) best = n;
      }
    }
    if (best != null) {
      setState(() {
        best!.hit = true;
        _combo++;
        _score += 10;
      });
    }
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
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score · Combo: $_combo')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth, h = constraints.maxHeight;
            final laneW = w / lanes;
            return Stack(
              children: [
                Container(color: Theme.of(context).colorScheme.surfaceContainerLow, width: double.infinity, height: double.infinity),
                Positioned(top: targetY * h, left: 0, right: 0, child: Container(height: 4, color: Colors.amber)),
                for (var l = 0; l < lanes; l++)
                  Positioned(left: l * laneW, top: 0, bottom: 0, child: Container(width: 1, color: Colors.white24)),
                for (final n in List.of(_notes))
                  if (!n.hit)
                    Positioned(
                      left: n.lane * laneW + laneW * 0.2,
                      top: n.y * h,
                      width: laneW * 0.6,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: n.missed ? Colors.grey : Colors.cyanAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List.generate(lanes, (l) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _tapLane(l),
                          child: Container(
                            height: 70,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.touch_app),
                          ),
                        ),
                      );
                    }),
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
                            if (_elapsedTotal.inSeconds > 0)
                              Text('${strings.t('game_over')} · ${strings.t('score')}: $_score',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _start,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(_elapsedTotal.inSeconds == 0 ? strings.t('play') : strings.t('restart')),
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
