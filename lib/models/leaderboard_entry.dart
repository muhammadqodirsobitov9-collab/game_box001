/// A single row in a game's leaderboard.
class LeaderboardEntry {
  final String playerName;
  final int score;
  final bool isYou;

  const LeaderboardEntry({
    required this.playerName,
    required this.score,
    this.isYou = false,
  });
}
