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
  final String? targetWord;

  const GameStarted({
    required this.categories,
    required this.level,
    this.targetWord,
  });

  @override
  List<Object?> get props => [categories, level, targetWord];
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

enum HintType { letter, synonym }

class HintRequested extends GameEvent {
  final HintType type;
  const HintRequested(this.type);

  @override
  List<Object?> get props => [type];
}

class PointsEarned extends GameEvent {
  final int amount;
  const PointsEarned(this.amount);

  @override
  List<Object?> get props => [amount];
}
