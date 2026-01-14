import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';
import 'statistics_repository.dart';

class CloudSyncService {
  final AuthRepository _authRepository;
  final StatisticsRepository _statsRepository;
  final FirebaseFirestore _firestore;

  StreamSubscription<User?>? _userSubscription;
  StreamSubscription<int>? _pointsSubscription;
  String? _currentUserId;

  // Dynamic Collection Name
  String get _usersCollection => kDebugMode ? 'dev_users' : 'prod_users';

  CloudSyncService({
    required AuthRepository authRepository,
    required StatisticsRepository statsRepository,
    FirebaseFirestore? firestore,
  }) : _authRepository = authRepository,
       _statsRepository = statsRepository,
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
  }

  void dispose() {
    _userSubscription?.cancel();
    _pointsSubscription?.cancel();
  }

  Future<void> _onUserChanged(User? user) async {
    _currentUserId = user?.uid;
    if (user != null) {
      // User logged in: Sync from Cloud
      await _syncFromCloud(user.uid);
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
        // Or if local > remote, update remote.
        // If remote > local, update local.

        if (remotePoints > localPoints) {
          await _statsRepository.setTotalPoints(remotePoints);
        } else if (localPoints > remotePoints) {
          await _updateCloudPoints(uid, localPoints);
        }
      } else {
        // New user doc, upload local points
        final localPoints = await _statsRepository.getTotalPoints();
        await _updateCloudPoints(uid, localPoints);
      }
    } catch (e) {
      print("Sync Error: $e");
    }
  }

  Future<void> _onPointsChanged(int points) async {
    if (_currentUserId != null) {
      // Debounce could be added here if needed, but Firestore writes are cheap enough for this volume
      await _updateCloudPoints(_currentUserId!, points);
    }
  }

  Future<void> _updateCloudPoints(String uid, int points) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).set({
        'totalPoints': points,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Cloud Write Error: $e");
    }
  }
}
