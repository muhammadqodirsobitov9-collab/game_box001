import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';

/// Local 2-player Connect Four on a 7x6 board. Score = total games
/// won this session (tracked like Tic-Tac-Toe).
class ConnectFourGame extends StatefulWidget {
  final GameModel game;
  const ConnectFourGame({super.key, required this.game});

  @override
  State<ConnectFourGame> createState() => _ConnectFourGameState();
}

class _ConnectFourGameState extends State<ConnectFourGame> {
  static const cols = 7;
  static const rows = 6;

  late List<List<String>> _board; // '' | 'R' | 'Y'
  String _turn = 'R';
  String? _winner;
  bool _draw = false;
  int _wins = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(rows, (_) => List.filled(cols, ''));
    _turn = 'R';
    _winner = null;
    _draw = false;
    setState(() {});
  }

  void _drop(int col) async {
    if (_winner != null || _draw) return;
    int? targetRow;
    for (var r = rows - 1; r >= 0; r--) {
      if (_board[r][col].isEmpty) {
        targetRow = r;
        break;
      }
    }
    if (targetRow == null) return;

    setState(() {
      _board[targetRow!][col] = _turn;
      if (_checkWin(targetRow!, col)) {
        _winner = _turn;
        _wins++;
      } else if (_board.every((row) => row.every((c) => c.isNotEmpty))) {
        _draw = true;
      } else {
        _turn = _turn == 'R' ? 'Y' : 'R';
      }
    });

    if (_winner != null) {
      await GameResultHandler.report(context, gameId: widget.game.id, score: _wins);
    }
  }

  bool _checkWin(int r, int c) {
    final player = _board[r][c];
    const dirs = [
      [0, 1], [1, 0], [1, 1], [1, -1],
    ];
    for (final d in dirs) {
      var count = 1;
      count += _count(r, c, d[0], d[1], player);
      count += _count(r, c, -d[0], -d[1], player);
      if (count >= 4) return true;
    }
    return false;
  }

  int _count(int r, int c, int dr, int dc, String player) {
    var count = 0;
    var rr = r + dr, cc = c + dc;
    while (rr >= 0 && rr < rows && cc >= 0 && cc < cols && _board[rr][cc] == player) {
      count++;
      rr += dr;
      cc += dc;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    String status;
    if (_winner != null) {
      status = '${_winner == 'R' ? 'Red' : 'Yellow'} wins!';
    } else if (_draw) {
      status = "It's a draw";
    } else {
      status = 'Turn: ${_turn == 'R' ? 'Red' : 'Yellow'}';
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: cols / rows,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: List.generate(cols, (col) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _drop(col),
                          child: Column(
                            children: List.generate(rows, (row) {
                              final v = _board[row][col];
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                    shape: BoxShape.circle,
                                  ),
                                  child: v.isEmpty
                                      ? null
                                      : Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: v == 'R' ? Colors.redAccent : Colors.amber,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_winner != null || _draw)
                FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      ),
    );
  }
}
