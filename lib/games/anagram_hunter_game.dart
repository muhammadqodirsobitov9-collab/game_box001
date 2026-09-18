import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Given a set of letters, find as many valid words hidden in them as
/// possible within 90 seconds. Uses a small fixed letter-set/word-list
/// pairing (rather than a full dictionary) so validation is exact.
/// Score = 10 per word found (longer words aren't weighted extra, to
/// keep the built-in word lists simple and fair).
class AnagramHunterGame extends StatefulWidget {
  final GameModel game;
  const AnagramHunterGame({super.key, required this.game});

  @override
  State<AnagramHunterGame> createState() => _AnagramHunterGameState();
}

class _AnagramHunterGameState extends State<AnagramHunterGame> {
  static const roundSeconds = 90;

  static const _sets = [
    (letters: 'TRIANGLES', words: ['RAT', 'RATS', 'TAG', 'TAGS', 'RING', 'STAR', 'STAIN', 'TRAIN', 'TRAINS', 'RATING', 'STRING']),
    (letters: 'COMPUTERS', words: ['CUP', 'CUPS', 'CORE', 'CORES', 'STORE', 'ROUTE', 'ROUTES', 'SPOUT', 'ESCORT', 'COMPUTE']),
    (letters: 'ADVENTURE', words: ['VAN', 'VANE', 'TUNE', 'TUNED', 'ADVENT', 'NATURE', 'ENDURE', 'VENTURE']),
  ];

  late String _letters;
  late Set<String> _validWords;
  final Set<String> _found = {};
  int _timeLeft = roundSeconds;
  bool _running = false;
  Timer? _clock;
  final _controller = TextEditingController();
  String _feedback = '';
  final _rand = Random();

  void _start() {
    final set = _sets[_rand.nextInt(_sets.length)];
    setState(() {
      _letters = set.letters;
      _validWords = set.words.where((w) => w.isNotEmpty).toSet();
      _found.clear();
      _timeLeft = roundSeconds;
      _running = true;
      _feedback = '';
      _controller.clear();
    });
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
  }

  void _submit() {
    if (!_running) return;
    final guess = _controller.text.trim().toUpperCase();
    _controller.clear();
    if (guess.isEmpty) return;
    if (_found.contains(guess)) {
      setState(() => _feedback = 'Already found');
      return;
    }
    if (_validWords.contains(guess)) {
      setState(() {
        _found.add(guess);
        _feedback = 'Nice! +10';
      });
    } else {
      setState(() => _feedback = 'Not in the list');
    }
  }

  void _finish() async {
    _running = false;
    _clock?.cancel();
    setState(() {});
    await GameResultHandler.report(context, gameId: widget.game.id, score: _found.length * 10);
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
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: ${_found.length * 10}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (!_running)
                Column(
                  children: [
                    if (_found.isNotEmpty)
                      Text('${strings.t('game_over')} · Found ${_found.length} words'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_found.isEmpty ? strings.t('play') : strings.t('restart')),
                    ),
                  ],
                )
              else ...[
                Text('$_timeLeft s left', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _letters.split('').join(' '),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Type a word'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _submit, child: const Text('Add')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_feedback),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: _found.map((w) => Chip(label: Text(w))).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
