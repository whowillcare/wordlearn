import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'game_score.dart';

class StatisticsRepository {
  static const _keyPrefix = 'stats_';
  static const _keyPoints = 'user_total_points';
  static const _keyLastLogin = 'last_login_date';
  static const _keyDailyStreak = 'daily_streak';
  SharedPreferences? _prefs;

  final _pointsController = BehaviorSubject<int>.seeded(0);
  Stream<int> get pointsStream => _pointsController.stream;
  int get currentPoints => _pointsController.value;

  static Future<StatisticsRepository> init() async {
    final repo = StatisticsRepository();
    repo._prefs = await SharedPreferences.getInstance();
    // Load initial value
    final points = repo._prefs!.getInt(_keyPoints) ?? 100;
    repo._pointsController.add(points);
    // If it was null (new user), save the default
    if (!repo._prefs!.containsKey(_keyPoints)) {
      await repo._prefs!.setInt(_keyPoints, 100);
    }
    return repo;
  }

  void dispose() {
    _pointsController.close();
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

  Future<int> getTotalPoints() async {
    if (_prefs == null) await init();
    if (!_prefs!.containsKey(_keyPoints)) {
      // New user bonus
      await _prefs!.setInt(_keyPoints, 100);
      _pointsController.add(100);
      return 100;
    }
    final p = _prefs!.getInt(_keyPoints) ?? 0;
    // Always sync the behavior subject to ensure latest source of truth
    if (_pointsController.value != p) {
      _pointsController.add(p);
    }
    return p;
  }

  Future<void> setTotalPoints(int points) async {
    if (_prefs == null) await init();
    await _prefs!.setInt(_keyPoints, points);
    _pointsController.add(points);
  }

  Future<void> addPoints(int amount) async {
    // Force init check inside getTotalPoints is enough but let's be safe
    if (_prefs == null) await init();
    final current = await getTotalPoints();
    final newValue = current + amount;
    await _prefs!.setInt(_keyPoints, newValue);
    _pointsController.add(newValue);
  }

  // Daily Bonus Logic
  Future<Map<String, dynamic>> checkDailyBonus() async {
    if (_prefs == null) await init();
    final now = DateTime.now();
    final lastLoginStr = _prefs!.getString(_keyLastLogin);
    int streak = _prefs!.getInt(_keyDailyStreak) ?? 0;

    if (lastLoginStr != null) {
      final lastLogin = DateTime.parse(lastLoginStr);
      final difference = now.difference(lastLogin).inDays;

      if (difference == 0) {
        // Already claimed today
        return {'claimed': true, 'streak': streak, 'reward': 0};
      } else if (difference == 1) {
        // Consecutive day
        streak++;
      } else {
        // Streak broken
        streak = 1;
      }
    } else {
      // First time login ever
      streak = 1;
    }

    // Reward Logic
    int reward = 20;
    if (streak % 7 == 0) {
      reward = 100; // Big reward every 7 days
    }

    // Save
    await _prefs!.setString(_keyLastLogin, now.toIso8601String());
    await _prefs!.setInt(_keyDailyStreak, streak);
    await addPoints(reward); // adds to stream

    return {'claimed': false, 'streak': streak, 'reward': reward};
  }

  Future<bool> deductPoints(int amount) async {
    if (_prefs == null) await init();
    final current = await getTotalPoints();
    if (current >= amount) {
      final newValue = current - amount;
      await _prefs!.setInt(_keyPoints, newValue);
      _pointsController.add(newValue);
      return true;
    }
    return false;
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
