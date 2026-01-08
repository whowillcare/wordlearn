import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVipMode = 'vip_mode';
  static const String _keyLanguage = 'language_code';
  static const String _keyDefaultCategories = 'default_categories';
  static const String _keyDefaultCategory =
      'default_category'; // Deprecated for single value

  SettingsRepository(this._prefs);

  static Future<SettingsRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    await repo._initFirebase();
    return repo;
  }

  Future<void> _initFirebase() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("Signed in anonymously: ${userCredential.user?.uid}");
      // Trigger a sync or listen to changes here if desired
    } catch (e) {
      print("Firebase Auth failed: $e");
    }
  }

  Future<void> syncSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'vip_mode': isVip,
        'sound_enabled': isSoundEnabled,
        'language_code': languageCode,
        'default_categories': defaultCategories,
        'last_synced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Sync failed: $e");
    }
  }

  bool get isSoundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_keySoundEnabled, value);
    syncSettings();
  }

  bool get isVip => _prefs.getBool(_keyVipMode) ?? false;
  Future<void> setVip(bool value) async {
    await _prefs.setBool(_keyVipMode, value);
    syncSettings();
  }

  String get languageCode => _prefs.getString(_keyLanguage) ?? 'en';
  Future<void> setLanguageCode(String value) async {
    await _prefs.setString(_keyLanguage, value);
    syncSettings();
  }

  String? get defaultCategory => _prefs.getString(_keyDefaultCategory);
  Future<void> setDefaultCategory(String value) async =>
      _prefs.setString(_keyDefaultCategory, value);

  List<String> get defaultCategories {
    // Check new list key first
    if (_prefs.containsKey(_keyDefaultCategories)) {
      return _prefs.getStringList(_keyDefaultCategories) ?? [];
    }
    // Fallback to legacy single key
    final single = _prefs.getString(_keyDefaultCategory);
    if (single != null) return [single];

    return [];
  }

  Future<void> setDefaultCategories(List<String> values) async {
    await _prefs.setStringList(_keyDefaultCategories, values);
    syncSettings();
  }
}
