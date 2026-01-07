import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_score.dart';

class StatisticsRepository {
  static const _keyPrefix = 'stats_';
  SharedPreferences? _prefs;

  static Future<StatisticsRepository> init() async {
    final repo = StatisticsRepository();
    repo._prefs = await SharedPreferences.getInstance();
    return repo;
  }

  Future<GameScore> getScore(String levelKey) async {
    if (_prefs == null) await init();
    final jsonString = _prefs!.getString('$_keyPrefix$levelKey');
    if (jsonString != null) {
      try {
        return GameScore.fromJson(jsonDecode(jsonString));
      } catch (e) {
        // Fallback if corrupt
        return GameScore.initial(levelKey);
      }
    }
    return GameScore.initial(levelKey);
  }

  Future<void> recordGame({
    required String levelKey,
    required bool isWin,
    required int score, // Points for this game
    required int durationInSeconds,
  }) async {
    if (_prefs == null) await init();

    final currentObj = await getScore(levelKey);

    int newGameStarted = currentObj.gameStarted + 1;
    int newGameWon = currentObj.gameWon;
    int newWinStreak = currentObj.winStreak;
    int newBestWinStreak = currentObj.bestWinStreak;
    int newAverageScore = currentObj.averageScore;
    int newAverageTime = currentObj.averageTime;
    int newBestScore = currentObj.bestScore;
    int newBestTime = currentObj.bestTime;

    if (isWin) {
      newGameWon++;
      newWinStreak++;
      if (newWinStreak > newBestWinStreak) newBestWinStreak = newWinStreak;

      // Averages
      // avg_new = (avg_old * old_wins + new_val) / new_wins
      // Note: old_wins is currentObj.gameWon
      newAverageScore =
          ((currentObj.averageScore * currentObj.gameWon + score) / newGameWon)
              .round();
      newAverageTime =
          ((currentObj.averageTime * currentObj.gameWon + durationInSeconds) /
                  newGameWon)
              .round();

      if (score > newBestScore) newBestScore = score;
      if (newBestTime == 0 || durationInSeconds < newBestTime)
        newBestTime = durationInSeconds;
    } else {
      newWinStreak = 0;
    }

    final newObj = GameScore(
      gameStarted: newGameStarted,
      gameWon: newGameWon,
      averageScore: newAverageScore,
      averageTime: newAverageTime,
      bestScore: newBestScore,
      bestTime: newBestTime,
      bestWinStreak: newBestWinStreak,
      levelKey: levelKey,
      winStreak: newWinStreak,
    );

    await _prefs!.setString(
      '$_keyPrefix$levelKey',
      jsonEncode(newObj.toJson()),
    );
  }
}
