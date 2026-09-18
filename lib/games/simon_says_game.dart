import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Watch the color sequence light up, then repeat it. Each round adds
/// one more step. Score = longest sequence successfully repeated.
class SimonSaysGame extends StatefulWidget {
  final GameModel game;
  const SimonSaysGame({super.key, required this.game});

  @override
  State<SimonSaysGame> createState() => _SimonSaysGameState();
}

class _SimonSaysGameState extends State<SimonSaysGame> {
  static const colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow];

  final List<int> _sequence = [];
  int _playerIndex = 0;
  int _highlighted = -1;
  bool _showingSequence = false;
  bool _gameOver = false;
  bool _started = false;
  final _rand = Random();

  void _start() {
    setState(() {
      _sequence.clear();
      _playerIndex = 0;
      _gameOver = false;
      _started = true;
    });
    _addStep();
  }

  void _addStep() {
    _sequence.add(_rand.nextInt(colors.length));
    _playerIndex = 0;
    _playSequence();
  }

  Future<void> _playSequence() async {
    setState(() => _showingSequence = true);
    await Future.delayed(const Duration(milliseconds: 400));
    for (final step in _sequence) {
      setState(() => _highlighted = step);
      await Future.delayed(const Duration(milliseconds: 420));
      setState(() => _highlighted = -1);
      await Future.delayed(const Duration(milliseconds: 180));
    }
    if (mounted) setState(() => _showingSequence = false);
  }

  void _tapColor(int i) {
    if (_showingSequence || _gameOver || !_started) return;
    if (i == _sequence[_playerIndex]) {
      _playerIndex++;
      if (_playerIndex == _sequence.length) {
        Future.delayed(const Duration(milliseconds: 500), _addStep);
      }
    } else {
      _endGame();
    }
  }

  void _endGame() async {
    setState(() => _gameOver = true);
    final score = _sequence.length - 1;
    await GameResultHandler.report(context, gameId: widget.game.id, score: score);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    final round = _sequence.isEmpty ? 0 : _sequence.length;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Round: $round')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_started || _gameOver)
                Column(
                  children: [
                    if (_gameOver) Text('${strings.t('game_over')} · ${strings.t('score')}: ${_sequence.length - 1}'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_gameOver ? strings.t('restart') : strings.t('play')),
                    ),
                  ],
                )
              else
                Text(_showingSequence ? 'Watch…' : 'Your turn',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                width: 260,
                height: 260,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: colors.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _tapColor(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: _highlighted == i ? colors[i] : colors[i].withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
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
