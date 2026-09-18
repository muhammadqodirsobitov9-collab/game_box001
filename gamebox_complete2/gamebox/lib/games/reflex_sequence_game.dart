import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

class _NumberSpot {
  final int value;
  final double x, y;
  _NumberSpot(this.value, this.x, this.y);
}

/// Numbered circles 1-15 are scattered randomly; tap them in
/// ascending order as fast as possible. Score = max(0, 3000 - ms taken).
class ReflexSequenceGame extends StatefulWidget {
  final GameModel game;
  const ReflexSequenceGame({super.key, required this.game});

  @override
  State<ReflexSequenceGame> createState() => _ReflexSequenceGameState();
}

class _ReflexSequenceGameState extends State<ReflexSequenceGame> {
  static const count = 15;
  late List<_NumberSpot> _spots;
  int _next = 1;
  DateTime? _startTime;
  int? _elapsedMs;
  bool _running = false;
  final _rand = Random();

  void _start() {
    final spots = <_NumberSpot>[];
    for (var i = 1; i <= count; i++) {
      spots.add(_NumberSpot(i, 0.08 + _rand.nextDouble() * 0.84, 0.08 + _rand.nextDouble() * 0.84));
    }
    setState(() {
      _spots = spots;
      _next = 1;
      _running = true;
      _elapsedMs = null;
      _startTime = DateTime.now();
    });
  }

  void _tap(_NumberSpot spot) async {
    if (!_running || spot.value != _next) return;
    if (_next == count) {
      final ms = DateTime.now().difference(_startTime!).inMilliseconds;
      setState(() {
        _running = false;
        _elapsedMs = ms;
      });
      final score = (3000 - ms).clamp(0, 3000);
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    } else {
      setState(() => _next++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!_running && _elapsedMs == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tap the numbers 1 → 15 as fast as you can', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: Text(strings.t('play'))),
                  ],
                ),
              );
            }
            if (!_running && _elapsedMs != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_elapsedMs}ms', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _start, child: Text(strings.t('restart'))),
                  ],
                ),
              );
            }
            return Stack(
              children: [
                for (final spot in _spots)
                  if (spot.value >= _next)
                    Positioned(
                      left: spot.x * constraints.maxWidth - 20,
                      top: spot.y * constraints.maxHeight - 20,
                      child: GestureDetector(
                        onTap: () => _tap(spot),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: spot.value == _next
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${spot.value}',
                                style: TextStyle(
                                  color: spot.value == _next ? Colors.white : null,
                                  fontWeight: FontWeight.bold,
                                )),
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
