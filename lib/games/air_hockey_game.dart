import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';

/// 2D air hockey against a simple CPU. Drag your mallet anywhere in
/// your half; first to 5 goals wins. Score = goals you scored.
class AirHockeyGame extends StatefulWidget {
  final GameModel game;
  const AirHockeyGame({super.key, required this.game});

  @override
  State<AirHockeyGame> createState() => _AirHockeyGameState();
}

class _AirHockeyGameState extends State<AirHockeyGame> with SingleTickerProviderStateMixin {
  static const winScore = 5;
  static const malletRadius = 0.06;
  static const puckRadius = 0.03;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;

  Offset _playerPos = const Offset(0.5, 0.85);
  Offset _cpuPos = const Offset(0.5, 0.15);
  Offset _puckPos = const Offset(0.5, 0.5);
  Offset _puckVel = const Offset(0.15, 0.25);
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
      _puckPos = const Offset(0.5, 0.5);
      _puckVel = const Offset(0.15, 0.25);
      _running = true;
      _gameOver = false;
      _lastTick = Duration.zero;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    var pos = _puckPos + _puckVel * dt;
    var vel = _puckVel;

    if (pos.dx <= puckRadius || pos.dx >= 1 - puckRadius) {
      vel = Offset(-vel.dx, vel.dy);
      pos = Offset(pos.dx.clamp(puckRadius, 1 - puckRadius), pos.dy);
    }

    // CPU chases the puck within its half.
    final cpuTargetX = pos.dy < 0.5 ? pos.dx : 0.5;
    final newCpuX = (_cpuPos.dx + (cpuTargetX - _cpuPos.dx) * 3 * dt).clamp(0.1, 0.9);
    _cpuPos = Offset(newCpuX, _cpuPos.dy);

    // Collisions with mallets
    if ((pos - _playerPos).distance < malletRadius + puckRadius && vel.dy > 0) {
      final delta = pos - _playerPos;
      vel = Offset(delta.dx * 4, -vel.dy.abs());
    }
    if ((pos - _cpuPos).distance < malletRadius + puckRadius && vel.dy < 0) {
      final delta = pos - _cpuPos;
      vel = Offset(delta.dx * 4, vel.dy.abs());
    }

    // Goals: top = CPU goal (player scores), bottom = player goal (CPU scores)
    if (pos.dy < 0) {
      _playerScore++;
      pos = const Offset(0.5, 0.5);
      vel = const Offset(0.1, 0.25);
    } else if (pos.dy > 1) {
      _cpuScore++;
      pos = const Offset(0.5, 0.5);
      vel = const Offset(0.1, -0.25);
    }

    if (_playerScore >= winScore || _cpuScore >= winScore) {
      setState(() {
        _puckPos = pos;
        _puckVel = vel;
      });
      _finish();
      return;
    }

    setState(() {
      _puckPos = pos;
      _puckVel = vel;
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
      final dx = (_playerPos.dx + details.delta.dx / constraints.maxWidth).clamp(0.08, 0.92);
      final dy = (_playerPos.dy + details.delta.dy / constraints.maxHeight).clamp(0.55, 0.95);
      _playerPos = Offset(dx, dy);
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
            final w = constraints.maxWidth, h = constraints.maxHeight;
            return GestureDetector(
              onPanUpdate: (d) => _onDrag(d, constraints),
              child: Stack(
                children: [
                  Container(color: Theme.of(context).colorScheme.surfaceContainerLow, width: double.infinity, height: double.infinity),
                  Positioned(top: h / 2 - 1, left: 0, right: 0, child: Container(height: 2, color: Colors.grey)),
                  Positioned(
                    left: _cpuPos.dx * w - malletRadius * w,
                    top: _cpuPos.dy * h - malletRadius * w,
                    child: Container(width: malletRadius * 2 * w, height: malletRadius * 2 * w, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                  ),
                  Positioned(
                    left: _playerPos.dx * w - malletRadius * w,
                    top: _playerPos.dy * h - malletRadius * w,
                    child: Container(width: malletRadius * 2 * w, height: malletRadius * 2 * w, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
                  ),
                  Positioned(
                    left: _puckPos.dx * w - puckRadius * w,
                    top: _puckPos.dy * h - puckRadius * w,
                    child: Container(width: puckRadius * 2 * w, height: puckRadius * 2 * w, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
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
                                Text(_playerScore > _cpuScore ? 'You win! 🎉' : 'CPU wins.',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
            );
          },
        ),
      ),
    );
  }
}
