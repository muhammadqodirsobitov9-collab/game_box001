import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Stroop-effect reflex game: a color name is shown rendered in a
/// (possibly different) color. Tap YES if the ink color matches the
/// word, NO if it doesn't. 45-second rounds, +10 per correct answer,
/// -5 per wrong one.
class ColorMatchGame extends StatefulWidget {
  final GameModel game;
  const ColorMatchGame({super.key, required this.game});

  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends State<ColorMatchGame> {
  static const roundSeconds = 45;
  static const _colors = {
    'RED': Colors.red,
    'GREEN': Colors.green,
    'BLUE': Colors.blue,
    'YELLOW': Colors.amber,
    'PURPLE': Colors.purple,
  };

  late String _word;
  late Color _inkColor;
  late bool _isMatch;
  int _score = 0;
  int _timeLeft = roundSeconds;
  bool _running = false;
  Timer? _clock;
  final _rand = Random();

  void _start() {
    setState(() {
      _score = 0;
      _timeLeft = roundSeconds;
      _running = true;
      _newRound();
    });
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
  }

  void _newRound() {
    final names = _colors.keys.toList();
    _word = names[_rand.nextInt(names.length)];
    _isMatch = _rand.nextBool();
    if (_isMatch) {
      _inkColor = _colors[_word]!;
    } else {
      final others = names.where((n) => n != _word).toList();
      _inkColor = _colors[others[_rand.nextInt(others.length)]]!;
    }
  }

  void _answer(bool userSaysMatch) {
    if (!_running) return;
    setState(() {
      if (userSaysMatch == _isMatch) {
        _score += 10;
      } else {
        _score = max(0, _score - 5);
      }
      _newRound();
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
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score · $_timeLeft s')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_running)
                Column(
                  children: [
                    if (_timeLeft != roundSeconds)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('${strings.t('game_over')} · ${strings.t('score')}: $_score'),
                      ),
                    const Text('Does the word match its ink color?', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_timeLeft == roundSeconds ? strings.t('play') : strings.t('restart')),
                    ),
                  ],
                )
              else ...[
                Text(_word, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _inkColor)),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _answer(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Match'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => _answer(false),
                      icon: const Icon(Icons.close),
                      label: const Text('No match'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
