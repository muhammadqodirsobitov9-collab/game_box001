import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_result_handler.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';

/// Simplified Blackjack against a dealer that hits to 17. No real
/// betting — just hand outcomes. Score = hands won this session.
class BlackjackGame extends StatefulWidget {
  final GameModel game;
  const BlackjackGame({super.key, required this.game});

  @override
  State<BlackjackGame> createState() => _BlackjackGameState();
}

class _BlackjackGameState extends State<BlackjackGame> {
  static const _ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

  List<String> _playerHand = [];
  List<String> _dealerHand = [];
  bool _playerTurn = true;
  bool _roundOver = false;
  String _result = '';
  int _wins = 0;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _deal();
  }

  String _draw() => _ranks[_rand.nextInt(_ranks.length)];

  int _handValue(List<String> hand) {
    var total = 0;
    var aces = 0;
    for (final card in hand) {
      if (card == 'A') {
        aces++;
        total += 11;
      } else if (['J', 'Q', 'K'].contains(card)) {
        total += 10;
      } else {
        total += int.parse(card);
      }
    }
    while (total > 21 && aces > 0) {
      total -= 10;
      aces--;
    }
    return total;
  }

  void _deal() {
    setState(() {
      _playerHand = [_draw(), _draw()];
      _dealerHand = [_draw(), _draw()];
      _playerTurn = true;
      _roundOver = false;
      _result = '';
    });
    if (_handValue(_playerHand) == 21) _stand();
  }

  void _hit() {
    if (!_playerTurn || _roundOver) return;
    setState(() => _playerHand.add(_draw()));
    if (_handValue(_playerHand) > 21) {
      _finishRound('Bust! You lose.', false);
    }
  }

  void _stand() async {
    if (_roundOver) return;
    setState(() => _playerTurn = false);
    while (_handValue(_dealerHand) < 17) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _dealerHand.add(_draw()));
    }
    final playerVal = _handValue(_playerHand);
    final dealerVal = _handValue(_dealerHand);
    if (dealerVal > 21 || playerVal > dealerVal) {
      _finishRound('You win! 🎉', true);
    } else if (playerVal == dealerVal) {
      _finishRound("Push (tie).", false, isPush: true);
    } else {
      _finishRound('Dealer wins.', false);
    }
  }

  void _finishRound(String message, bool won, {bool isPush = false}) async {
    setState(() {
      _roundOver = true;
      _result = message;
      if (won) _wins++;
    });
    await GameResultHandler.report(context, gameId: widget.game.id, score: _wins);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppStrings>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.name} · Wins: $_wins')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Dealer: ${_roundOver ? _dealerHand.join(' ') : '${_dealerHand.first} ?'}', style: const TextStyle(fontSize: 18)),
              if (_roundOver) Text('(${_handValue(_dealerHand)})'),
              const SizedBox(height: 24),
              Text('You: ${_playerHand.join(' ')} (${_handValue(_playerHand)})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (_roundOver) ...[
                Text(_result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _deal, child: const Text('Next hand')),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(onPressed: _hit, child: const Text('Hit')),
                    const SizedBox(width: 16),
                    FilledButton(onPressed: _stand, child: const Text('Stand')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
