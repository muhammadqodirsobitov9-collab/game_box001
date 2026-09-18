import 'package:flutter/widgets.dart';
import '../models/game_model.dart';
import 'snake_game.dart';
import 'tic_tac_toe_game.dart';
import 'runner_game.dart';
import 'memory_game.dart';
import 'puzzle_2048_game.dart';
import 'whack_a_mole_game.dart';
import 'reaction_time_game.dart';
import 'simon_says_game.dart';
import 'rock_paper_scissors_game.dart';
import 'number_guess_game.dart';
import 'minesweeper_game.dart';
import 'connect_four_game.dart';
import 'sliding_puzzle_game.dart';
import 'word_scramble_game.dart';
import 'higher_lower_game.dart';
import 'brick_breaker_game.dart';
import 'mini_sudoku_game.dart';
import 'match_three_game.dart';
import 'typing_speed_game.dart';
import 'dice_duel_game.dart';
import 'fruit_slice_game.dart';
import 'flappy_block_game.dart';
import 'pong_game.dart';
import 'hangman_game.dart';
import 'speed_math_game.dart';
import 'quiz_trivia_game.dart';
import 'battleship_game.dart';
import 'maze_escape_game.dart';
import 'color_match_game.dart';
import 'tetris_lite_game.dart';
import 'sokoban_mini_game.dart';
import 'sudoku_classic_game.dart';
import 'target_shooter_game.dart';
import 'tug_of_war_game.dart';
import 'coin_flip_streak_game.dart';
import 'anagram_hunter_game.dart';
import 'odd_one_out_game.dart';
import 'bubble_pop_match_game.dart';
import 'balloon_inflate_game.dart';
import 'air_hockey_game.dart';
import 'reflex_sequence_game.dart';
import 'wordle_game.dart';
import 'alien_shooter_game.dart';
import 'checkers_game.dart';
import 'tower_of_hanoi_game.dart';
import 'peg_solitaire_game.dart';
import 'blackjack_game.dart';
import 'basketball_shootout_game.dart';
import 'rhythm_tap_game.dart';
import 'darts_game.dart';

/// Maps a [GameModel.engineKey] to its actual playable screen.
///
/// Adding a new built-in game only means adding one case here plus a
/// new file under lib/games/ — nothing else in the app needs to
/// change, which mirrors the "scalable catalog" requirement even
/// before the downloadable-package system exists.
class GameRegistry {
  static Widget? widgetFor(GameModel game) {
    switch (game.engineKey) {
      case 'snake':
        return SnakeGame(game: game);
      case 'tic_tac_toe':
        return TicTacToeGame(game: game);
      case 'runner':
        return RunnerGame(game: game);
      case 'memory':
        return MemoryGame(game: game);
      case 'puzzle_2048':
        return Puzzle2048Game(game: game);
      case 'whack_a_mole':
        return WhackAMoleGame(game: game);
      case 'reaction_time':
        return ReactionTimeGame(game: game);
      case 'simon_says':
        return SimonSaysGame(game: game);
      case 'rock_paper_scissors':
        return RockPaperScissorsGame(game: game);
      case 'number_guess':
        return NumberGuessGame(game: game);
      case 'minesweeper':
        return MinesweeperGame(game: game);
      case 'connect_four':
        return ConnectFourGame(game: game);
      case 'sliding_puzzle':
        return SlidingPuzzleGame(game: game);
      case 'word_scramble':
        return WordScrambleGame(game: game);
      case 'higher_lower':
        return HigherLowerGame(game: game);
      case 'brick_breaker':
        return BrickBreakerGame(game: game);
      case 'mini_sudoku':
        return MiniSudokuGame(game: game);
      case 'match_three':
        return MatchThreeGame(game: game);
      case 'typing_speed':
        return TypingSpeedGame(game: game);
      case 'dice_duel':
        return DiceDuelGame(game: game);
      case 'fruit_slice':
        return FruitSliceGame(game: game);
      case 'flappy_block':
        return FlappyBlockGame(game: game);
      case 'pong':
        return PongGame(game: game);
      case 'hangman':
        return HangmanGame(game: game);
      case 'speed_math':
        return SpeedMathGame(game: game);
      case 'quiz_trivia':
        return QuizTriviaGame(game: game);
      case 'battleship':
        return BattleshipGame(game: game);
      case 'maze_escape':
        return MazeEscapeGame(game: game);
      case 'color_match':
        return ColorMatchGame(game: game);
      case 'tetris_lite':
        return TetrisLiteGame(game: game);
      case 'sokoban_mini':
        return SokobanMiniGame(game: game);
      case 'sudoku_classic':
        return SudokuClassicGame(game: game);
      case 'target_shooter':
        return TargetShooterGame(game: game);
      case 'tug_of_war':
        return TugOfWarGame(game: game);
      case 'coin_flip_streak':
        return CoinFlipStreakGame(game: game);
      case 'anagram_hunter':
        return AnagramHunterGame(game: game);
      case 'odd_one_out':
        return OddOneOutGame(game: game);
      case 'bubble_pop_match':
        return BubblePopMatchGame(game: game);
      case 'balloon_inflate':
        return BalloonInflateGame(game: game);
      case 'air_hockey':
        return AirHockeyGame(game: game);
      case 'reflex_sequence':
        return ReflexSequenceGame(game: game);
      case 'wordle':
        return WordleGame(game: game);
      case 'alien_shooter':
        return AlienShooterGame(game: game);
      case 'checkers':
        return CheckersGame(game: game);
      case 'tower_of_hanoi':
        return TowerOfHanoiGame(game: game);
      case 'peg_solitaire':
        return PegSolitaireGame(game: game);
      case 'blackjack':
        return BlackjackGame(game: game);
      case 'basketball_shootout':
        return BasketballShootoutGame(game: game);
      case 'rhythm_tap':
        return RhythmTapGame(game: game);
      case 'darts':
        return DartsGame(game: game);
      default:
        return null;
    }
  }
}
