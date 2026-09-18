import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Tap the mole before it disappears. 30-second rounds, one active
/// hole at a time, speeding up as the timer runs down.
class WhackAMoleGame extends StatefulWidget {
  final GameModel game;
  const WhackAMoleGame({super.key, required this.game});

  @override
  State<WhackAMoleGame> createState() => _WhackAMoleGameState();
}

class _WhackAMoleGameState extends State<WhackAMoleGame> {
  static const gridCount = 9;
  static const roundSeconds = 30;

  int _activeHole = -1;
  int _score = 0;
  int _timeLeft = roundSeconds;
  bool _running = false;
  Timer? _moleTimer;
  Timer? _clock;
  final _rand = Random();

  void _start() {
    setState(() {
      _score = 0;
      _timeLeft = roundSeconds;
      _running = true;
    });
    _scheduleNextMole();
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
  }

  void _scheduleNextMole() {
    _moleTimer?.cancel();
    if (!_running) return;
    final speed = max(280, 900 - (roundSeconds - _timeLeft) * 20);
    _moleTimer = Timer(Duration(milliseconds: speed + _rand.nextInt(300)), () {
      if (!_running) return;
      setState(() => _activeHole = _rand.nextInt(gridCount));
      _scheduleNextMole();
    });
  }

  void _tapHole(int i) {
    if (!_running) return;
    if (i == _activeHole) {
      setState(() {
        _score += 10;
        _activeHole = -1;
      });
    }
  }

  void _finish() async {
    _running = false;
    _moleTimer?.cancel();
    _clock?.cancel();
    setState(() => _activeHole = -1);
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  @override
  void dispose() {
    _moleTimer?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.game.name} · ${strings.t('score')}: $_score · $_timeLeft s'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_running)
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(strings.t('play')),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                height: 300,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: gridCount,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _tapHole(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: i == _activeHole
                            ? const Icon(Icons.pest_control_rodent, size: 40, color: Colors.brown)
                            : null,
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
