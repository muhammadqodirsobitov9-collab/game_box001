import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// A grid of identical colored shapes hides one subtly different tile
/// (slightly different shade). Find it before time runs out; each
/// round shrinks the time limit and the color difference slightly.
/// Score = 10 per round solved.
class OddOneOutGame extends StatefulWidget {
  final GameModel game;
  const OddOneOutGame({super.key, required this.game});

  @override
  State<OddOneOutGame> createState() => _OddOneOutGameState();
}

class _OddOneOutGameState extends State<OddOneOutGame> {
  int _round = 0;
  int _score = 0;
  int _gridSize = 3;
  int _oddIndex = 0;
  double _diff = 0.22;
  int _timeLeft = 5;
  Timer? _timer;
  bool _running = false;
  bool _gameOver = false;
  Color _baseColor = Colors.blue;
  final _rand = Random();

  void _start() {
    setState(() {
      _round = 0;
      _score = 0;
      _gridSize = 3;
      _diff = 0.22;
      _running = true;
      _gameOver = false;
    });
    _newRound();
  }

  void _newRound() {
    _round++;
    if (_round > 3) _gridSize = 4;
    if (_round > 6) _gridSize = 5;
    _diff = max(0.06, 0.22 - _round * 0.015);
    _oddIndex = _rand.nextInt(_gridSize * _gridSize);
    final hues = [Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange, Colors.teal];
    _baseColor = hues[_rand.nextInt(hues.length)];
    _timeLeft = max(3, 6 - (_round ~/ 3));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
    setState(() {});
  }

  void _tap(int i) async {
    if (!_running) return;
    if (i == _oddIndex) {
      _timer?.cancel();
      setState(() => _score += 10);
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      _newRound();
    } else {
      _finish();
    }
  }

  void _finish() async {
    _running = false;
    _timer?.cancel();
    setState(() => _gameOver = true);
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_running)
                Column(
                  children: [
                    if (_gameOver) Text('${strings.t('game_over')} · ${strings.t('score')}: $_score'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_gameOver ? strings.t('restart') : strings.t('play')),
                    ),
                  ],
                )
              else ...[
                Text('Round $_round · $_timeLeft s', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  width: 280,
                  height: 280,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: _gridSize * _gridSize,
                    itemBuilder: (context, i) {
                      final isOdd = i == _oddIndex;
                      final color = isOdd
                          ? Color.lerp(_baseColor, Colors.white, _diff)!
                          : _baseColor;
                      return GestureDetector(
                        onTap: () => _tap(i),
                        child: Container(
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
