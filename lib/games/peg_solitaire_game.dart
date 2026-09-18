import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Classic cross-shaped Peg Solitaire. Jump a peg over an adjacent
/// peg into an empty hole to remove the jumped peg. Game ends when no
/// more jumps are possible. Score = 400 - remaining pegs*10 (winning
/// with just 1 peg left scores the most).
class PegSolitaireGame extends StatefulWidget {
  final GameModel game;
  const PegSolitaireGame({super.key, required this.game});

  @override
  State<PegSolitaireGame> createState() => _PegSolitaireGameState();
}

// -1 = invalid cell, 0 = empty hole, 1 = peg
class _PegSolitaireGameState extends State<PegSolitaireGame> {
  static const size = 7;
  late List<List<int>> _board;
  int? _selR, _selC;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(size, (r) => List.generate(size, (c) {
          final inCross = (r >= 2 && r <= 4) || (c >= 2 && c <= 4);
          if (!inCross) return -1;
          return (r == 3 && c == 3) ? 0 : 1;
        }));
    _selR = null;
    _selC = null;
    _finished = false;
    setState(() {});
  }

  int get _pegCount => _board.expand((r) => r).where((v) => v == 1).length;

  bool _canJump(int r, int c, int nr, int nc) {
    if (nr < 0 || nr >= size || nc < 0 || nc >= size) return false;
    if (_board[nr][nc] != 0) return false;
    final midR = (r + nr) ~/ 2, midC = (c + nc) ~/ 2;
    return _board[midR][midC] == 1;
  }

  void _tap(int r, int c) async {
    if (_finished || _board[r][c] == -1) return;
    if (_board[r][c] == 1) {
      setState(() {
        _selR = r;
        _selC = c;
      });
      return;
    }
    if (_selR == null) return;
    final dr = r - _selR!, dc = c - _selC!;
    if ((dr.abs() == 2 && dc == 0) || (dc.abs() == 2 && dr == 0)) {
      if (_canJump(_selR!, _selC!, r, c)) {
        final midR = (_selR! + r) ~/ 2, midC = (_selC! + c) ~/ 2;
        setState(() {
          _board[_selR!][_selC!] = 0;
          _board[midR][midC] = 0;
          _board[r][c] = 1;
          _selR = null;
          _selC = null;
        });
        if (!_anyMovesLeft()) {
          setState(() => _finished = true);
          final score = (400 - _pegCount * 10).clamp(0, 400);
          await GameResultHandler.report(context, gameId: widget.game.id, score: score);
        }
      }
    }
  }

  bool _anyMovesLeft() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_board[r][c] != 1) continue;
        if (_canJump(r, c, r - 2, c) || _canJump(r, c, r + 2, c) ||
            _canJump(r, c, r, c - 2) || _canJump(r, c, r, c + 2)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Pegs left: $_pegCount')),
      body: SafeArea(
        child: Column(
          children: [
            if (_finished)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _pegCount == 1 ? 'Perfect solve! 🎉' : 'No more moves — $_pegCount pegs left',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size),
                      itemCount: size * size,
                      itemBuilder: (context, i) {
                        final r = i ~/ size, c = i % size;
                        final v = _board[r][c];
                        if (v == -1) return const SizedBox.shrink();
                        final isSelected = _selR == r && _selC == c;
                        return GestureDetector(
                          onTap: () => _tap(r, c),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.amber, width: 2) : null,
                            ),
                            child: v == 1
                                ? Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Container(
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                                    ),
                                  )
                                : null,
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
