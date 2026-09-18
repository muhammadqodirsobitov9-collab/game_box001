import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Press and hold to inflate a balloon toward a hidden target size;
/// release as close to it as possible without bursting. 5 rounds,
/// each scored 0-100 based on distance from the target, summed.
class BalloonInflateGame extends StatefulWidget {
  final GameModel game;
  const BalloonInflateGame({super.key, required this.game});

  @override
  State<BalloonInflateGame> createState() => _BalloonInflateGameState();
}

class _BalloonInflateGameState extends State<BalloonInflateGame> {
  static const totalRounds = 5;
  static const burstSize = 220.0;
  static const minSize = 40.0;

  int _round = 0;
  int _totalScore = 0;
  double _size = minSize;
  late double _targetSize;
  Timer? _timer;
  bool _holding = false;
  bool _burst = false;
  bool _roundOver = false;
  bool _finished = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _round++;
    _size = minSize;
    _targetSize = 100 + _rand.nextDouble() * 90;
    _burst = false;
    _roundOver = false;
    setState(() {});
  }

  void _startHold() {
    if (_roundOver) return;
    _holding = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      setState(() => _size += 3.5);
      if (_size >= burstSize) {
        _timer?.cancel();
        _holding = false;
        _burst = true;
        _endRound(0);
      }
    });
  }

  void _release() {
    if (!_holding) return;
    _timer?.cancel();
    _holding = false;
    final distance = (_size - _targetSize).abs();
    final score = max(0, 100 - distance.round());
    _endRound(score);
  }

  void _endRound(int score) async {
    setState(() {
      _totalScore += score;
      _roundOver = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_round >= totalRounds) {
      setState(() => _finished = true);
      await GameResultHandler.report(context, gameId: widget.game.id, score: _totalScore);
    } else {
      _newRound();
    }
  }

  void _reset() {
    setState(() {
      _round = 0;
      _totalScore = 0;
      _finished = false;
    });
    _newRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    if (_finished) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.game.name)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${strings.t('score')}: $_totalScore / ${totalRounds * 100}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Round $_round/$totalRounds · Total: $_totalScore')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Hold to inflate — release at the right moment!', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: burstSize + 20,
                height: burstSize + 20,
                child: Center(
                  child: _burst
                      ? const Icon(Icons.close, size: 60, color: Colors.red)
                      : AnimatedContainer(
                          duration: const Duration(milliseconds: 30),
                          width: _size,
                          height: _size,
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              if (_roundOver)
                Text(_burst ? 'Popped! 0 points' : 'Round score recorded', style: const TextStyle(fontWeight: FontWeight.bold))
              else
                GestureDetector(
                  onTapDown: (_) => _startHold(),
                  onTapUp: (_) => _release(),
                  onTapCancel: _release,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text('HOLD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
