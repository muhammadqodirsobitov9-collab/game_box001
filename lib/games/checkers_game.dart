import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

enum _Piece { empty, redMan, redKing, blackMan, blackKing }

class _Pt {
  final int x, y;
  const _Pt(this.x, this.y);
}

/// Simplified local 2-player Checkers (Draughts) on 8x8. Captures are
/// optional (not forced) and only single-step jumps are supported —
/// no multi-jump chains — to keep the rules approachable. Kings move
/// and capture in all 4 diagonal directions. Score = pieces captured
/// by the winner.
class CheckersGame extends StatefulWidget {
  final GameModel game;
  const CheckersGame({super.key, required this.game});

  @override
  State<CheckersGame> createState() => _CheckersGameState();
}

class _CheckersGameState extends State<CheckersGame> {
  late List<List<_Piece>> _board;
  bool _redTurn = true;
  _Pt? _selected;
  int _redCaptured = 0;
  int _blackCaptured = 0;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(8, (_) => List.filled(8, _Piece.empty));
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) _board[r][c] = _Piece.blackMan;
      }
    }
    for (var r = 5; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) _board[r][c] = _Piece.redMan;
      }
    }
    _redTurn = true;
    _selected = null;
    _redCaptured = 0;
    _blackCaptured = 0;
    _winner = null;
    setState(() {});
  }

  bool _isRed(_Piece p) => p == _Piece.redMan || p == _Piece.redKing;
  bool _isBlack(_Piece p) => p == _Piece.blackMan || p == _Piece.blackKing;
  bool _isKing(_Piece p) => p == _Piece.redKing || p == _Piece.blackKing;

  void _tap(int r, int c) async {
    if (_winner != null) return;
    final piece = _board[r][c];
    final isOwn = _redTurn ? _isRed(piece) : _isBlack(piece);

    if (_selected == null) {
      if (isOwn) setState(() => _selected = _Pt(r, c));
      return;
    }

    if (isOwn) {
      setState(() => _selected = _Pt(r, c));
      return;
    }

    final sr = _selected!.x, sc = _selected!.y;
    final moving = _board[sr][sc];
    final dr = r - sr, dc = c - sc;

    if (piece != _Piece.empty || dc.abs() != dr.abs() || dr == 0) {
      setState(() => _selected = null);
      return;
    }

    if (dr.abs() == 1) {
      final forwardOk = _isKing(moving) || (_isRed(moving) ? dr == -1 : dr == 1);
      if (forwardOk) {
        setState(() {
          _board[r][c] = moving;
          _board[sr][sc] = _Piece.empty;
          _maybePromote(r, c);
          _selected = null;
          _redTurn = !_redTurn;
        });
        _checkWin();
      } else {
        setState(() => _selected = null);
      }
    } else if (dr.abs() == 2) {
      final midR = (sr + r) ~/ 2, midC = (sc + c) ~/ 2;
      final midPiece = _board[midR][midC];
      final directionOk = _isKing(moving) || (_isRed(moving) ? dr == -2 : dr == 2);
      final canCapture = directionOk && (_redTurn ? _isBlack(midPiece) : _isRed(midPiece));
      if (canCapture) {
        setState(() {
          _board[r][c] = moving;
          _board[sr][sc] = _Piece.empty;
          _board[midR][midC] = _Piece.empty;
          if (_redTurn) {
            _redCaptured++;
          } else {
            _blackCaptured++;
          }
          _maybePromote(r, c);
          _selected = null;
          _redTurn = !_redTurn;
        });
        _checkWin();
      } else {
        setState(() => _selected = null);
      }
    } else {
      setState(() => _selected = null);
    }
  }

  void _maybePromote(int r, int c) {
    if (_board[r][c] == _Piece.redMan && r == 0) _board[r][c] = _Piece.redKing;
    if (_board[r][c] == _Piece.blackMan && r == 7) _board[r][c] = _Piece.blackKing;
  }

  void _checkWin() async {
    final hasRed = _board.expand((row) => row).any(_isRed);
    final hasBlack = _board.expand((row) => row).any(_isBlack);
    if (!hasRed || !hasBlack) {
      final winner = hasRed ? 'Red' : 'Black';
      setState(() => _winner = winner);
      final score = hasRed ? _redCaptured : _blackCaptured;
      await GameResultHandler.report(context, gameId: widget.game.id, score: score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · ${_redTurn ? 'Red' : 'Black'} to move')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_winner != null) Text('$_winner wins! 🎉', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Captured — Red: $_redCaptured  Black: $_blackCaptured'),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                    itemCount: 64,
                    itemBuilder: (context, i) {
                      final r = i ~/ 8, c = i % 8;
                      final dark = (r + c) % 2 == 1;
                      final piece = _board[r][c];
                      final isSelected = _selected?.x == r && _selected?.y == c;
                      return GestureDetector(
                        onTap: () => _tap(r, c),
                        child: Container(
                          color: isSelected
                              ? Colors.yellow[200]
                              : (dark ? Colors.brown[700] : Colors.brown[200]),
                          child: piece == _Piece.empty
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isRed(piece) ? Colors.red : Colors.black,
                                      border: Border.all(color: Colors.white24, width: 2),
                                    ),
                                    child: _isKing(piece)
                                        ? const Icon(Icons.star, color: Colors.amber, size: 14)
                                        : null,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_winner != null) FilledButton(onPressed: _reset, child: Text(strings.t('restart'))),
            ],
          ),
        ),
      ),
    );
  }
}
