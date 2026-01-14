import 'dart:math';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../data/word_repository.dart';
import '../data/game_levels.dart';
import '../data/statistics_repository.dart';
import '../data/settings_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:word_learn_app/core/logger.dart';

import 'game_event.dart';
import 'game_state.dart';

export 'game_event.dart';
export 'game_state.dart';

class GameBloc extends HydratedBloc<GameEvent, GameState> {
  final WordRepository _repository;
  final Random _random = Random();
  final StatisticsRepository _statsRepository;

  final SettingsRepository _settingsRepository;
  final AudioPlayer _audioPlayer = AudioPlayer();

  GameBloc(this._repository, this._statsRepository, this._settingsRepository)
    : super(const GameState()) {
    on<GameStarted>(_onGameStarted);
    on<GuessSubmitted>(_onGuessSubmitted);
    on<GuessEntered>(_onGuessEntered);
    on<GuessDeleted>(_onGuessDeleted);
    on<AddToLibraryRequested>(_onAddToLibraryRequested);
    on<HintRequested>(_onHintRequested);
    on<GameRevived>(_onGameRevived);
    on<PointsEarned>(_onPointsEarned);
  }

  @override
  GameState? fromJson(Map<String, dynamic> json) {
    try {
      final statusIndex = json['status'] as int? ?? 0;
      final status = GameStatus.values[statusIndex];

      final levelKey = json['levelKey'] as String?;
      final level = gameLevels.firstWhere(
        (l) => l.key == levelKey,
        orElse: () => gameLevels[2], // Default to Grade 3
      );

      return GameState(
        status: status,
        targetWord: json['targetWord'] as String? ?? '',
        guesses: (json['guesses'] as List<dynamic>?)?.cast<String>() ?? [],
        revealedIndices:
            (json['revealedIndices'] as List<dynamic>?)?.cast<int>().toSet() ??
            {},
        level: level,
        categories:
            (json['categories'] as List<dynamic>?)?.cast<String>() ?? ['all'],
        currentGuess: json['currentGuess'] as String? ?? '',
        startTime: json['startTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['startTime'])
            : null,
        letterStatus: _calculateLetterStatus(
          json['targetWord'] as String? ?? '',
          (json['guesses'] as List<dynamic>?)?.cast<String>() ?? [],
        ),
        categoryWordCount: json['categoryWordCount'] as int?,
        isWordSaved: json['isWordSaved'] as bool? ?? false,
      );
    } catch (e, s) {
      Log.e('Failed to load game state', e, s);
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(GameState state) {
    try {
      return {
        'status': state.status.index,
        'targetWord': state.targetWord,
        'guesses': state.guesses,
        'revealedIndices': state.revealedIndices.toList(),
        'levelKey': state.level?.key,
        'categories': state.categories,
        'currentGuess': state.currentGuess,
        'startTime': state.startTime?.millisecondsSinceEpoch,
        'categoryWordCount': state.categoryWordCount,
        'isWordSaved': state.isWordSaved,
      };
    } catch (e, s) {
      Log.e('Failed to save game state', e, s);
      return null;
    }
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    try {
      Log.i(
        'Starting game with Level: ${event.level.key}, Cats: ${event.categories.join(', ')}',
      );

      final minLen = event.level.minLength;
      final maxLen = event.level.maxLength ?? 30;

      final allowSpecial = _settingsRepository.isSpecialCharsAllowed;
      await _statsRepository.deductPoints(10); // Cost to play

      final words = await _repository.getWords(
        event.categories,
        minLen,
        maxLen,
        allowSpecialChars: allowSpecial,
      );
      final count = await _repository.getWordsCount(
        event.categories,
        minLen,
        maxLen,
        allowSpecialChars: allowSpecial,
      );

      String target;
      if (event.targetWord != null) {
        target = event.targetWord!.toLowerCase();
      } else {
        if (words.isEmpty) {
          emit(
            state.copyWith(
              status: GameStatus.lost,
              errorMessage:
                  'No words found for categories "${event.categories.join(', ')}" with length ${event.level.minLength}-${event.level.maxLength}',
            ),
          );
          return;
        }
        target = words[_random.nextInt(words.length)].toLowerCase();
      }

      Log.i('Target word selected: $target');

      emit(
        GameState(
          status: GameStatus.playing,
          targetWord: target,
          guesses: const [],
          revealedIndices: const {},
          level: event.level,
          categories: event.categories,
          startTime: DateTime.now(),
          currentGuess: '',
          letterStatus: const {},
          categoryWordCount: count,
        ),
      );
    } catch (e, s) {
      Log.e('Failed to start game', e, s);
      emit(state.copyWith(errorMessage: 'Failed to start game: $e'));
    }
  }

  void _onGuessEntered(GuessEntered event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    if (state.currentGuess.length >= state.targetWord.length) return;

    emit(
      state.copyWith(
        currentGuess: state.currentGuess + event.letter,
        clearError: true,
      ),
    );
  }

  void _onGuessDeleted(GuessDeleted event, Emitter<GameState> emit) {
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
    final newStatus = _calculateLetterStatus(state.targetWord, newGuesses);

    if (guess == state.targetWord) {
      final finishTime = DateTime.now();
      final duration = finishTime
          .difference(state.startTime ?? finishTime)
          .inSeconds;

      final score = 100;

      if (state.level != null) {
        await _statsRepository.recordGame(
          levelKey: state.level!.key,
          isWin: true,
          score: score,
          durationInSeconds: duration,
        );
      }

      try {
        await _audioPlayer.play(AssetSource('sounds/success.wav'));
      } catch (_) {}

      await _statsRepository.addPoints(20);

      emit(
        state.copyWith(
          guesses: newGuesses,
          status: GameStatus.won,
          currentGuess: '',
          letterStatus: newStatus,
          isWordSaved: false,
        ),
      );
    } else {
      final maxAttempts = (state.level?.attempts ?? 6) + state.bonusAttempts;

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

  Map<String, LetterStatus> _calculateLetterStatus(
    String targetWord,
    List<String> guesses,
  ) {
    final newStatus = <String, LetterStatus>{};
    for (final guess in guesses) {
      for (int i = 0; i < guess.length; i++) {
        final letter = guess[i];
        if (targetWord[i] == letter) {
          newStatus[letter] = LetterStatus.correct;
        } else if (targetWord.contains(letter)) {
          if (newStatus[letter] != LetterStatus.correct) {
            newStatus[letter] = LetterStatus.wrongPosition;
          }
        } else {
          if (newStatus[letter] == null) {
            newStatus[letter] = LetterStatus.notInWord;
          }
        }
      }
    }
    return newStatus;
  }

  Future<void> _onAddToLibraryRequested(
    AddToLibraryRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state.status != GameStatus.won || state.isWordSaved) return;

    try {
      final category = await _repository.getWordCategory(state.targetWord);
      await _repository.addLearntWord(state.targetWord, category);
      emit(state.copyWith(isWordSaved: true));
    } catch (e, s) {
      Log.e('Error saving word', e, s);
    }
  }

  Future<void> _onHintRequested(
    HintRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state.status != GameStatus.playing) return;

    if (event.type == HintType.letter) {
      await _handleLetterHint(emit);
    } else if (event.type == HintType.synonym) {
      await _handleSynonymHint(emit);
    }
  }

  Future<void> _handleLetterHint(Emitter<GameState> emit) async {
    const cost = 10;
    final hasPoints = await _statsRepository.deductPoints(cost);
    if (!hasPoints) {
      _playErrorSound();
      emit(state.copyWith(errorMessage: 'Not enough points! Need $cost.'));
      return;
    }

    final target = state.targetWord;
    final unrevealedIndices = <int>[];
    for (int i = 0; i < target.length; i++) {
      if (!state.revealedIndices.contains(i)) {
        unrevealedIndices.add(i);
      }
    }

    if (unrevealedIndices.isEmpty) {
      emit(state.copyWith(errorMessage: 'All letters revealed!'));
      return;
    }

    final unknownIndices = unrevealedIndices.where((i) {
      for (final guess in state.guesses) {
        if (guess.length > i && guess[i] == target[i]) {
          return false;
        }
      }
      return true;
    }).toList();

    final candidates = unknownIndices.isNotEmpty
        ? unknownIndices
        : unrevealedIndices;

    if (candidates.isEmpty) {
      emit(state.copyWith(errorMessage: 'All letters known!'));
      return;
    }

    final index = candidates[_random.nextInt(candidates.length)];
    final newRevealed = Set<int>.from(state.revealedIndices)..add(index);

    _playSuccessSound();
    emit(state.copyWith(revealedIndices: newRevealed));
  }

  Future<void> _handleSynonymHint(Emitter<GameState> emit) async {
    const cost = 20;

    final hasPoints = await _statsRepository.deductPoints(cost);
    if (!hasPoints) {
      _playErrorSound();
      emit(state.copyWith(errorMessage: 'Not enough points! Need $cost.'));
      return;
    }

    final meanings = await _repository.getWordMeanings(state.targetWord);
    String msg = 'No hint available for this word.';

    if (meanings != null) {
      if (meanings.synonyms.isNotEmpty) {
        msg = 'Synonym: ${meanings.synonyms.first}';
      } else if (meanings.definitions.isNotEmpty) {
        String def = meanings.definitions.first;
        final target = state.targetWord;
        def = def.replaceAll(RegExp(target, caseSensitive: false), '****');
        msg = 'Definition: $def';
      }
    }

    _playSuccessSound();
    emit(
      state.copyWith(
        hintMessage: msg,
        isCategoryRevealed: true, // Ensure hint box is visible
      ),
    );
  }

  void _playErrorSound() {
    if (_settingsRepository.isSoundEnabled) {
      try {
        _audioPlayer.play(AssetSource('sounds/error.wav'));
      } catch (_) {}
    }
  }

  void _playSuccessSound() {
    if (_settingsRepository.isSoundEnabled) {
      try {
        _audioPlayer.play(AssetSource('sounds/success.wav'));
      } catch (_) {}
    }
  }

  Future<void> _onGameRevived(
    GameRevived event,
    Emitter<GameState> emit,
  ) async {
    if (state.status != GameStatus.lost) return;

    final cost = 30;
    final hasPoints = await _statsRepository.deductPoints(cost);

    if (!hasPoints) {
      if (_settingsRepository.isSoundEnabled) {
        try {
          await _audioPlayer.play(AssetSource('sounds/error.wav'));
        } catch (_) {}
      }
      emit(state.copyWith(errorMessage: 'Not enough points to revive!'));
      return;
    }

    emit(
      state.copyWith(
        status: GameStatus.playing,
        bonusAttempts: state.bonusAttempts + 3,
        errorMessage: null, // Clear error
        clearError: true,
      ),
    );

    if (_settingsRepository.isSoundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/success.wav'));
      } catch (_) {}
    }
  }

  Future<void> _onPointsEarned(
    PointsEarned event,
    Emitter<GameState> emit,
  ) async {
    await _statsRepository.addPoints(event.amount);
    if (_settingsRepository.isSoundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/success.wav'));
      } catch (_) {}
    }
  }
}
