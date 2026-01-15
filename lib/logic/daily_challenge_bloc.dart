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
      final hasCompleted = await _repository.hasCompletedDailyChallenge();

      emit(
        state.copyWith(
          status: hasCompleted
              ? DailyChallengeStatus.finished
              : DailyChallengeStatus.ready,
          challenge: challenge,
          currentWordIndex: 0,
          results: hasCompleted
              ? List.filled(challenge.words.length, true)
              : [], // Fake results if done?
          errorMessage: hasCompleted
              ? 'You have already completed today\'s challenge!'
              : null,
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

  Future<void> _onStart(
    StartDailyGame event,
    Emitter<DailyChallengeState> emit,
  ) async {
    if (state.challenge == null) return;

    // Log Attempt
    await _repository.incrementStartStats();

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

    // No per-word global stat update anymore

    if (state.currentWordIndex >= state.challenge!.words.length - 1) {
      // Finished Game
      final wins = newResults.where((r) => r).length;
      final isWin =
          wins ==
          state
              .challenge!
              .words
              .length; // Strict: All words must be won? Or majority? User implied 3/3.

      if (isWin) {
        await _repository.incrementWinStats();
        await _repository.markDailyChallengeCompleted();
      } else {
        await _repository.incrementLossStats();
      }

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
