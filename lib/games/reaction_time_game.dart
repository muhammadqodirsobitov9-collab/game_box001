import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';

enum _State { idle, waiting, ready, tooSoon, result }

/// Tap as soon as the screen turns green. Score = 1000 - reaction ms
/// (floored at 0) so faster reactions mean a higher "high score",
/// consistent with every other built-in game.
class ReactionTimeGame extends StatefulWidget {
  final GameModel game;
  const ReactionTimeGame({super.key, required this.game});

  @override
  State<ReactionTimeGame> createState() => _ReactionTimeGameState();
}

class _ReactionTimeGameState extends State<ReactionTimeGame> {
  _State _state = _State.idle;
  Timer? _timer;
  DateTime? _shownAt;
  int? _lastMs;
  int _bestMs = 999999;
  final _rand = Random();

  void _start() {
    setState(() => _state = _State.waiting);
    _timer = Timer(Duration(milliseconds: 1200 + _rand.nextInt(2500)), () {
      _shownAt = DateTime.now();
      setState(() => _state = _State.ready);
    });
  }

  void _tap() {
    switch (_state) {
      case _State.idle:
        _start();
        break;
      case _State.waiting:
        _timer?.cancel();
        setState(() => _state = _State.tooSoon);
        break;
      case _State.ready:
        final ms = DateTime.now().difference(_shownAt!).inMilliseconds;
        _lastMs = ms;
        if (ms < _bestMs) _bestMs = ms;
        setState(() => _state = _State.result);
        final score = max(0, 1000 - ms);
        GameResultHandler.report(context, gameId: widget.game.id, score: score);
        break;
      case _State.tooSoon:
      case _State.result:
        setState(() => _state = _State.idle);
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (_state) {
      case _State.idle:
        bg = Theme.of(context).colorScheme.primary;
        label = 'Tap to start';
        break;
      case _State.waiting:
        bg = Colors.redAccent;
        label = 'Wait for green…';
        break;
      case _State.ready:
        bg = Colors.green;
        label = 'TAP NOW!';
        break;
      case _State.tooSoon:
        bg = Colors.orange;
        label = 'Too soon! Tap to retry';
        break;
      case _State.result:
        bg = Theme.of(context).colorScheme.tertiary;
        label = '${_lastMs}ms  (best: $_bestMs ms)\nTap to try again';
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name)),
      body: GestureDetector(
        onTap: _tap,
        child: Container(
          color: bg,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
