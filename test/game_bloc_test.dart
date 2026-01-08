import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:word_learn_app/data/game_levels.dart';
import 'package:word_learn_app/data/settings_repository.dart';
import 'package:word_learn_app/data/statistics_repository.dart';
import 'package:word_learn_app/data/word_repository.dart';
import 'package:word_learn_app/logic/game_bloc.dart';
import 'package:word_learn_app/logic/game_event.dart';
import 'package:word_learn_app/logic/game_state.dart';

@GenerateMocks([WordRepository, StatisticsRepository, SettingsRepository])
import 'game_bloc_test.mocks.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel('xyz.luan/audioplayers.global').setMockMethodCallHandler((
    MethodCall methodCall,
  ) async {
    return null;
  });
  const MethodChannel('xyz.luan/audioplayers').setMockMethodCallHandler((
    MethodCall methodCall,
  ) async {
    return null;
  });

  group('GameBloc Validation Bug', () {
    late MockWordRepository mockWordRepository;
    late MockStatisticsRepository mockStatisticsRepository;
    late MockSettingsRepository mockSettingsRepository;
    late GameBloc gameBloc;

    setUp(() {
      mockWordRepository = MockWordRepository();
      mockStatisticsRepository = MockStatisticsRepository();
      mockSettingsRepository = MockSettingsRepository();

      when(
        mockWordRepository.getWords(any, any, any),
      ).thenAnswer((_) async => ['apple']);
      when(mockWordRepository.isValidWord(any)).thenAnswer((_) async => false);
      when(mockSettingsRepository.isSoundEnabled).thenReturn(false);
      when(
        mockWordRepository.getWordsCount(any, any, any),
      ).thenAnswer((_) async => 100);

      gameBloc = GameBloc(
        mockWordRepository,
        mockStatisticsRepository,
        mockSettingsRepository,
      );
    });

    // Case 1: Submitting invalid word sets errorMessage
    blocTest<GameBloc, GameState>(
      'errorMessage is set when submitting invalid word',
      build: () => gameBloc,
      act: (bloc) async {
        bloc.add(GameStarted(level: gameLevels[2], categories: ['food']));
        await Future.delayed(Duration.zero);
        // "apple" is 5 letters. Type 5 letters.
        bloc.add(const GuessEntered('a'));
        bloc.add(const GuessEntered('a'));
        bloc.add(const GuessEntered('a'));
        bloc.add(const GuessEntered('a'));
        bloc.add(const GuessEntered('a'));
        bloc.add(const GuessSubmitted());
      },
      verify: (bloc) {
        expect(bloc.state.errorMessage, 'Not a valid word!');
      },
    );

    // Case 2: LetterDeleted should clear errorMessage
    blocTest<GameBloc, GameState>(
      'errorMessage is cleared when letter is deleted',
      build: () => gameBloc,
      act: (bloc) async {
        bloc.add(GameStarted(level: gameLevels[2], categories: ['food']));
        // Type invalid word
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessSubmitted());

        // Delete a letter
        bloc.add(const GuessDeleted());
      },
      skip: 0, // Check all emissions
      verify: (bloc) {
        // If we rely on verify, we must ensure processing is done.
        expect(bloc.state.errorMessage, isNull);
      },
      wait: const Duration(milliseconds: 100), // Give time for event processing
    );

    // Case 3: LetterEntered should clear errorMessage
    blocTest<GameBloc, GameState>(
      'errorMessage is cleared when letter is entered',
      build: () => gameBloc,
      act: (bloc) async {
        bloc.add(GameStarted(level: gameLevels[2], categories: ['food']));
        // Type invalid word
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessEntered('x'));
        bloc.add(const GuessSubmitted());

        // Delete to make space
        bloc.add(const GuessDeleted());
        // Enter new letter
        bloc.add(const GuessEntered('y'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.errorMessage, isNull);
      },
    );
  });
}
