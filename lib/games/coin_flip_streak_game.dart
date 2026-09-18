import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Predict heads or tails before each flip. Score = longest streak.
class CoinFlipStreakGame extends StatefulWidget {
  final GameModel game;
  const CoinFlipStreakGame({super.key, required this.game});

  @override
  State<CoinFlipStreakGame> createState() => _CoinFlipStreakGameState();
}

class _CoinFlipStreakGameState extends State<CoinFlipStreakGame> {
  bool _isHeads = true;
  int _streak = 0;
  int _best = 0;
  bool _flipping = false;
  bool _gameOver = false;
  String? _lastResult;
  final _rand = Random();

  void _guess(bool guessHeads) async {
    if (_flipping || _gameOver) return;
    setState(() => _flipping = true);
    for (var i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() => _isHeads = _rand.nextBool());
    }
    final result = _rand.nextBool();
    setState(() {
      _isHeads = result;
      _lastResult = result ? 'Heads' : 'Tails';
      _flipping = false;
      if (result == guessHeads) {
        _streak++;
        if (_streak > _best) _best = _streak;
      } else {
        _gameOver = true;
      }
    });
    if (_gameOver) {
      await GameResultHandler.report(context, gameId: widget.game.id, score: _best);
    }
  }

  void _reset() {
    setState(() {
      _streak = 0;
      _gameOver = false;
      _lastResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Streak: $_streak (best $_best)')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber[700],
                  border: Border.all(color: Colors.amber[900]!, width: 4),
                ),
                child: Center(
                  child: Text(
                    _isHeads ? 'H' : 'T',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_lastResult != null) Text('Last flip: $_lastResult'),
              const SizedBox(height: 24),
              if (_gameOver) ...[
                Text('${strings.t('game_over')} · Best streak: $_best'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(onPressed: _flipping ? null : () => _guess(true), child: const Text('Heads')),
                    const SizedBox(width: 16),
                    FilledButton(onPressed: _flipping ? null : () => _guess(false), child: const Text('Tails')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
