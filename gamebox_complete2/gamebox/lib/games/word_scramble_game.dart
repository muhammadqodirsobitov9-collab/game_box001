import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Unscramble the letters to form the word. Score accumulates across
/// a word list, +10 per correct word minus a penalty for hints.
///
/// If `widget.game.customData['words']` is present (set when this
/// game came from an Admin Panel ZIP import), that word list is used
/// instead of the built-in default — this is the concrete example of
/// content-driven publishing described in AdminService.
class WordScrambleGame extends StatefulWidget {
  final GameModel game;
  const WordScrambleGame({super.key, required this.game});

  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame> {
  static const _defaultWords = [
    'FLUTTER', 'PUZZLE', 'GAMEBOX', 'MOBILE', 'WIDGET',
    'ARCADE', 'PIXEL', 'SCORE', 'PLAYER', 'LEVEL',
  ];

  late List<String> _pool;
  int _index = 0;
  late String _scrambled;
  int _score = 0;
  bool _usedHint = false;
  final _controller = TextEditingController();
  String _feedback = '';
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    final custom = widget.game.customData?['words'];
    final words = (custom is List && custom.isNotEmpty)
        ? custom.map((w) => w.toString().toUpperCase()).toList()
        : _defaultWords;
    _pool = List<String>.of(words)..shuffle();
    _score = 0;
    _index = 0;
    _scramble();
  }

  void _scramble() {
    final word = _pool[_index];
    List<String> letters;
    do {
      letters = word.split('')..shuffle(_rand);
    } while (letters.join() == word);
    _scrambled = letters.join();
    _usedHint = false;
    _feedback = '';
    _controller.clear();
    setState(() {});
  }

  void _submit() async {
    final guess = _controller.text.trim().toUpperCase();
    final answer = _pool[_index];
    if (guess == answer) {
      setState(() {
        _score += _usedHint ? 5 : 10;
        _feedback = 'Correct!';
      });
      await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _pool.length;
        if (_index == 0) _pool.shuffle();
      });
      _scramble();
    } else {
      setState(() => _feedback = 'Try again');
    }
  }

  void _hint() {
    setState(() {
      _usedHint = true;
      _feedback = 'First letter: ${_pool[_index][0]}';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _scrambled.split('').join(' '),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Your answer',
                ),
              ),
              const SizedBox(height: 12),
              Text(_feedback, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(onPressed: _submit, child: const Text('Submit')),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: _hint, child: const Text('Hint')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
