import 'package:equatable/equatable.dart';
import '../data/game_levels.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class GameStarted extends GameEvent {
  final List<String> categories;
  final GameLevel level;

  const GameStarted({required this.categories, required this.level});

  @override
  List<Object> get props => [categories, level];
}

class GuessSubmitted extends GameEvent {
  const GuessSubmitted();

  @override
  List<Object?> get props => [];
}

class GuessEntered extends GameEvent {
  final String letter;
  const GuessEntered(this.letter);

  @override
  List<Object?> get props => [letter];
}

class GuessDeleted extends GameEvent {
  const GuessDeleted();

  @override
  List<Object?> get props => [];
}

class AddToLibraryRequested extends GameEvent {}

class GameRevived extends GameEvent {}

class HintRequested extends GameEvent {}
