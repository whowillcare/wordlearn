import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';
import '../data/settings_repository.dart';
import '../data/game_levels.dart';

// Events
abstract class FlashcardsEvent extends Equatable {
  const FlashcardsEvent();
  @override
  List<Object> get props => [];
}

class StartFlashcards extends FlashcardsEvent {}

class CheckAnswer extends FlashcardsEvent {
  final String answer;
  const CheckAnswer(this.answer);
  @override
  List<Object> get props => [answer];
}

class NextQuestion extends FlashcardsEvent {}

// State
enum FlashcardsStatus { initial, loading, question, answered, finished, error }

class FlashcardsState extends Equatable {
  final FlashcardsStatus status;
  final List<Map<String, dynamic>> questions;
  final int currentIndex;
  final int score;
  final String? selectedAnswer;
  final bool? isCorrect;

  const FlashcardsState({
    this.status = FlashcardsStatus.initial,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.selectedAnswer,
    this.isCorrect,
  });

  Map<String, dynamic>? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
      ? questions[currentIndex]
      : null;

  FlashcardsState copyWith({
    FlashcardsStatus? status,
    List<Map<String, dynamic>>? questions,
    int? currentIndex,
    int? score,
    String? selectedAnswer,
    bool? isCorrect,
  }) {
    return FlashcardsState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  List<Object?> get props => [
    status,
    questions,
    currentIndex,
    score,
    selectedAnswer,
    isCorrect,
  ];
}

// Bloc
class FlashcardsBloc extends Bloc<FlashcardsEvent, FlashcardsState> {
  final WordRepository _wordRepository;
  final StatisticsRepository _statisticsRepository;
  final SettingsRepository _settingsRepository;

  static const int _questionsPerGame = 10;
  static const int _pointsPerCorrect = 5;

  FlashcardsBloc(
    this._wordRepository,
    this._statisticsRepository,
    this._settingsRepository,
  ) : super(const FlashcardsState()) {
    on<StartFlashcards>(_onStartGame);
    on<CheckAnswer>(_onCheckAnswer);
    on<NextQuestion>(_onNextQuestion);
  }

  Future<void> _onStartGame(
    StartFlashcards event,
    Emitter<FlashcardsState> emit,
  ) async {
    emit(state.copyWith(status: FlashcardsStatus.loading));
    try {
      // Get Settings
      final levelKey = _settingsRepository.gameLevel;
      final categories = _settingsRepository.defaultCategories;

      // Get Level Info
      final level = gameLevels.firstWhere(
        (l) => l.key == levelKey,
        orElse: () => gameLevels[2], // Default to medium
      );

      final questions = await _wordRepository.getFlashcardQuestions(
        _questionsPerGame,
        categories,
        level.minLength,
        level.maxLength,
      );
      if (questions.isEmpty) {
        emit(state.copyWith(status: FlashcardsStatus.error));
        return;
      }
      emit(
        state.copyWith(
          status: FlashcardsStatus.question,
          questions: questions,
          currentIndex: 0,
          score: 0,
          selectedAnswer: null,
          isCorrect: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: FlashcardsStatus.error));
    }
  }

  Future<void> _onCheckAnswer(
    CheckAnswer event,
    Emitter<FlashcardsState> emit,
  ) async {
    if (state.status != FlashcardsStatus.question) return;

    final question = state.currentQuestion!;
    final validAnswer = question['targetWord'] as String;
    final isCorrect = event.answer == validAnswer;

    if (isCorrect) {
      // Award Points
      await _statisticsRepository.addPoints(_pointsPerCorrect);
      // Mark as learnt/mastered? Maybe not automatically, just practice.
    }

    emit(
      state.copyWith(
        status: FlashcardsStatus.answered,
        selectedAnswer: event.answer,
        isCorrect: isCorrect,
        score: isCorrect ? state.score + 1 : state.score,
      ),
    );
  }

  void _onNextQuestion(NextQuestion event, Emitter<FlashcardsState> emit) {
    if (state.currentIndex >= state.questions.length - 1) {
      emit(state.copyWith(status: FlashcardsStatus.finished));
    } else {
      emit(
        state.copyWith(
          status: FlashcardsStatus.question,
          currentIndex: state.currentIndex + 1,
          selectedAnswer: null,
          isCorrect: null,
        ),
      );
    }
  }
}
