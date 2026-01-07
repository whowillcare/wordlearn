import 'package:equatable/equatable.dart';
import '../data/game_levels.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class GameStarted extends GameEvent {
  final String category;
  final GameLevel level;

  const GameStarted({required this.category, required this.level});

  @override
  List<Object> get props => [category, level];
}

class GuessSubmitted extends GameEvent {
  const GuessSubmitted();

  @override
  List<Object?> get props => [];
}

class LetterEntered extends GameEvent {
  final String letter;
  const LetterEntered(this.letter);

  @override
  List<Object?> get props => [letter];
}

class LetterDeleted extends GameEvent {
  const LetterDeleted();

  @override
  List<Object?> get props => [];
}

class HintRequested extends GameEvent {}

class SolutionRequested extends GameEvent {}
