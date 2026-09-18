import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamebox/services/local_storage_service.dart';
import 'package:gamebox/services/progression_service.dart';

Future<LocalStorageService> freshStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorageService.instance;
  storage.resetForTesting();
  await storage.init();
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressionService', () {
    test('starts at level 1 with 0 XP and 0 coins', () async {
      final storage = await freshStorage();
      final progression = ProgressionService(storage);

      expect(progression.level, 1);
      expect(progression.xp, 0);
      expect(progression.coins, 0);
      expect(progression.unlockedAchievementIds, isEmpty);
    });

    test('awardForGame grants XP and coins, and unlocks first_play', () async {
      final storage = await freshStorage();
      final progression = ProgressionService(storage);

      final unlocked = await progression.awardForGame(
        gameId: 'snake',
        isNewHighScore: false,
        allPlayedGameIds: {'snake'},
      );

      expect(progression.xp, greaterThan(0));
      expect(progression.coins, greaterThan(0));
      expect(unlocked.map((a) => a.id), contains('first_play'));
      expect(progression.unlockedAchievementIds, contains('first_play'));
    });

    test('a new high score grants a bonus over a normal play', () async {
      final storageA = await freshStorage();
      final normal = ProgressionService(storageA);
      await normal.awardForGame(gameId: 'snake', isNewHighScore: false, allPlayedGameIds: {'snake'});

      final storageB = await freshStorage();
      final highScore = ProgressionService(storageB);
      await highScore.awardForGame(gameId: 'snake', isNewHighScore: true, allPlayedGameIds: {'snake'});

      expect(highScore.xp, greaterThan(normal.xp));
      expect(highScore.coins, greaterThan(normal.coins));
    });

    test('does not re-unlock an already-unlocked achievement', () async {
      final storage = await freshStorage();
      final progression = ProgressionService(storage);

      await progression.awardForGame(gameId: 'snake', isNewHighScore: false, allPlayedGameIds: {'snake'});
      final secondUnlock = await progression.awardForGame(
        gameId: 'snake',
        isNewHighScore: false,
        allPlayedGameIds: {'snake'},
      );

      expect(secondUnlock.map((a) => a.id), isNot(contains('first_play')));
    });

    test('leveling up requires cumulative XP per the 100*N curve', () async {
      final storage = await freshStorage();
      final progression = ProgressionService(storage);

      // Level 1 -> 2 requires 100 XP. Each play grants at least 15 XP,
      // so a handful of plays should push past level 1.
      for (var i = 0; i < 10; i++) {
        await progression.awardForGame(
          gameId: 'snake',
          isNewHighScore: false,
          allPlayedGameIds: {'snake'},
        );
      }

      expect(progression.level, greaterThanOrEqualTo(2));
    });

    test('try_three_games unlocks once 3 distinct games have been played', () async {
      final storage = await freshStorage();
      final progression = ProgressionService(storage);

      await progression.awardForGame(gameId: 'snake', isNewHighScore: false, allPlayedGameIds: {'snake'});
      await progression.awardForGame(gameId: 'tic_tac_toe', isNewHighScore: false, allPlayedGameIds: {'snake', 'tic_tac_toe'});
      final unlocked = await progression.awardForGame(
        gameId: '2048',
        isNewHighScore: false,
        allPlayedGameIds: {'snake', 'tic_tac_toe', '2048'},
      );

      expect(unlocked.map((a) => a.id), contains('try_three_games'));
    });
  });
}
