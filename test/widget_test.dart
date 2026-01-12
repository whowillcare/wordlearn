import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:word_learn_app/data/word_repository.dart';
import 'package:word_learn_app/data/statistics_repository.dart';
import 'package:word_learn_app/data/game_score.dart';

import 'package:word_learn_app/data/settings_repository.dart';
import 'package:word_learn_app/main.dart';
import 'package:word_learn_app/l10n/app_localizations.dart';

class MockWordRepository extends Mock implements WordRepository {
  @override
  Future<List<String>> getCategories() async => [];

  @override
  Future<List<String>> getWords(
    List<String> categories,
    int minLength,
    int maxLength, {
    bool allowSpecialChars = true,
  }) async => [];

  @override
  Future<int> getWordsCount(
    List<String> categories,
    int minLength,
    int maxLength, {
    bool allowSpecialChars = true,
  }) async => 0;

  @override
  Future<String> getWordCategory(String word) async => 'unknown';

  @override
  Future<void> insertWord(String text, String category) async {}

  @override
  Future<void> bulkInsertWords(List<Map<String, dynamic>> words) async {}

  @override
  Future<void> addLearntWord(String word, String category) async {}

  @override
  Future<List<Map<String, dynamic>>> getLearntWords() async => [];

  @override
  Future<void> toggleFavorite(String word, bool isFav) async {}

  @override
  Future<void> deleteLearntWord(String word) async {}

  @override
  Future<bool> isWordLearnt(String word) async => false;

  @override
  Future<List<String>> searchCategories(String query) async => [];

  @override
  Future<int> getWordCount() async => 0;
}

class MockStatisticsRepository extends Mock implements StatisticsRepository {
  @override
  Future<void> init() async {}
  @override
  Future<GameScore> getScore(String levelKey) async =>
      GameScore.initial(levelKey);

  @override
  Future<int> getTotalPoints() async => 0;

  @override
  Future<Map<String, dynamic>> checkDailyBonus() async => {};
}

class MockSettingsRepository extends Mock implements SettingsRepository {
  @override
  bool get isSoundEnabled => true;
  @override
  bool get isVip => false;
  @override
  String get languageCode => 'en';
  @override
  List<String> get defaultCategories => [];
  @override
  String? get defaultCategory => null;

  @override
  String get gameLevel => 'grade-1';

  @override
  Future<void> syncSettings() async {}
}

class MockStorage extends Mock implements Storage {
  @override
  Future<void> write(String key, dynamic value) async {}
  @override
  dynamic read(String key) => null;
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    HydratedBloc.storage = MockStorage();
    // Build our app and trigger a frame.
    // Note: The default template has a counter, but our MyApp has changed to HomeScreen.
    // So this test needs to adapt or just verify MyApp builds.

    await tester.pumpWidget(
      MyApp(
        repository: MockWordRepository(),
        statsRepository: MockStatisticsRepository(),
        settingsRepository: MockSettingsRepository(),
      ),
    );

    // Verify that our app builds.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
