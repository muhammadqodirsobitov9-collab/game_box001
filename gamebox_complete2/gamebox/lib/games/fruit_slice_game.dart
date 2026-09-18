import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

class _FallingItem {
  double x; // 0..1
  double y; // 0..1
  final bool isBomb;
  final double speed;
  _FallingItem({required this.x, required this.y, required this.isBomb, required this.speed});
}

/// Tap falling fruits for points; tapping a bomb ends the game.
/// Items fall faster over time. Score = 10 per fruit tapped.
class FruitSliceGame extends StatefulWidget {
  final GameModel game;
  const FruitSliceGame({super.key, required this.game});

  @override
  State<FruitSliceGame> createState() => _FruitSliceGameState();
}

class _FruitSliceGameState extends State<FruitSliceGame> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Duration _lastSpawn = Duration.zero;

  final List<_FallingItem> _items = [];
  int _score = 0;
  bool _running = false;
  bool _gameOver = false;
  final _rand = Random();

  static const _fruitIcons = [Icons.circle, Icons.eco, Icons.local_florist];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _start() {
    setState(() {
      _items.clear();
      _score = 0;
      _running = true;
      _gameOver = false;
      _lastTick = Duration.zero;
      _lastSpawn = Duration.zero;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    if (_lastSpawn == Duration.zero || (elapsed - _lastSpawn).inMilliseconds > 700) {
      _lastSpawn = elapsed;
      _items.add(_FallingItem(
        x: 0.1 + _rand.nextDouble() * 0.8,
        y: -0.05,
        isBomb: _rand.nextDouble() < 0.2,
        speed: 0.25 + _rand.nextDouble() * 0.15 + (_score * 0.002),
      ));
    }

    for (final item in _items) {
      item.y += item.speed * dt;
    }
    _items.removeWhere((i) => i.y > 1.1);

    setState(() {});
  }

  void _tapItem(_FallingItem item) async {
    if (!_running) return;
    if (item.isBomb) {
      _items.remove(item);
      _finish();
      return;
    }
    setState(() {
      _items.remove(item);
      _score += 10;
    });
  }

  void _finish() async {
    _running = false;
    setState(() => _gameOver = true);
    await GameResultHandler.report(context, gameId: widget.game.id, score: _score);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${strings.t('score')}: $_score')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(color: Theme.of(context).colorScheme.surfaceContainerLow),
                for (final item in List.of(_items))
                  Positioned(
                    left: item.x * constraints.maxWidth - 20,
                    top: item.y * constraints.maxHeight - 20,
                    child: GestureDetector(
                      onTap: () => _tapItem(item),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.isBomb ? Colors.black87 : Colors.primaries[item.hashCode % Colors.primaries.length],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isBomb ? Icons.dangerous : _fruitIcons[item.hashCode % _fruitIcons.length],
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                if (!_running)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_gameOver)
                              Text('${strings.t('game_over')} · ${strings.t('score')}: $_score',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _start,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(_gameOver ? strings.t('restart') : strings.t('play')),
                            ),
                            const SizedBox(height: 8),
                            const Text('Avoid the black bombs!', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
