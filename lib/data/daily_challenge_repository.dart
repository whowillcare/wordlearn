import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_repository.dart';

class DailyChallenge {
  final String date;
  final List<String> words;
  final Map<String, dynamic> stats;

  const DailyChallenge({
    required this.date,
    required this.words,
    this.stats = const {'attempts': 0, 'wins': 0},
  });

  factory DailyChallenge.fromMap(Map<String, dynamic> map, String id) {
    return DailyChallenge(
      date: id,
      words: List<String>.from(map['words'] ?? []),
      stats: Map<String, dynamic>.from(map['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'words': words,
      'stats': stats,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}

class DailyChallengeRepository {
  final FirebaseFirestore _firestore;
  final WordRepository _wordRepository;

  DailyChallengeRepository({
    FirebaseFirestore? firestore,
    required WordRepository wordRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _wordRepository = wordRepository;

  String get _collectionName => kDebugMode ? 'dev_users' : 'prod_users';

  String get _todayStr {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  DocumentReference get _dailyDocRef {
    return _firestore
        .collection(_collectionName)
        .doc('public')
        .collection('daily_word')
        .doc(_todayStr);
  }

  Future<DailyChallenge> getDailyChallenge() async {
    final docRef = _dailyDocRef;

    // Transaction to safely get or create
    return _firestore.runTransaction<DailyChallenge>((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        return DailyChallenge.fromMap(
          snapshot.data() as Map<String, dynamic>,
          snapshot.id,
        );
      } else {
        // Generate new words
        final words = await _wordRepository.getDailyChallengeWords();

        // Fallback if repository fails (shouldn't happen often)
        final safeWords = words.isNotEmpty
            ? words
            : ['apple', 'grape', 'banana'];

        final newChallenge = DailyChallenge(date: _todayStr, words: safeWords);

        transaction.set(docRef, newChallenge.toMap());
        return newChallenge;
      }
    });
  }

  Future<void> incrementStartStats() async {
    // Called when user STARTS a game -> Attempts + 1
    final docRef = _dailyDocRef;
    try {
      await docRef.update({'stats.attempts': FieldValue.increment(1)});
    } catch (e) {
      print("Error updating start stats: $e");
    }
  }

  Future<void> incrementWinStats() async {
    // Called when user WINS the game -> Wins + 1
    final docRef = _dailyDocRef;
    try {
      await docRef.update({'stats.wins': FieldValue.increment(1)});
    } catch (e) {
      print("Error updating win stats: $e");
    }
  }

  Future<void> incrementLossStats() async {
    // Called when user FAILS the game -> Losses + 1
    final docRef = _dailyDocRef;
    try {
      await docRef.update({'stats.losses': FieldValue.increment(1)});
    } catch (e) {
      print("Error updating loss stats: $e");
    }
  }

  // --- Local Persistence for Daily Status ---

  Future<bool> hasCompletedDailyChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'daily_solved_$_todayStr';
    return prefs.getBool(key) ?? false;
  }

  Future<void> markDailyChallengeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'daily_solved_$_todayStr';
    await prefs.setBool(key, true);
  }
}
