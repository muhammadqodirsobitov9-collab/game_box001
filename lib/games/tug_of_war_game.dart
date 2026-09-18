import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Tap as fast as you can for 5 seconds to pull the rope to your side
/// against a simulated CPU. Score = final rope position advantage
/// (0-100) if you win, 0 if you lose or tie.
class TugOfWarGame extends StatefulWidget {
  final GameModel game;
  const TugOfWarGame({super.key, required this.game});

  @override
  State<TugOfWarGame> createState() => _TugOfWarGameState();
}

class _TugOfWarGameState extends State<TugOfWarGame> {
  static const roundSeconds = 5;
  double _rope = 0.5; // 0 = CPU wins, 1 = player wins
  int _timeLeft = roundSeconds;
  bool _running = false;
  bool _finished = false;
  Timer? _clock;
  Timer? _cpuTimer;
  final _rand = Random();
  int _playerTaps = 0;

  void _start() {
    setState(() {
      _rope = 0.5;
      _timeLeft = roundSeconds;
      _running = true;
      _finished = false;
      _playerTaps = 0;
    });
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
    _cpuTimer?.cancel();
    _cpuTimer = Timer.periodic(const Duration(milliseconds: 180), (t) {
      if (!_running) return;
      setState(() => _rope = (_rope - (0.01 + _rand.nextDouble() * 0.02)).clamp(0.0, 1.0));
      if (_rope <= 0) _finish();
    });
  }

  void _tap() {
    if (!_running) return;
    _playerTaps++;
    setState(() => _rope = (_rope + 0.035).clamp(0.0, 1.0));
    if (_rope >= 1) _finish();
  }

  void _finish() async {
    _running = false;
    _clock?.cancel();
    _cpuTimer?.cancel();
    setState(() => _finished = true);
    final score = _rope > 0.5 ? ((_rope - 0.5) * 200).round() : 0;
    await GameResultHandler.report(context, gameId: widget.game.id, score: score);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _cpuTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · $_timeLeft s')),
      body: SafeArea(
        child: GestureDetector(
          onTap: _tap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text('CPU', style: TextStyle(color: _rope < 0.3 ? Colors.red : null, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Stack(
                  children: [
                    Container(height: 24, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 100),
                      alignment: Alignment(_rope * 2 - 1, 0),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text('You', style: TextStyle(color: _rope > 0.7 ? Colors.green : null, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              if (!_running && !_finished)
                FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: Text(strings.t('play'))),
              if (_running)
                const Text('TAP ANYWHERE FAST!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (_finished) ...[
                Text(_rope > 0.5 ? 'You win! 🎉' : (_rope < 0.5 ? 'CPU wins.' : 'Tie!'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FilledButton(onPressed: _start, child: Text(strings.t('restart'))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
