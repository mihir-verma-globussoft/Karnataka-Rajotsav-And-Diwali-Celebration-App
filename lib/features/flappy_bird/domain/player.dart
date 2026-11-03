class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.username,
    required this.createdAt,
    this.email,
    this.avatarUrl,
    this.characterAvatarUrl,
  });

  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? characterAvatarUrl;
  final DateTime createdAt;

  String? get displayAvatarUrl => characterAvatarUrl ?? avatarUrl;

  bool get hasCharacterAvatar => characterAvatarUrl?.isNotEmpty ?? false;
}

class PlayerStats {
  const PlayerStats({
    required this.highScore,
    required this.totalGames,
    required this.totalScore,
    this.globalRank,
  });

  static const zero = PlayerStats(highScore: 0, totalGames: 0, totalScore: 0);

  final int highScore;
  final int totalGames;
  final int totalScore;
  final int? globalRank;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.highScore,
    this.avatarUrl,
  });

  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int highScore;
}

class DashboardData {
  const DashboardData({required this.profile, required this.stats});

  final PlayerProfile profile;
  final PlayerStats stats;
}
