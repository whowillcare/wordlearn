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
  final String category;
  final DateTime? startTime;

  final String currentGuess;
  final Map<String, LetterStatus> letterStatus;

  const GameState({
    this.status = GameStatus.initial,
    this.targetWord = '',
    this.guesses = const [],
    this.revealedIndices = const {},
    this.errorMessage,
    this.level,
    this.category = '',
    this.startTime,
    this.currentGuess = '',
    this.letterStatus = const {},
  });

  GameState copyWith({
    GameStatus? status,
    String? targetWord,
    List<String>? guesses,
    Set<int>? revealedIndices,
    String? errorMessage,
    GameLevel? level,
    String? category,
    DateTime? startTime,
    String? currentGuess,
    Map<String, LetterStatus>? letterStatus,
  }) {
    return GameState(
      status: status ?? this.status,
      targetWord: targetWord ?? this.targetWord,
      guesses: guesses ?? this.guesses,
      revealedIndices: revealedIndices ?? this.revealedIndices,
      errorMessage: errorMessage ?? this.errorMessage,
      level: level ?? this.level,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      currentGuess: currentGuess ?? this.currentGuess,
      letterStatus: letterStatus ?? this.letterStatus,
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
  ];
}
