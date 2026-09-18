import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Guess the secret number between 1 and 100 in as few tries as
/// possible. Score = max(0, 110 - tries*10), so guessing it in 1 try
/// scores 100, running out of "free" tries trends toward 0.
class NumberGuessGame extends StatefulWidget {
  final GameModel game;
  const NumberGuessGame({super.key, required this.game});

  @override
  State<NumberGuessGame> createState() => _NumberGuessGameState();
}

class _NumberGuessGameState extends State<NumberGuessGame> {
  final _controller = TextEditingController();
  late int _secret;
  int _tries = 0;
  String _hint = 'Guess a number between 1 and 100';
  bool _won = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _secret = 1 + _rand.nextInt(100);
    _tries = 0;
    _hint = 'Guess a number between 1 and 100';
    _won = false;
    _controller.clear();
    setState(() {});
  }

  void _guess() async {
    final value = int.tryParse(_controller.text);
    if (value == null) return;
    setState(() {
      _tries++;
      if (value == _secret) {
        _won = true;
        _hint = 'Correct! It was $_secret.';
      } else if (value < _secret) {
        _hint = 'Higher than $value';
      } else {
        _hint = 'Lower than $value';
      }
    });
    _controller.clear();
    if (_won) {
      final score = (110 - _tries * 10).clamp(0, 100);
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    }
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
      appBar: AppBar(title: Text('${widget.game.name} · Tries: $_tries')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_hint, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (!_won)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        onSubmitted: (_) => _guess(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Your guess',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _guess, child: const Text('Guess')),
                  ],
                )
              else
                FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      ),
    );
  }
}
