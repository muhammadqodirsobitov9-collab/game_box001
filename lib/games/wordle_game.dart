import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

enum _LetterState { unknown, absent, present, correct }

/// Wordle-style 5-letter word guessing with 6 attempts. Guesses are
/// validated against the same small word bank the answer is drawn
/// from (rather than a full dictionary), so every guess is guaranteed
/// meaningful. Score = (7 - guessesUsed) * 100 on a win, 0 on a loss.
class WordleGame extends StatefulWidget {
  final GameModel game;
  const WordleGame({super.key, required this.game});

  @override
  State<WordleGame> createState() => _WordleGameState();
}

class _WordleGameState extends State<WordleGame> {
  static const _words = [
    'FLUTE', 'CRANE', 'PLANT', 'STONE', 'BRAVE',
    'GHOST', 'SHINE', 'CLOUD', 'TRAIN', 'SPARK',
  ];
  static const maxGuesses = 6;

  late String _answer;
  final List<String> _guesses = [];
  final List<List<_LetterState>> _results = [];
  String _current = '';
  bool _won = false;
  bool _lost = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _answer = _words[_rand.nextInt(_words.length)];
    _guesses.clear();
    _results.clear();
    _current = '';
    _won = false;
    _lost = false;
    setState(() {});
  }

  void _addLetter(String l) {
    if (_won || _lost || _current.length >= 5) return;
    setState(() => _current += l);
  }

  void _backspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _submit() async {
    if (_current.length != 5) return;
    if (!_words.contains(_current)) {
      setState(() {}); // no-op, could show a "not in list" hint
      return;
    }
    final guess = _current;
    final result = List.generate(5, (i) {
      if (guess[i] == _answer[i]) return _LetterState.correct;
      if (_answer.contains(guess[i])) return _LetterState.present;
      return _LetterState.absent;
    });
    setState(() {
      _guesses.add(guess);
      _results.add(result);
      _current = '';
      if (guess == _answer) {
        _won = true;
      } else if (_guesses.length >= maxGuesses) {
        _lost = true;
      }
    });
    if (_won) {
      final score = (7 - _guesses.length) * 100;
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    } else if (_lost) {
      await GameResultHandler.report(context, gameId: widget.game.id, score: 0);
    }
  }

  Color _colorFor(_LetterState s) {
    switch (s) {
      case _LetterState.correct:
        return Colors.green;
      case _LetterState.present:
        return Colors.amber;
      case _LetterState.absent:
        return Colors.grey;
      case _LetterState.unknown:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${_guesses.length}/$maxGuesses')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            for (var r = 0; r < maxGuesses; r++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (c) {
                    String letter = '';
                    Color color = Theme.of(context).colorScheme.surfaceContainerHigh;
                    if (r < _guesses.length) {
                      letter = _guesses[r][c];
                      color = _colorFor(_results[r][c]);
                    } else if (r == _guesses.length && c < _current.length) {
                      letter = _current[c];
                    }
                    return Container(
                      width: 46,
                      height: 46,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: Text(letter, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    );
                  }),
                ),
              ),
            const SizedBox(height: 12),
            if (_won || _lost) ...[
              Text(_won ? 'You got it! 🎉' : 'The word was $_answer', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ] else
              _buildKeyboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    const rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Wrap(
              spacing: 4,
              children: [
                for (final l in row.split(''))
                  SizedBox(
                    width: 30,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _addLetter(l),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(l, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: _backspace, child: const Icon(Icons.backspace_outlined, size: 16)),
            const SizedBox(width: 12),
            FilledButton(onPressed: _submit, child: const Text('Enter')),
          ],
        ),
      ],
    );
  }
}
