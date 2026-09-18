import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Solve as many arithmetic problems as possible in 60 seconds.
/// Score = 10 per correct answer.
class SpeedMathGame extends StatefulWidget {
  final GameModel game;
  const SpeedMathGame({super.key, required this.game});

  @override
  State<SpeedMathGame> createState() => _SpeedMathGameState();
}

class _SpeedMathGameState extends State<SpeedMathGame> {
  static const roundSeconds = 60;

  int _a = 0, _b = 0;
  String _op = '+';
  int _answer = 0;
  int _score = 0;
  int _timeLeft = roundSeconds;
  bool _running = false;
  Timer? _clock;
  final _controller = TextEditingController();
  final _rand = Random();
  String _feedback = '';

  void _newProblem() {
    final ops = ['+', '-', '×'];
    _op = ops[_rand.nextInt(ops.length)];
    switch (_op) {
      case '+':
        _a = 1 + _rand.nextInt(50);
        _b = 1 + _rand.nextInt(50);
        _answer = _a + _b;
        break;
      case '-':
        _a = 10 + _rand.nextInt(80);
        _b = 1 + _rand.nextInt(_a);
        _answer = _a - _b;
        break;
      case '×':
        _a = 2 + _rand.nextInt(12);
        _b = 2 + _rand.nextInt(12);
        _answer = _a * _b;
        break;
    }
    _controller.clear();
  }

  void _start() {
    setState(() {
      _score = 0;
      _timeLeft = roundSeconds;
      _running = true;
      _feedback = '';
      _newProblem();
    });
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
  }

  void _submit() {
    if (!_running) return;
    final value = int.tryParse(_controller.text);
    if (value == null) return;
    setState(() {
      if (value == _answer) {
        _score += 10;
        _feedback = 'Correct!';
      } else {
        _feedback = 'Wrong, it was $_answer';
      }
      _newProblem();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score · $_timeLeft s')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_running)
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_timeLeft == roundSeconds ? strings.t('play') : strings.t('restart')),
                )
              else ...[
                Text('$_a $_op $_b = ?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Answer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _submit, child: const Text('Go')),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_feedback),
              ],
              if (!_running && _timeLeft != roundSeconds)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('${strings.t('game_over')} · ${strings.t('score')}: $_score'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
