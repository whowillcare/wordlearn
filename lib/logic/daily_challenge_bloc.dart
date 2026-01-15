import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/daily_challenge_repository.dart';

// Events
abstract class DailyChallengeEvent extends Equatable {
  const DailyChallengeEvent();
  @override
  List<Object> get props => [];
}

class LoadDailyChallenge extends DailyChallengeEvent {}

class StartDailyGame extends DailyChallengeEvent {}

class WordCompleted extends DailyChallengeEvent {
  final String word;
  final bool success;
  const WordCompleted(this.word, this.success);
}

class ChallengeFinished extends DailyChallengeEvent {}

// State
enum DailyChallengeStatus { initial, loading, ready, playing, finished, error }

class DailyChallengeState extends Equatable {
  final DailyChallengeStatus status;
  final DailyChallenge? challenge;
  final int currentWordIndex;
  final List<bool> results; // Results for words so far
  final String? errorMessage;

  const DailyChallengeState({
    this.status = DailyChallengeStatus.initial,
    this.challenge,
    this.currentWordIndex = 0,
    this.results = const [],
    this.errorMessage,
  });

  DailyChallengeState copyWith({
    DailyChallengeStatus? status,
    DailyChallenge? challenge,
    int? currentWordIndex,
    List<bool>? results,
    String? errorMessage,
  }) {
    return DailyChallengeState(
      status: status ?? this.status,
      challenge: challenge ?? this.challenge,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    challenge,
    currentWordIndex,
    results,
    errorMessage,
  ];
}

// Bloc
class DailyChallengeBloc
    extends Bloc<DailyChallengeEvent, DailyChallengeState> {
  final DailyChallengeRepository _repository;

  DailyChallengeBloc(this._repository) : super(const DailyChallengeState()) {
    on<LoadDailyChallenge>(_onLoad);
    on<StartDailyGame>(_onStart);
    on<WordCompleted>(_onWordCompleted);
  }

  Future<void> _onLoad(
    LoadDailyChallenge event,
    Emitter<DailyChallengeState> emit,
  ) async {
    emit(state.copyWith(status: DailyChallengeStatus.loading));
    try {
      final challenge = await _repository.getDailyChallenge();
      // TODO: Check local persistence if already played today?
      // For now, just load it.
      emit(
        state.copyWith(
          status: DailyChallengeStatus.ready,
          challenge: challenge,
          currentWordIndex: 0,
          results: [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DailyChallengeStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onStart(StartDailyGame event, Emitter<DailyChallengeState> emit) {
    if (state.challenge == null) return;
    emit(
      state.copyWith(status: DailyChallengeStatus.playing, currentWordIndex: 0),
    );
  }

  Future<void> _onWordCompleted(
    WordCompleted event,
    Emitter<DailyChallengeState> emit,
  ) async {
    if (state.status != DailyChallengeStatus.playing || state.challenge == null)
      return;

    final newResults = List<bool>.from(state.results)..add(event.success);

    // Update Global Stats in Background
    _repository.incrementStats(won: event.success);

    if (state.currentWordIndex >= state.challenge!.words.length - 1) {
      // Finished
      try {
        // Try to get updated stats
        final updatedChallenge = await _repository.getDailyChallenge();
        emit(
          state.copyWith(
            status: DailyChallengeStatus.finished,
            results: newResults,
            currentWordIndex: state.currentWordIndex + 1,
            challenge: updatedChallenge,
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            status: DailyChallengeStatus.finished,
            results: newResults,
            currentWordIndex: state.currentWordIndex + 1,
          ),
        );
      }
    } else {
      // Next Word
      emit(
        state.copyWith(
          currentWordIndex: state.currentWordIndex + 1,
          results: newResults,
        ),
      );
    }
  }
}
