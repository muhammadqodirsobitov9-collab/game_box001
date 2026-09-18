import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

/// Tracks per-game statistics (high score, times played) fully offline.
/// This is deliberately small in Part 1 — the full XP / coins / level
/// system is built on top of this in a later stage without needing to
/// change this class's storage format.
class StatisticsService extends ChangeNotifier {
  static const _highScorePrefix = 'high_score_';
  static const _playsPrefix = 'plays_';
  static const _playedGameIdsKey = 'played_game_ids';

  final LocalStorageService _storage;

  StatisticsService(this._storage);

  int highScoreFor(String gameId) => _storage.getInt('$_highScorePrefix$gameId') ?? 0;

  int playsFor(String gameId) => _storage.getInt('$_playsPrefix$gameId') ?? 0;

  Set<String> get playedGameIds => _storage.getStringList(_playedGameIdsKey).toSet();

  Future<bool> reportScore(String gameId, int score) async {
    final current = highScoreFor(gameId);
    final isNewHighScore = score > current;
    if (isNewHighScore) {
      await _storage.setInt('$_highScorePrefix$gameId', score);
    }
    await _storage.setInt('$_playsPrefix$gameId', playsFor(gameId) + 1);

    final played = playedGameIds;
    if (!played.contains(gameId)) {
      played.add(gameId);
      await _storage.setStringList(_playedGameIdsKey, played.toList());
    }

    notifyListeners();
    return isNewHighScore;
  }

  int get totalGamesPlayed {
    // Summed lazily; fine at this catalog size, revisit if the
    // catalog grows into the hundreds mentioned in the spec.
    return 0; // populated by GameRepository.totalPlays() in the UI layer
  }
}
