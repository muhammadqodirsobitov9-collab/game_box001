import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

/// One unlockable achievement definition.
class Achievement {
  final String id;
  final String title;
  final String description;
  final int coinReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.coinReward = 20,
  });
}

/// Central progression system: XP, levels, coins, and achievements.
///
/// Design notes:
/// - XP required per level grows so early levels come fast and later
///   ones take real play time: level N needs `100 * N` XP.
/// - Coins are a separate currency from XP — earned from play *and*
///   from achievement rewards — so a future in-app "shop" (icons,
///   themes) has something to spend them on without touching this
///   class.
/// - Every built-in and future game funnels through `awardForGame`
///   so no game-specific code needs to know about levels/coins at all.
class ProgressionService extends ChangeNotifier {
  static const _xpKey = 'progression_xp';
  static const _coinsKey = 'progression_coins';
  static const _unlockedKey = 'progression_unlocked_achievements';
  static const _totalPlaysKey = 'progression_total_plays';
  static const _totalWinsKey = 'progression_total_high_scores';

  final LocalStorageService _storage;

  int _xp;
  int _coins;
  int _totalPlays;
  int _totalNewHighScores;
  Set<String> _unlocked;

  ProgressionService(this._storage)
      : _xp = _storage.getInt(_xpKey) ?? 0,
        _coins = _storage.getInt(_coinsKey) ?? 0,
        _totalPlays = _storage.getInt(_totalPlaysKey) ?? 0,
        _totalNewHighScores = _storage.getInt(_totalWinsKey) ?? 0,
        _unlocked = _storage.getStringList(_unlockedKey).toSet();

  // ---- Public read API -------------------------------------------------

  int get xp => _xp;
  int get coins => _coins;
  int get totalPlays => _totalPlays;
  Set<String> get unlockedAchievementIds => Set.unmodifiable(_unlocked);

  /// Level 1 starts at 0 XP. Level N requires cumulative XP of
  /// 100 + 200 + ... for a smoothly increasing curve.
  int get level {
    var remaining = _xp;
    var lvl = 1;
    while (remaining >= _xpForLevel(lvl)) {
      remaining -= _xpForLevel(lvl);
      lvl++;
    }
    return lvl;
  }

  int get xpIntoCurrentLevel {
    var remaining = _xp;
    var lvl = 1;
    while (remaining >= _xpForLevel(lvl)) {
      remaining -= _xpForLevel(lvl);
      lvl++;
    }
    return remaining;
  }

  int get xpNeededForNextLevel => _xpForLevel(level);

  double get levelProgress => xpIntoCurrentLevel / xpNeededForNextLevel;

  int _xpForLevel(int lvl) => 100 * lvl;

  static const List<Achievement> allAchievements = [
    Achievement(
      id: 'first_play',
      title: 'First Steps',
      description: 'Play any game for the first time',
      coinReward: 10,
    ),
    Achievement(
      id: 'ten_plays',
      title: 'Warming Up',
      description: 'Play games 10 times total',
      coinReward: 30,
    ),
    Achievement(
      id: 'fifty_plays',
      title: 'Dedicated Player',
      description: 'Play games 50 times total',
      coinReward: 100,
    ),
    Achievement(
      id: 'first_high_score',
      title: 'Personal Best',
      description: 'Beat your own high score in any game',
      coinReward: 15,
    ),
    Achievement(
      id: 'five_high_scores',
      title: 'On a Roll',
      description: 'Beat your high score 5 times across any games',
      coinReward: 50,
    ),
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach player level 5',
      coinReward: 40,
    ),
    Achievement(
      id: 'level_10',
      title: 'Veteran',
      description: 'Reach player level 10',
      coinReward: 100,
    ),
    Achievement(
      id: 'try_three_games',
      title: 'Explorer',
      description: 'Play 3 different games at least once',
      coinReward: 25,
    ),
  ];

  List<Achievement> get unlockedAchievements =>
      allAchievements.where((a) => _unlocked.contains(a.id)).toList();

  List<Achievement> get lockedAchievements =>
      allAchievements.where((a) => !_unlocked.contains(a.id)).toList();

  // ---- Mutation API ------------------------------------------------------

  /// Call this once per completed play session for ANY game (built-in
  /// or downloaded later). [isNewHighScore] should come straight from
  /// `StatisticsService.reportScore`'s return value.
  ///
  /// Returns the list of achievements newly unlocked by this call, so
  /// the UI can show an unlock toast/dialog right after a game ends.
  Future<List<Achievement>> awardForGame({
    required String gameId,
    required bool isNewHighScore,
    required Set<String> allPlayedGameIds,
  }) async {
    final newlyUnlocked = <Achievement>[];

    _totalPlays++;
    await _storage.setInt(_totalPlaysKey, _totalPlays);

    // Base XP + coins per play, with a bonus for a new high score.
    var xpGain = 15;
    var coinGain = 3;
    if (isNewHighScore) {
      xpGain += 10;
      coinGain += 5;
      _totalNewHighScores++;
      await _storage.setInt(_totalWinsKey, _totalNewHighScores);
    }

    final leveledUpFrom = level;
    _xp += xpGain;
    _coins += coinGain;
    await _storage.setInt(_xpKey, _xp);
    await _storage.setInt(_coinsKey, _coins);

    void tryUnlock(String id, bool condition) {
      if (condition && !_unlocked.contains(id)) {
        final achievement = allAchievements.firstWhere((a) => a.id == id);
        _unlocked.add(id);
        _coins += achievement.coinReward;
        newlyUnlocked.add(achievement);
      }
    }

    tryUnlock('first_play', _totalPlays >= 1);
    tryUnlock('ten_plays', _totalPlays >= 10);
    tryUnlock('fifty_plays', _totalPlays >= 50);
    tryUnlock('first_high_score', _totalNewHighScores >= 1);
    tryUnlock('five_high_scores', _totalNewHighScores >= 5);
    tryUnlock('try_three_games', allPlayedGameIds.length >= 3);
    tryUnlock('level_5', level >= 5);
    tryUnlock('level_10', level >= 10);

    if (newlyUnlocked.isNotEmpty) {
      await _storage.setStringList(_unlockedKey, _unlocked.toList());
      await _storage.setInt(_coinsKey, _coins);
    }

    if (level != leveledUpFrom || newlyUnlocked.isNotEmpty || xpGain > 0) {
      notifyListeners();
    }

    return newlyUnlocked;
  }
}
