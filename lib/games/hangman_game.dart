import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Classic Hangman: guess the word one letter at a time before you
/// run out of attempts. Score = 100 - 10 per wrong guess (min 0) on a win.
class HangmanGame extends StatefulWidget {
  final GameModel game;
  const HangmanGame({super.key, required this.game});

  @override
  State<HangmanGame> createState() => _HangmanGameState();
}

class _HangmanGameState extends State<HangmanGame> {
  static const _words = [
    'FLUTTER', 'PYTHON', 'KEYBOARD', 'ELEPHANT', 'JOURNEY',
    'RAINBOW', 'CRYSTAL', 'VOLCANO', 'PENGUIN', 'PUZZLE',
  ];
  static const maxWrong = 6;

  late String _word;
  final Set<String> _guessed = {};
  int _wrong = 0;
  bool _won = false;
  bool _lost = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _word = _words[_rand.nextInt(_words.length)];
    _guessed.clear();
    _wrong = 0;
    _won = false;
    _lost = false;
    setState(() {});
  }

  void _guess(String letter) async {
    if (_won || _lost || _guessed.contains(letter)) return;
    setState(() {
      _guessed.add(letter);
      if (!_word.contains(letter)) {
        _wrong++;
        if (_wrong >= maxWrong) _lost = true;
      } else if (_word.split('').every((c) => _guessed.contains(c))) {
        _won = true;
      }
    });
    if (_won) {
      final score = (100 - _wrong * 10).clamp(0, 100);
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    final display = _word.split('').map((c) => _guessed.contains(c) ? c : '_').join(' ');
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Wrong: $_wrong/$maxWrong')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(display, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
              const SizedBox(height: 16),
              if (_lost) Text('The word was: $_word', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (_won) const Text('You got it! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: letters.split('').map((l) {
                  final used = _guessed.contains(l);
                  final correct = used && _word.contains(l);
                  return SizedBox(
                    width: 38,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: (used || _won || _lost) ? null : () => _guess(l),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: used ? (correct ? Colors.green : Colors.redAccent) : null,
                      ),
                      child: Text(l),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_won || _lost)
                FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      ),
    );
  }
}
