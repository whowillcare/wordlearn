import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:word_learn_app/core/logger.dart';
import 'package:word_learn_app/data/word_repository.dart';
import 'auth_repository.dart';
import 'statistics_repository.dart';

class CloudSyncService {
  final AuthRepository _authRepository;
  final StatisticsRepository _statsRepository;
  final WordRepository _wordRepository;
  final FirebaseFirestore _firestore;

  StreamSubscription<User?>? _userSubscription;
  StreamSubscription<int>? _pointsSubscription;
  StreamSubscription<WordUpdateEvent>? _wordUpdatesSubscription;
  String? _currentUserId;

  // Dynamic Collection Name
  String get _usersCollection => kDebugMode ? 'dev_users' : 'prod_users';

  CloudSyncService({
    required AuthRepository authRepository,
    required StatisticsRepository statsRepository,
    required WordRepository wordRepository,
    FirebaseFirestore? firestore,
  }) : _authRepository = authRepository,
       _statsRepository = statsRepository,
       _wordRepository = wordRepository,
       _firestore = firestore ?? FirebaseFirestore.instance {
    _init();
  }

  void _init() {
    // Listen to Auth State
    _userSubscription = _authRepository.user.listen(_onUserChanged);

    // Listen to Local Points
    _pointsSubscription = _statsRepository.pointsStream.listen(
      _onPointsChanged,
    );

    // Listen to Local Word Updates
    _wordUpdatesSubscription = _wordRepository.updates.listen(_onWordUpdated);
  }

  void dispose() {
    _userSubscription?.cancel();
    _pointsSubscription?.cancel();
    _wordUpdatesSubscription?.cancel();
  }

  Future<void> _onUserChanged(User? user) async {
    _currentUserId = user?.uid;
    if (user != null) {
      // User logged in: Sync from Cloud
      await _syncFromCloud(user.uid);
      await _syncWordsFromCloud(user.uid);
    }
  }

  Future<void> _syncFromCloud(String uid) async {
    try {
      final docRef = _firestore.collection(_usersCollection).doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final data = snapshot.data();
        final remotePoints = data?['totalPoints'] as int? ?? 0;
        final localPoints = await _statsRepository.getTotalPoints();

        // Conflict Resolution: Max wins (prevent data loss)
        if (remotePoints > localPoints) {
          Log.i(
            "Sync: Cloud points ($remotePoints) > Local ($localPoints). Updating local.",
          );
          await _statsRepository.setTotalPoints(remotePoints);
        } else if (localPoints > remotePoints) {
          Log.i(
            "Sync: Local points ($localPoints) > Cloud ($remotePoints). Updating cloud.",
          );
          await _updateCloudPoints(uid, localPoints);
        }
      } else {
        // New user doc, upload local points
        final localPoints = await _statsRepository.getTotalPoints();
        Log.i(
          "Sync: New user. Uploading local points ($localPoints) to start.",
        );
        await _updateCloudPoints(uid, localPoints);
      }
    } catch (e, stack) {
      Log.e("Sync Error", e, stack);
    }
  }

  Future<void> _onPointsChanged(int points) async {
    if (_currentUserId != null) {
      await _updateCloudPoints(_currentUserId!, points);
    }
  }

  Future<void> _updateCloudPoints(String uid, int points) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).set({
        'totalPoints': points,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Log.i("Cloud Sync: Updated points to $points in $_usersCollection");
    } catch (e, stack) {
      Log.e("Cloud Write Error", e, stack);
    }
  }

  // --- Learnt Words Sync ---

  Future<void> _onWordUpdated(WordUpdateEvent event) async {
    if (_currentUserId == null) return;
    await _updateCloudWord(_currentUserId!, event);
  }

  Future<void> _updateCloudWord(String uid, WordUpdateEvent event) async {
    try {
      final docRef = _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection('learnt_words')
          .doc(event.word);

      Log.i(
        "Cloud Sync: Syncing word '${event.word}' for UID: $uid in $_usersCollection",
      );

      if (event.status == 'Deleted') {
        await docRef.delete();
        Log.i("Cloud Sync: Deleted word '${event.word}' from cloud");
      } else {
        await docRef.set({
          'word': event.word,
          'status': event.status,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        Log.i("Cloud Sync: Updated word '${event.word}' to '${event.status}'");
      }
    } catch (e, stack) {
      Log.e("Cloud Word Sync Error", e, stack);
    }
  }

  Future<void> _syncWordsFromCloud(String uid) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection('learnt_words')
          .get();

      if (snapshot.docs.isNotEmpty) {
        Log.i("Sync: Found ${snapshot.docs.length} learnt words in cloud.");
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final String word = data['word'] as String;
          final String status = data['status'] as String;

          if (status == 'Learnt') {
            await _wordRepository.addLearntWord(word, 'unknown');
          } else if (status == 'Mastered') {
            await _wordRepository.addLearntWord(word, 'unknown');
            await _wordRepository.toggleFavorite(word, true);
          }
        }
      }
    } catch (e, stack) {
      Log.e("Sync Words Error", e, stack);
    }
  }
}
