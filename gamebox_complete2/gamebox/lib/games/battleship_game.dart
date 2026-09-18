import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Single-player Battleship: find all hidden ships on a 6x6 grid in
/// as few shots as possible. Score = max(0, 100 - misses*5).
class BattleshipGame extends StatefulWidget {
  final GameModel game;
  const BattleshipGame({super.key, required this.game});

  @override
  State<BattleshipGame> createState() => _BattleshipGameState();
}

class _BattleshipGameState extends State<BattleshipGame> {
  static const size = 6;
  static const shipSizes = [3, 2, 2];

  late List<bool> _ships;
  late List<bool> _hit;
  late List<bool> _revealed;
  int _shots = 0;
  int _hits = 0;
  bool _finished = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _ships = List.filled(size * size, false);
    _hit = List.filled(size * size, false);
    _revealed = List.filled(size * size, false);
    _shots = 0;
    _hits = 0;
    _finished = false;
    _placeShips();
    setState(() {});
  }

  void _placeShips() {
    for (final len in shipSizes) {
      var placed = false;
      while (!placed) {
        final horizontal = _rand.nextBool();
        final r = _rand.nextInt(size);
        final c = _rand.nextInt(size);
        final cells = <int>[];
        var fits = true;
        for (var i = 0; i < len; i++) {
          final rr = horizontal ? r : r + i;
          final cc = horizontal ? c + i : c;
          if (rr >= size || cc >= size || _ships[rr * size + cc]) {
            fits = false;
            break;
          }
          cells.add(rr * size + cc);
        }
        if (fits) {
          for (final idx in cells) {
            _ships[idx] = true;
          }
          placed = true;
        }
      }
    }
  }

  void _tap(int i) async {
    if (_finished || _revealed[i]) return;
    setState(() {
      _revealed[i] = true;
      _shots++;
      if (_ships[i]) {
        _hit[i] = true;
        _hits++;
        if (_hits == shipSizes.fold<int>(0, (a, b) => a + b)) {
          _finished = true;
        }
      }
    });
    if (_finished) {
      final misses = _shots - _hits;
      final score = (100 - misses * 5).clamp(0, 100);
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    final totalShipCells = shipSizes.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Shots: $_shots · Hits: $_hits/$totalShipCells')),
      body: SafeArea(
        child: Column(
          children: [
            if (_finished)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('All ships sunk! 🎉', style: Theme.of(context).textTheme.titleMedium),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: size,
                        mainAxisSpacing: 3,
                        crossAxisSpacing: 3,
                      ),
                      itemCount: size * size,
                      itemBuilder: (context, i) {
                        Color color;
                        Widget? icon;
                        if (_revealed[i]) {
                          if (_hit[i]) {
                            color = Colors.redAccent;
                            icon = const Icon(Icons.local_fire_department, size: 16, color: Colors.white);
                          } else {
                            color = Theme.of(context).colorScheme.surfaceContainerLow;
                            icon = const Icon(Icons.close, size: 14, color: Colors.grey);
                          }
                        } else {
                          color = Theme.of(context).colorScheme.primaryContainer;
                        }
                        return GestureDetector(
                          onTap: () => _tap(i),
                          child: Container(
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                            child: Center(child: icon),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ),
          ],
        ),
      ),
    );
  }
}
