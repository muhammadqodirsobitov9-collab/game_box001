import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Classic Tower of Hanoi with 5 disks. Tap a peg to pick up its top
/// disk, tap another peg to drop it (only onto a larger disk or an
/// empty peg). Win by moving the whole stack to the last peg. Score =
/// 200 if solved in the optimal 31 moves, decreasing for more moves,
/// floored at 20.
class TowerOfHanoiGame extends StatefulWidget {
  final GameModel game;
  const TowerOfHanoiGame({super.key, required this.game});

  @override
  State<TowerOfHanoiGame> createState() => _TowerOfHanoiGameState();
}

class _TowerOfHanoiGameState extends State<TowerOfHanoiGame> {
  static const diskCount = 5;
  late List<List<int>> _pegs;
  int? _selectedPeg;
  int _moves = 0;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _pegs = [
      List.generate(diskCount, (i) => diskCount - i),
      [],
      [],
    ];
    _selectedPeg = null;
    _moves = 0;
    _solved = false;
    setState(() {});
  }

  void _tapPeg(int i) async {
    if (_solved) return;
    if (_selectedPeg == null) {
      if (_pegs[i].isNotEmpty) setState(() => _selectedPeg = i);
      return;
    }
    if (_selectedPeg == i) {
      setState(() => _selectedPeg = null);
      return;
    }
    final from = _selectedPeg!;
    final disk = _pegs[from].last;
    final target = _pegs[i];
    if (target.isEmpty || target.last > disk) {
      setState(() {
        _pegs[from].removeLast();
        target.add(disk);
        _moves++;
        _selectedPeg = null;
      });
      if (_pegs[2].length == diskCount) {
        setState(() => _solved = true);
        final optimal = (1 << diskCount) - 1;
        final score = (200 - (_moves - optimal) * 5).clamp(20, 200);
        await GameResultHandler.report(context, gameId: widget.game.id, score: score);
      }
    } else {
      setState(() => _selectedPeg = i);
    }
  }

  Color _diskColor(int size) {
    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.green, Colors.blue, Colors.purple];
    return colors[(size - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    final optimal = (1 << diskCount) - 1;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Moves: $_moves (optimal: $optimal)')),
      body: SafeArea(
        child: Column(
          children: [
            if (_solved)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Solved! 🎉', style: Theme.of(context).textTheme.titleMedium),
              ),
            Expanded(
              child: Row(
                children: List.generate(3, (i) {
                  final peg = _pegs[i];
                  final isSelected = _selectedPeg == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _tapPeg(i),
                      child: Container(
                        color: isSelected ? Colors.amber.withValues(alpha: 0.1) : Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            for (final disk in peg.reversed)
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                width: 30.0 + disk * 22,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _diskColor(disk),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            Container(height: 6, color: Colors.brown),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
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
