import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Type the shown sentence as fast and accurately as possible.
/// Score = words-per-minute, penalized for errors.
class TypingSpeedGame extends StatefulWidget {
  final GameModel game;
  const TypingSpeedGame({super.key, required this.game});

  @override
  State<TypingSpeedGame> createState() => _TypingSpeedGameState();
}

class _TypingSpeedGameState extends State<TypingSpeedGame> {
  static const _sentences = [
    'The quick brown fox jumps over the lazy dog',
    'Flutter makes it easy to build beautiful apps',
    'Practice makes perfect when learning to type',
    'GameBox brings fun offline games to everyone',
    'A journey of a thousand miles begins with a single step',
  ];

  late String _target;
  final _controller = TextEditingController();
  Stopwatch? _stopwatch;
  bool _started = false;
  bool _finished = false;
  int? _wpm;
  int _errors = 0;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _pickSentence();
  }

  void _pickSentence() {
    _target = _sentences[_rand.nextInt(_sentences.length)];
    _controller.clear();
    _started = false;
    _finished = false;
    _wpm = null;
    _errors = 0;
    _stopwatch = null;
    setState(() {});
  }

  void _onChanged(String value) async {
    if (!_started) {
      _started = true;
      _stopwatch = Stopwatch()..start();
    }
    _errors = 0;
    for (var i = 0; i < value.length && i < _target.length; i++) {
      if (value[i] != _target[i]) _errors++;
    }
    if (value == _target) {
      _stopwatch?.stop();
      final minutes = (_stopwatch?.elapsed.inMilliseconds ?? 1) / 60000.0;
      final words = _target.split(' ').length;
      final wpm = (words / (minutes == 0 ? 0.01 : minutes)).round();
      setState(() {
        _finished = true;
        _wpm = wpm;
      });
      final score = (wpm - _errors * 2).clamp(0, 300);
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    } else {
      setState(() {});
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
    final typed = _controller.text;

    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 20, height: 1.5),
                  children: [
                    for (var i = 0; i < _target.length; i++)
                      TextSpan(
                        text: _target[i],
                        style: TextStyle(
                          color: i >= typed.length
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                              : (typed[i] == _target[i] ? Colors.green : Colors.red),
                          backgroundColor: i == typed.length
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                enabled: !_finished,
                onChanged: _onChanged,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Start typing…',
                ),
              ),
              const SizedBox(height: 16),
              if (_finished) ...[
                Text('$_wpm WPM · $_errors errors',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FilledButton(onPressed: _pickSentence, child: Text(strings.t('restart'))),
              ] else
                Text('Errors so far: $_errors'),
            ],
          ),
        ),
      ),
    );
  }
}
