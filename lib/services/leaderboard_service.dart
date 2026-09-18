import 'dart:math';
import '../models/leaderboard_entry.dart';
import 'local_storage_service.dart';
import 'statistics_service.dart';

/// Per-game leaderboards, ranking the player against other entries.
///
/// ## Important honesty note
/// A *real* global leaderboard needs a server: something that stores
/// every player's scores and serves them back to everyone else. This
/// app has no backend (it's offline-first by design — see the
/// Download Manager for the same pattern), so there is no way to show
/// genuine other-player data here.
///
/// What this class does instead — and what it's honest about — is
/// generate a deterministic set of **simulated** opponent scores per
/// game (seeded from the game's id, so the same game always shows the
/// same simulated field rather than reshuffling every time), and rank
/// the player's real local high score against them. The UI labels
/// these clearly as a demo/practice leaderboard.
///
/// Swapping in a real backend later (Firebase, Supabase, a custom
/// API) only means replacing `_simulatedEntriesFor()` with an actual
/// network call — `LeaderboardService`'s public API (`getLeaderboard`,
/// `playerName`) doesn't need to change, and neither does any screen
/// that uses it.
class LeaderboardService {
  static const _nameKey = 'leaderboard_player_name';
  static const _namePool = [
    'Nova', 'Comet', 'Blaze', 'Echo', 'Jinx', 'Rook', 'Vex', 'Zephyr',
    'Onyx', 'Sable', 'Quill', 'Frost', 'Halo', 'Raven', 'Storm', 'Lynx',
  ];

  final LocalStorageService _storage;
  LeaderboardService(this._storage);

  String get playerName => _storage.getString(_nameKey) ?? 'You';

  Future<void> setPlayerName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _storage.setString(_nameKey, trimmed);
  }

  /// Adopts [googleName] as the leaderboard display name, but only if
  /// the player has never set one manually — signing in shouldn't
  /// silently overwrite a name someone already chose for themselves.
  Future<void> adoptGoogleNameIfUnset(String? googleName) async {
    if (googleName == null || googleName.trim().isEmpty) return;
    if (_storage.getString(_nameKey) != null) return;
    await _storage.setString(_nameKey, googleName.trim());
  }

  /// Generates a stable list of simulated opponent scores for
  /// [gameId], seeded by the id so it's the same every time rather
  /// than random noise on every screen open.
  List<int> _simulatedScoresFor(String gameId, int playerScore) {
    final seed = gameId.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
    final rand = Random(seed);
    // Spread simulated scores around a plausible range relative to
    // the player's own score, so the board feels populated whether
    // the player has played once or a hundred times.
    final baseline = max(playerScore, 50);
    return List.generate(9, (_) {
      final factor = 0.4 + rand.nextDouble() * 1.3; // 0.4x - 1.7x baseline
      return (baseline * factor).round();
    });
  }

  /// Returns the top entries for [gameId], the player's own real high
  /// score included and correctly ranked among the simulated field.
  List<LeaderboardEntry> getLeaderboard(String gameId, StatisticsService stats) {
    final playerScore = stats.highScoreFor(gameId);
    final simulated = _simulatedScoresFor(gameId, playerScore);
    final rand = Random(gameId.codeUnits.fold<int>(0, (a, b) => a * 31 + b));
    final names = List.of(_namePool)..shuffle(rand);

    final entries = <LeaderboardEntry>[
      LeaderboardEntry(playerName: playerName, score: playerScore, isYou: true),
      for (var i = 0; i < simulated.length; i++)
        LeaderboardEntry(playerName: names[i % names.length], score: simulated[i]),
    ];
    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries;
  }
}
