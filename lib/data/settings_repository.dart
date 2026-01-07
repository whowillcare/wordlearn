import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVipMode = 'vip_mode';
  static const String _keyLanguage = 'language_code';
  static const String _keyDefaultCategory = 'default_category';

  SettingsRepository(this._prefs);

  static Future<SettingsRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  bool get isSoundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) async =>
      _prefs.setBool(_keySoundEnabled, value);

  bool get isVip => _prefs.getBool(_keyVipMode) ?? false;
  Future<void> setVip(bool value) async => _prefs.setBool(_keyVipMode, value);

  String get languageCode => _prefs.getString(_keyLanguage) ?? 'en';
  Future<void> setLanguageCode(String value) async =>
      _prefs.setString(_keyLanguage, value);

  String? get defaultCategory => _prefs.getString(_keyDefaultCategory);
  Future<void> setDefaultCategory(String value) async =>
      _prefs.setString(_keyDefaultCategory, value);
}
