import 'package:json_annotation/json_annotation.dart';

// part 'game_score.g.dart'; // We won't generate this yet, but we'll prep for it or use manual serialization for simplicity

// @JsonSerializable()
class GameScore {
  final int gameStarted;
  final int gameWon;
  final int bestTime; // in seconds
  final int averageTime;
  final int bestScore;
  final int averageScore;
  final String levelKey;
  final int winStreak;
  final int bestWinStreak;

  GameScore({
    required this.gameStarted,
    required this.gameWon,
    required this.averageScore,
    required this.averageTime,
    required this.bestScore,
    required this.bestTime,
    required this.bestWinStreak,
    required this.levelKey,
    required this.winStreak,
  });

  factory GameScore.initial(String levelKey) {
    return GameScore(
      gameStarted: 0,
      gameWon: 0,
      averageScore: 0,
      averageTime: 0,
      bestScore: 0,
      bestTime: 0,
      bestWinStreak: 0,
      levelKey: levelKey,
      winStreak: 0,
    );
  }

  // Manual serialization to avoid needing build_runner immediately
  Map<String, dynamic> toJson() => {
    'gameStarted': gameStarted,
    'gameWon': gameWon,
    'averageScore': averageScore,
    'averageTime': averageTime,
    'bestScore': bestScore,
    'bestTime': bestTime,
    'bestWinStreak': bestWinStreak,
    'levelKey': levelKey,
    'winStreak': winStreak,
  };

  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      gameStarted: json['gameStarted'] as int? ?? 0,
      gameWon: json['gameWon'] as int? ?? 0,
      averageScore: json['averageScore'] as int? ?? 0,
      averageTime: json['averageTime'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      bestTime: json['bestTime'] as int? ?? 0,
      bestWinStreak: json['bestWinStreak'] as int? ?? 0,
      levelKey: json['levelKey'] as String? ?? 'casual',
      winStreak: json['winStreak'] as int? ?? 0,
    );
  }

  GameScore copyWith({
    int? gameStarted,
    int? gameWon,
    int? averageScore,
    int? averageTime,
    int? bestScore,
    int? bestTime,
    int? bestWinStreak,
    String? levelKey,
    int? winStreak,
  }) {
    return GameScore(
      gameStarted: gameStarted ?? this.gameStarted,
      gameWon: gameWon ?? this.gameWon,
      averageScore: averageScore ?? this.averageScore,
      averageTime: averageTime ?? this.averageTime,
      bestScore: bestScore ?? this.bestScore,
      bestTime: bestTime ?? this.bestTime,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      levelKey: levelKey ?? this.levelKey,
      winStreak: winStreak ?? this.winStreak,
    );
  }
}
