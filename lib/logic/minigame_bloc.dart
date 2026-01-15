import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/word_repository.dart';
import '../data/settings_repository.dart';
import '../data/statistics_repository.dart';
import '../config/economy_constants.dart';
import '../data/game_levels.dart';

// Events
abstract class MiniGameEvent extends Equatable {
  const MiniGameEvent();
  @override
  List<Object?> get props => [];
}

class StartNewGame extends MiniGameEvent {}

class SubmitGuess extends MiniGameEvent {
  final String guess;
  const SubmitGuess(this.guess);
}

class ShuffleLetters extends MiniGameEvent {}

class SkipWord extends MiniGameEvent {}

class RequestHint extends MiniGameEvent {}

class AddToLibrary extends MiniGameEvent {}

// State
enum GameStatus { initial, loading, playing, won, lost }

class MiniGameState extends Equatable {
  final GameStatus status;
  final String targetWord;
  final String scrambledWord;
  final int score;
  final String message;
  final String hintText;
  final int hintsUsed;
  final bool isWordLearnt;

  const MiniGameState({
    this.status = GameStatus.initial,
    this.targetWord = '',
    this.scrambledWord = '',
    this.score = 0,
    this.message = '',
    this.hintText = '',
    this.hintsUsed = 0,
    this.isWordLearnt = false,
  });

  MiniGameState copyWith({
    GameStatus? status,
    String? targetWord,
    String? scrambledWord,
    int? score,
    String? message,
    String? hintText,
    int? hintsUsed,
    bool? isWordLearnt,
  }) {
    return MiniGameState(
      status: status ?? this.status,
      targetWord: targetWord ?? this.targetWord,
      scrambledWord: scrambledWord ?? this.scrambledWord,
      score: score ?? this.score,
      message: message ?? this.message,
      hintText: hintText ?? this.hintText,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isWordLearnt: isWordLearnt ?? this.isWordLearnt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    targetWord,
    scrambledWord,
    score,
    message,
    hintText,
    hintsUsed,
    isWordLearnt,
  ];
}

// Bloc
class MiniGameBloc extends Bloc<MiniGameEvent, MiniGameState> {
  final WordRepository _wordRepository;
  final SettingsRepository _settingsRepository;
  final StatisticsRepository _statisticsRepository;

  MiniGameBloc(
    this._wordRepository,
    this._settingsRepository,
    this._statisticsRepository,
  ) : super(const MiniGameState()) {
    on<StartNewGame>(_onStartNewGame);
    on<SubmitGuess>(_onSubmitGuess);
    on<ShuffleLetters>(_onShuffleLetters);
    on<SkipWord>(_onSkipWord);
    on<RequestHint>(_onRequestHint);
    on<AddToLibrary>(_onAddToLibrary);
  }

  Future<void> _onStartNewGame(
    StartNewGame event,
    Emitter<MiniGameState> emit,
  ) async {
    emit(
      state.copyWith(
        status: GameStatus.loading,
        message: '',
        hintText: '',
        hintsUsed: 0,
        isWordLearnt: false,
      ),
    );

    // Get settings
    final categories = _settingsRepository.defaultCategories;
    final levelKey = _settingsRepository.gameLevel;

    // Resolve GameLevel object
    final level = gameLevels.firstWhere(
      (l) => l.key == levelKey,
      orElse: () => gameLevels.firstWhere((l) => l.key == 'classic'),
    );

    int minLength = level.minLength;
    int? maxLength = level.maxLength;

    final word = await _wordRepository.getRandomWord(
      minLength,
      maxLength,
      categories,
    );

    if (word != null) {
      final scrambled = _scramble(word);
      emit(
        state.copyWith(
          status: GameStatus.playing,
          targetWord: word,
          scrambledWord: scrambled,
          message: '',
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: GameStatus.lost,
          message: 'Could not load word for selected level/category.',
        ),
      );
    }
  }

  Future<void> _onSubmitGuess(
    SubmitGuess event,
    Emitter<MiniGameState> emit,
  ) async {
    if (state.status != GameStatus.playing) return;

    if (event.guess.trim().toLowerCase() == state.targetWord.toLowerCase()) {
      // Award points (less if hints used)
      int points =
          state.targetWord.length * EconomyConstants.anagramWinMultiplier;
      if (state.hintsUsed > 0) {
        points = (points / 2).floor();
      }

      await _statisticsRepository.addPoints(points);

      emit(
        state.copyWith(
          status: GameStatus.won,
          score: state.score + points,
          message: 'Correct! +$points Points',
        ),
      );
    } else {
      emit(state.copyWith(message: 'Incorrect, try again!'));
    }
  }

  void _onShuffleLetters(ShuffleLetters event, Emitter<MiniGameState> emit) {
    emit(state.copyWith(scrambledWord: _scramble(state.targetWord)));
  }

  Future<void> _onSkipWord(SkipWord event, Emitter<MiniGameState> emit) async {
    add(StartNewGame());
  }

  Future<void> _onRequestHint(
    RequestHint event,
    Emitter<MiniGameState> emit,
  ) async {
    if (state.status != GameStatus.playing) return;

    final target = state.targetWord;
    final currentHintLen = state.hintText.length;

    if (currentHintLen >= target.length - 1) {
      emit(state.copyWith(message: 'No more hints available!'));
      return;
    }

    // Check limits/funds
    final success = await _statisticsRepository.deductPoints(
      EconomyConstants.hintCost,
    );
    if (!success) {
      emit(
        state.copyWith(
          message: 'Not enough diamonds! Need ${EconomyConstants.hintCost}.',
        ),
      );
      return;
    }

    final nextChar = target[currentHintLen];
    final newHint = state.hintText + nextChar;

    emit(
      state.copyWith(
        hintText: newHint,
        hintsUsed: state.hintsUsed + 1,
        message:
            'Hint: Letter ${currentHintLen + 1} is "$nextChar" (-${EconomyConstants.hintCost} 💎)',
      ),
    );
  }

  Future<void> _onAddToLibrary(
    AddToLibrary event,
    Emitter<MiniGameState> emit,
  ) async {
    if (state.isWordLearnt) return;

    await _wordRepository.addLearntWord(state.targetWord, 'Game');

    emit(
      state.copyWith(
        isWordLearnt: true,
        message: 'Added "${state.targetWord}" to Library!',
      ),
    );
  }

  String _scramble(String word) {
    List<String> chars = word.split('');
    chars.shuffle();
    String scrambled = chars.join('');
    // Ensure it's not the same as original
    if (scrambled == word && word.length > 1) {
      return _scramble(word);
    }
    return scrambled;
  }
}
