import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/word_repository.dart';
import '../data/game_levels.dart';
import '../data/statistics_repository.dart';
import '../data/settings_repository.dart';
import 'package:audioplayers/audioplayers.dart';

import 'game_event.dart';
import 'game_state.dart';

export 'game_event.dart';
export 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final WordRepository _repository;
  final Random _random = Random();
  final StatisticsRepository _statsRepository;

  final SettingsRepository _settingsRepository;
  final AudioPlayer _audioPlayer = AudioPlayer();

  GameBloc(this._repository, this._statsRepository, this._settingsRepository)
    : super(const GameState()) {
    on<GameStarted>(_onGameStarted);
    on<GuessSubmitted>(_onGuessSubmitted);
    on<LetterEntered>(_onLetterEntered);
    on<LetterDeleted>(_onLetterDeleted);
    on<HintRequested>(_onHintRequested);
    on<SolutionRequested>(_onSolutionRequested);
  }

  Future<void> _onSolutionRequested(
    SolutionRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state.status != GameStatus.playing) return;

    final finishTime = DateTime.now();
    final duration = finishTime
        .difference(state.startTime ?? finishTime)
        .inSeconds;

    await _repository.addLearntWord(state.targetWord, state.category);

    // Count as loss logic
    if (state.level != null) {
      await _statsRepository.recordGame(
        levelKey: state.level!.key,
        isWin: false,
        score: 0,
        durationInSeconds: duration,
      );
    }

    emit(
      state.copyWith(
        status: GameStatus.lost,
        errorMessage: 'Solution Revealed! Word added to Library.',
        revealedIndices: List.generate(
          state.targetWord.length,
          (i) => i,
        ).toSet(),
      ),
    );
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    try {
      print(
        'Starting game with Level: ${event.level.key}, Cat: ${event.category}',
      );

      final minLen = event.level.minLength;
      final maxLen = event.level.maxLength ?? 30;

      final words = await _repository.getWords(event.category, minLen, maxLen);

      if (words.isEmpty) {
        emit(
          state.copyWith(
            status: GameStatus.lost,
            errorMessage:
                'No words found for category "${event.category}" with length ${event.level.minLength}-${event.level.maxLength}',
          ),
        );
        return;
      }

      final target = words[_random.nextInt(words.length)];
      print('Target word selected: $target');

      emit(
        GameState(
          status: GameStatus.playing,
          targetWord: target,
          guesses: const [],
          revealedIndices: const {},
          level: event.level,
          category: event.category,
          startTime: DateTime.now(),
          currentGuess: '',
          letterStatus: const {},
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Error starting game: $e'));
    }
  }

  void _onLetterEntered(LetterEntered event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    if (state.currentGuess.length >= state.targetWord.length) return;

    emit(
      state.copyWith(
        currentGuess: state.currentGuess + event.letter,
        clearError: true,
      ),
    );
  }

  void _onLetterDeleted(LetterDeleted event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    if (state.currentGuess.isEmpty) return;

    emit(
      state.copyWith(
        currentGuess: state.currentGuess.substring(
          0,
          state.currentGuess.length - 1,
        ),
        clearError: true,
      ),
    );
  }

  Future<void> _onGuessSubmitted(
    GuessSubmitted event,
    Emitter<GameState> emit,
  ) async {
    if (state.status != GameStatus.playing) return;

    final guess = state.currentGuess.toLowerCase();

    // Basic Validation
    if (guess.length != state.targetWord.length) {
      return;
    }

    final isValid = await _repository.isValidWord(guess);
    if (!isValid) {
      if (_settingsRepository.isSoundEnabled) {
        try {
          await _audioPlayer.play(
            AssetSource('sounds/error.wav'),
          ); // Assume sound exists
        } catch (_) {}
      }
      emit(state.copyWith(errorMessage: 'Not a valid word!'));
      return; // Stop processing
    }

    final newGuesses = List<String>.from(state.guesses)..add(guess);

    // Update letter status
    final newStatus = Map<String, LetterStatus>.from(state.letterStatus);
    final target = state.targetWord;

    for (int i = 0; i < guess.length; i++) {
      final letter = guess[i];
      if (target[i] == letter) {
        newStatus[letter] = LetterStatus.correct;
      } else if (target.contains(letter)) {
        if (newStatus[letter] != LetterStatus.correct) {
          newStatus[letter] = LetterStatus.wrongPosition;
        }
      } else {
        if (newStatus[letter] == null) {
          newStatus[letter] = LetterStatus.notInWord;
        }
      }
    }

    if (guess == state.targetWord) {
      final finishTime = DateTime.now();
      final duration = finishTime
          .difference(state.startTime ?? finishTime)
          .inSeconds;

      final score = 100;

      await _repository.addLearntWord(state.targetWord, state.category);

      if (state.level != null) {
        await _statsRepository.recordGame(
          levelKey: state.level!.key,
          isWin: true,
          score: score,
          durationInSeconds: duration,
        );
      }

      if (_settingsRepository.isSoundEnabled) {
        try {
          await _audioPlayer.play(AssetSource('sounds/success.wav'));
        } catch (_) {}
      }

      emit(
        state.copyWith(
          guesses: newGuesses,
          status: GameStatus.won,
          currentGuess: '',
          letterStatus: newStatus,
        ),
      );
    } else {
      final maxAttempts = state.level?.attempts ?? 6;

      if (newGuesses.length >= maxAttempts) {
        final finishTime = DateTime.now();
        final duration = finishTime
            .difference(state.startTime ?? finishTime)
            .inSeconds;

        if (state.level != null) {
          await _statsRepository.recordGame(
            levelKey: state.level!.key,
            isWin: false,
            score: 0,
            durationInSeconds: duration,
          );
        }

        if (_settingsRepository.isSoundEnabled) {
          try {
            await _audioPlayer.play(AssetSource('sounds/fail.wav'));
          } catch (_) {}
        }

        emit(
          state.copyWith(
            guesses: newGuesses,
            status: GameStatus.lost,
            currentGuess: '',
            letterStatus: newStatus,
          ),
        );
      } else {
        emit(
          state.copyWith(
            guesses: newGuesses,
            currentGuess: '',
            letterStatus: newStatus,
          ),
        );
      }
    }
  }

  void _onHintRequested(HintRequested event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;

    final target = state.targetWord;
    final unrevealedIndices = <int>[];
    for (int i = 0; i < target.length; i++) {
      if (!state.revealedIndices.contains(i)) {
        unrevealedIndices.add(i);
      }
    }

    if (unrevealedIndices.isNotEmpty) {
      final indexToReveal =
          unrevealedIndices[_random.nextInt(unrevealedIndices.length)];
      final newRevealed = Set<int>.from(state.revealedIndices)
        ..add(indexToReveal);
      emit(state.copyWith(revealedIndices: newRevealed));
    }
  }
}
