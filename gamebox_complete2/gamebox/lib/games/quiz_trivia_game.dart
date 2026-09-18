import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

class _Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  const _Question(this.text, this.options, this.correctIndex);
}

/// General-knowledge multiple-choice quiz. Score = 10 per correct
/// answer across a fixed question bank, shuffled each session.
class QuizTriviaGame extends StatefulWidget {
  final GameModel game;
  const QuizTriviaGame({super.key, required this.game});

  @override
  State<QuizTriviaGame> createState() => _QuizTriviaGameState();
}

class _QuizTriviaGameState extends State<QuizTriviaGame> {
  static const _bank = [
    _Question('What is the capital of Japan?', ['Seoul', 'Tokyo', 'Beijing', 'Bangkok'], 1),
    _Question('How many continents are there?', ['5', '6', '7', '8'], 2),
    _Question('What planet is known as the Red Planet?', ['Venus', 'Mars', 'Jupiter', 'Saturn'], 1),
    _Question('What is the largest ocean on Earth?', ['Atlantic', 'Indian', 'Arctic', 'Pacific'], 3),
    _Question('Which language has the most native speakers?', ['English', 'Mandarin', 'Spanish', 'Hindi'], 1),
    _Question('How many legs does a spider have?', ['6', '8', '10', '12'], 1),
    _Question('What gas do plants absorb from the air?', ['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen'], 2),
    _Question('What is the smallest prime number?', ['0', '1', '2', '3'], 2),
    _Question('Which organ pumps blood through the body?', ['Lungs', 'Liver', 'Heart', 'Kidney'], 2),
    _Question('What is H2O commonly known as?', ['Salt', 'Water', 'Sugar', 'Oxygen'], 1),
  ];

  late List<_Question> _questions;
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = List.of(_bank)..shuffle();
    _index = 0;
    _score = 0;
  }

  void _answer(int i) async {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
      if (i == _questions[_index].correctIndex) _score += 10;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (_index + 1 >= _questions.length) {
      setState(() => _finished = true);
      await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
    } else {
      setState(() {
        _index++;
        _answered = false;
        _selected = null;
      });
    }
  }

  void _reset() {
    setState(() {
      _questions = List.of(_bank)..shuffle();
      _index = 0;
      _score = 0;
      _answered = false;
      _selected = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();

    if (_finished) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.game.name)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${strings.t('score')}: $_score / ${_questions.length * 10}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      );
    }

    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${_index + 1}/${_questions.length}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              for (var i = 0; i < q.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _answer(i),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _answered
                            ? (i == q.correctIndex
                                ? Colors.green.withValues(alpha: 0.3)
                                : (i == _selected ? Colors.red.withValues(alpha: 0.3) : null))
                            : null,
                      ),
                      child: Align(alignment: Alignment.centerLeft, child: Text(q.options[i])),
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
