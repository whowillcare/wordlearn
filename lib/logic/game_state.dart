import 'package:equatable/equatable.dart';
import '../data/game_levels.dart';

enum GameStatus { initial, playing, won, lost }

enum LetterStatus { initial, notInWord, wrongPosition, correct }

class GameState extends Equatable {
  final GameStatus status;
  final String targetWord;
  final List<String> guesses;
  final Set<int> revealedIndices;
  final String? errorMessage;

  final GameLevel? level;
  final List<String> categories;
  final DateTime? startTime;

  final String currentGuess;
  final Map<String, LetterStatus> letterStatus;
  final bool isWordSaved;

  const GameState({
    this.status = GameStatus.initial,
    this.targetWord = '',
    this.guesses = const [],
    this.revealedIndices = const {},
    this.errorMessage,
    this.level,
    this.categories = const [],
    this.startTime,
    this.currentGuess = '',
    this.letterStatus = const {},
    this.categoryWordCount,
    this.isWordSaved = false,
  });

  final int? categoryWordCount;

  GameState copyWith({
    GameStatus? status,
    String? targetWord,
    List<String>? guesses,
    Set<int>? revealedIndices,
    String? errorMessage,
    GameLevel? level,
    List<String>? categories,
    DateTime? startTime,
    String? currentGuess,
    Map<String, LetterStatus>? letterStatus,
    bool clearError = false,
    int? categoryWordCount,
    bool? isWordSaved,
  }) {
    return GameState(
      status: status ?? this.status,
      targetWord: targetWord ?? this.targetWord,
      guesses: guesses ?? this.guesses,
      revealedIndices: revealedIndices ?? this.revealedIndices,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      level: level ?? this.level,
      categories: categories ?? this.categories,
      startTime: startTime ?? this.startTime,
      currentGuess: currentGuess ?? this.currentGuess,
      letterStatus: letterStatus ?? this.letterStatus,
      categoryWordCount: categoryWordCount ?? this.categoryWordCount,
      isWordSaved: isWordSaved ?? this.isWordSaved,
    );
  }

  @override
  List<Object?> get props => [
    status,
    targetWord,
    guesses,
    revealedIndices,
    errorMessage,
    level,
    startTime,
    currentGuess,
    letterStatus,
    categoryWordCount,
  ];
}
