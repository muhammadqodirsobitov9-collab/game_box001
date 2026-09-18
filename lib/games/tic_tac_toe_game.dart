import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';

/// Local 2-player Tic-Tac-Toe. "High score" for this game is tracked
/// as total wins across both players in a single session, so it
/// still plugs into the shared StatisticsService like every other
/// built-in game.
class TicTacToeGame extends StatefulWidget {
  final GameModel game;
  const TicTacToeGame({super.key, required this.game});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> _board = List.filled(9, '');
  String _turn = 'X';
  String? _winner;
  bool _draw = false;
  int _wins = 0;

  static const _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  void _tap(int i) {
    if (_board[i].isNotEmpty || _winner != null || _draw) return;
    setState(() {
      _board[i] = _turn;
      final winner = _checkWinner();
      if (winner != null) {
        _winner = winner;
        _wins++;
        GameResultHandler.report(context, gameId: widget.game.id, score: _wins);
      } else if (!_board.contains('')) {
        _draw = true;
      } else {
        _turn = _turn == 'X' ? 'O' : 'X';
      }
    });
  }

  String? _checkWinner() {
    for (final line in _lines) {
      final a = _board[line[0]], b = _board[line[1]], c = _board[line[2]];
      if (a.isNotEmpty && a == b && b == c) return a;
    }
    return null;
  }

  void _reset() {
    setState(() {
      _board = List.filled(9, '');
      _turn = 'X';
      _winner = null;
      _draw = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    String status;
    if (_winner != null) {
      status = '$_winner wins!';
    } else if (_draw) {
      status = "It's a draw";
    } else {
      status = 'Turn: $_turn';
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                height: 300,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _tap(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _board[i],
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _board[i] == 'X'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_winner != null || _draw)
                FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      ),
    );
  }
}
