import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
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

  Future<void> incrementStats({required bool won}) async {
    final docRef = _dailyDocRef;
    final updates = {'stats.attempts': FieldValue.increment(1)};

    if (won) {
      updates['stats.wins'] = FieldValue.increment(1);
    } else {
      updates['stats.losses'] = FieldValue.increment(1);
    }

    try {
      await docRef.update(updates);
    } catch (e) {
      // If doc missing (rare race condition if day rolled over), ignore or retry
      print("Error updating stats: $e");
    }
  }
}
