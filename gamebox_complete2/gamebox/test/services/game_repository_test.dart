import 'package:flutter_test/flutter_test.dart';
import 'package:gamebox/services/game_repository.dart';
import 'package:gamebox/games/game_registry.dart';

void main() {
  group('GameRepository', () {
    late GameRepository repo;

    setUp(() {
      repo = GameRepository();
    });

    test('contains the full 47-game built-in catalog', () {
      expect(repo.getAll().length, 47);
    });

    test('every game id is unique', () {
      final ids = repo.getAll().map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every game has a non-empty name, category and description', () {
      for (final game in repo.getAll()) {
        expect(game.name, isNotEmpty, reason: 'game ${game.id} has no name');
        expect(game.category, isNotEmpty, reason: 'game ${game.id} has no category');
        expect(game.description, isNotEmpty, reason: 'game ${game.id} has no description');
      }
    });

    test('every game has a working GameRegistry entry', () {
      for (final game in repo.getAll()) {
        final widget = GameRegistry.widgetFor(game);
        expect(widget, isNotNull, reason: '${game.id} (engineKey: ${game.engineKey}) has no registered widget');
      }
    });

    test('byId finds a known game and returns null for an unknown one', () {
      expect(repo.byId('snake'), isNotNull);
      expect(repo.byId('does_not_exist'), isNull);
    });

    test('search matches by name case-insensitively', () {
      final results = repo.search('snake');
      expect(results.any((g) => g.id == 'snake'), isTrue);
    });

    test('search matches by category', () {
      final results = repo.search('puzzle');
      expect(results, isNotEmpty);
      expect(results.every((g) => g.category.toLowerCase().contains('puzzle') || g.name.toLowerCase().contains('puzzle')), isTrue);
    });

    test('getCategories returns the expected 4 categories', () {
      expect(repo.getCategories().toSet(), {'Arcade', 'Brain', 'Casual', 'Puzzle'});
    });

    test('getPopular and getNew only return flagged games', () {
      for (final g in repo.getPopular()) {
        expect(g.isPopular, isTrue);
      }
      for (final g in repo.getNew()) {
        expect(g.isNew, isTrue);
      }
    });
  });
}
