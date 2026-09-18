import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Roll two dice against the CPU, best of 5 rounds. Score = rounds won.
class DiceDuelGame extends StatefulWidget {
  final GameModel game;
  const DiceDuelGame({super.key, required this.game});

  @override
  State<DiceDuelGame> createState() => _DiceDuelGameState();
}

class _DiceDuelGameState extends State<DiceDuelGame> {
  static const totalRounds = 5;
  int _round = 0;
  int _playerWins = 0;
  int _cpuWins = 0;
  int _playerRoll = 1;
  int _cpuRoll = 1;
  String _feedback = 'Tap Roll to start';
  bool _rolling = false;
  bool _finished = false;
  final _rand = Random();

  void _roll() async {
    if (_rolling || _finished) return;
    setState(() => _rolling = true);
    for (var i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() {
        _playerRoll = 1 + _rand.nextInt(6);
        _cpuRoll = 1 + _rand.nextInt(6);
      });
    }
    setState(() {
      _round++;
      if (_playerRoll > _cpuRoll) {
        _playerWins++;
        _feedback = 'You win this round!';
      } else if (_cpuRoll > _playerRoll) {
        _cpuWins++;
        _feedback = 'CPU wins this round!';
      } else {
        _feedback = 'Tie!';
      }
      _rolling = false;
      if (_round >= totalRounds) _finished = true;
    });
    if (_finished) {
      await GameResultHandler.report(context, gameId: widget.game.id, score: _playerWins);
    }
  }

  void _reset() {
    setState(() {
      _round = 0;
      _playerWins = 0;
      _cpuWins = 0;
      _playerRoll = 1;
      _cpuRoll = 1;
      _feedback = 'Tap Roll to start';
      _finished = false;
    });
  }

  Widget _die(int value) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
      ),
      child: Center(
        child: Text('$value', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Round $_round/$totalRounds')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You $_playerWins - $_cpuWins CPU', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(children: [_die(_playerRoll), const SizedBox(height: 6), const Text('You')]),
                  const SizedBox(width: 40),
                  Column(children: [_die(_cpuRoll), const SizedBox(height: 6), const Text('CPU')]),
                ],
              ),
              const SizedBox(height: 24),
              Text(_feedback, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              if (_finished)
                Column(
                  children: [
                    Text(_playerWins > _cpuWins ? 'You win the match! 🎉' : (_playerWins < _cpuWins ? 'CPU wins the match.' : 'Match tied.')),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: _roll,
                  icon: const Icon(Icons.casino),
                  label: const Text('Roll'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
