import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Drag back and release to shoot the ball toward the hoop with an
/// arc; power and angle come from the drag vector. 30-second rounds.
/// Score = 10 per basket made.
class BasketballShootoutGame extends StatefulWidget {
  final GameModel game;
  const BasketballShootoutGame({super.key, required this.game});

  @override
  State<BasketballShootoutGame> createState() => _BasketballShootoutGameState();
}

class _BasketballShootoutGameState extends State<BasketballShootoutGame> with SingleTickerProviderStateMixin {
  static const roundSeconds = 30;
  static const hoopX = 0.5;
  static const hoopY = 0.15;

  late Ticker _ticker;
  Duration _lastTick = Duration.zero;

  Offset _ballPos = const Offset(0.5, 0.85);
  Offset _ballVel = Offset.zero;
  bool _inFlight = false;
  Offset? _dragStart;
  Offset? _dragCurrent;

  int _score = 0;
  int _timeLeft = roundSeconds;
  bool _running = false;
  Timer? _clock;
  bool _scoredThisShot = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _score = 0;
      _timeLeft = roundSeconds;
      _running = true;
      _resetBall();
    });
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
  }

  void _resetBall() {
    _ballPos = const Offset(0.5, 0.85);
    _ballVel = Offset.zero;
    _inFlight = false;
    _scoredThisShot = false;
  }

  void _onPanStart(DragStartDetails d, BoxConstraints c) {
    if (!_running || _inFlight) return;
    _dragStart = d.localPosition;
    _dragCurrent = d.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    setState(() => _dragCurrent = d.localPosition);
  }

  void _onPanEnd(BoxConstraints constraints) {
    if (_dragStart == null || _dragCurrent == null) return;
    final delta = _dragStart! - _dragCurrent!;
    setState(() {
      _ballVel = Offset(delta.dx / constraints.maxWidth * 1.8, delta.dy / constraints.maxHeight * 2.2);
      _inFlight = true;
    });
    _dragStart = null;
    _dragCurrent = null;
  }

  void _onTick(Duration elapsed) {
    if (!_running || !_inFlight) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) {
      _lastTick = elapsed;
      return;
    }

    var pos = _ballPos + _ballVel * dt;
    var vel = _ballVel + const Offset(0, 1.8) * dt; // gravity

    // Hoop check
    if (!_scoredThisShot && (pos - const Offset(hoopX, hoopY)).distance < 0.05 && vel.dy > 0) {
      _scoredThisShot = true;
      _score += 10;
    }

    if (pos.dy > 1.0 || pos.dx < -0.2 || pos.dx > 1.2) {
      setState(_resetBall);
      return;
    }

    setState(() {
      _ballPos = pos;
      _ballVel = vel;
    });
  }

  void _finish() async {
    _running = false;
    _clock?.cancel();
    setState(() {});
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score · $_timeLeft s')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth, h = constraints.maxHeight;
            return GestureDetector(
              onPanStart: (d) => _onPanStart(d, constraints),
              onPanUpdate: _onPanUpdate,
              onPanEnd: (_) => _onPanEnd(constraints),
              child: Stack(
                children: [
                  Container(color: Theme.of(context).colorScheme.surfaceContainerLow, width: double.infinity, height: double.infinity),
                  Positioned(
                    left: hoopX * w - 24,
                    top: hoopY * h - 6,
                    child: Container(width: 48, height: 12, decoration: BoxDecoration(border: Border.all(color: Colors.orange, width: 3))),
                  ),
                  Positioned(
                    left: _ballPos.dx * w - 14,
                    top: _ballPos.dy * h - 14,
                    child: Container(width: 28, height: 28, decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle)),
                  ),
                  if (_dragStart != null && _dragCurrent != null)
                    CustomPaint(
                      size: Size(w, h),
                      painter: _LinePainter(_dragStart!, _dragCurrent!),
                    ),
                  if (!_running)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_timeLeft != roundSeconds)
                                Text('${strings.t('game_over')} · ${strings.t('score')}: $_score',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _start,
                                icon: const Icon(Icons.play_arrow),
                                label: Text(_timeLeft == roundSeconds ? strings.t('play') : strings.t('restart')),
                              ),
                              const SizedBox(height: 8),
                              const Text('Drag back from the ball and release to shoot', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
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

class _LinePainter extends CustomPainter {
  final Offset from, to;
  _LinePainter(this.from, this.to);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 3;
    canvas.drawLine(from, to, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => oldDelegate.from != from || oldDelegate.to != to;
}
