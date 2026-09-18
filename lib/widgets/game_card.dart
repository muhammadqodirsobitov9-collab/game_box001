import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../services/favorites_service.dart';
import '../l10n/app_strings.dart';

/// A single game tile used across Home, Games, Search and Favorites.
/// Enlarges slightly on press per the "cards animate/enlarge when
/// touched" requirement from the spec.
class GameCard extends StatefulWidget {
  final GameModel game;
  final VoidCallback onTap;

  const GameCard({super.key, required this.game, required this.onTap});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = context.watch<FavoritesService>();
    final strings = context.watch<AppStrings>();
    final isFav = favorites.isFavorite(widget.game.id);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.85),
                          theme.colorScheme.tertiary.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            _iconFor(widget.game.engineKey),
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.game.isNew || widget.game.isPopular)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: _Badge(
                              label: widget.game.isNew ? 'NEW' : 'HOT',
                            ),
                          ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                            ),
                            onPressed: () => favorites.toggle(widget.game.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.game.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber[600]),
                    const SizedBox(width: 2),
                    Text(widget.game.rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Text(widget.game.sizeLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: widget.onTap,
                    child: Text(strings.t('play')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String engineKey) {
    switch (engineKey) {
      case 'snake':
        return Icons.grain;
      case 'tic_tac_toe':
        return Icons.grid_3x3;
      case 'runner':
        return Icons.directions_run;
      case 'memory':
        return Icons.grid_view;
      case 'puzzle_2048':
        return Icons.apps;
      case 'whack_a_mole':
        return Icons.pest_control_rodent;
      case 'reaction_time':
        return Icons.bolt;
      case 'simon_says':
        return Icons.palette;
      case 'rock_paper_scissors':
        return Icons.front_hand;
      case 'number_guess':
        return Icons.pin;
      case 'minesweeper':
        return Icons.dangerous;
      case 'connect_four':
        return Icons.circle;
      case 'sliding_puzzle':
        return Icons.extension;
      case 'word_scramble':
        return Icons.abc;
      case 'higher_lower':
        return Icons.style;
      case 'brick_breaker':
        return Icons.view_module;
      case 'dice_duel':
        return Icons.casino;
      case 'fruit_slice':
        return Icons.eco;
      case 'flappy_block':
        return Icons.flight;
      case 'pong':
        return Icons.sports_tennis;
      case 'hangman':
        return Icons.text_fields;
      case 'speed_math':
        return Icons.calculate;
      case 'quiz_trivia':
        return Icons.quiz;
      case 'battleship':
        return Icons.directions_boat;
      case 'maze_escape':
        return Icons.route;
      case 'color_match':
        return Icons.color_lens;
      case 'tetris_lite':
        return Icons.view_agenda;
      case 'sokoban_mini':
        return Icons.move_down;
      case 'sudoku_classic':
        return Icons.grid_on;
      case 'target_shooter':
        return Icons.gps_fixed;
      case 'tug_of_war':
        return Icons.fitness_center;
      case 'coin_flip_streak':
        return Icons.monetization_on;
      case 'anagram_hunter':
        return Icons.spellcheck;
      case 'odd_one_out':
        return Icons.visibility;
      case 'bubble_pop_match':
        return Icons.bubble_chart;
      case 'balloon_inflate':
        return Icons.circle_outlined;
      case 'air_hockey':
        return Icons.sports_hockey;
      case 'reflex_sequence':
        return Icons.filter_9_plus;
      case 'wordle':
        return Icons.text_format;
      case 'alien_shooter':
        return Icons.rocket_launch;
      case 'checkers':
        return Icons.grid_4x4;
      case 'tower_of_hanoi':
        return Icons.filter_none;
      case 'peg_solitaire':
        return Icons.scatter_plot;
      case 'blackjack':
        return Icons.style;
      case 'basketball_shootout':
        return Icons.sports_basketball;
      case 'rhythm_tap':
        return Icons.music_note;
      case 'darts':
        return Icons.track_changes;
      case 'mini_sudoku':
        return Icons.window;
      case 'match_three':
        return Icons.diamond;
      case 'typing_speed':
        return Icons.keyboard;
      default:
        return Icons.sports_esports;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
