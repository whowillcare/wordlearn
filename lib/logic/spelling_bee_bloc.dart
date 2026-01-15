import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';

// Events
abstract class SpellingBeeEvent extends Equatable {
  const SpellingBeeEvent();
  @override
  List<Object> get props => [];
}

class StartSpellingGame extends SpellingBeeEvent {}

class PlayAudio extends SpellingBeeEvent {
  final bool slow;
  const PlayAudio({this.slow = false});
}

class SubmitSpelling extends SpellingBeeEvent {
  final String text;
  const SubmitSpelling(this.text);
}

class NextSpellingWord extends SpellingBeeEvent {}

// State
enum SpellingStatus { initial, loading, playing, correct, incorrect, finished }

class SpellingBeeState extends Equatable {
  final SpellingStatus status;
  final List<String> words;
  final int currentIndex;
  final int score;
  final String currentInput;
  final bool isTtsSpeaking;

  const SpellingBeeState({
    this.status = SpellingStatus.initial,
    this.words = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.currentInput = '',
    this.isTtsSpeaking = false,
  });

  String get targetWord => words.isNotEmpty && currentIndex < words.length
      ? words[currentIndex]
      : '';

  SpellingBeeState copyWith({
    SpellingStatus? status,
    List<String>? words,
    int? currentIndex,
    int? score,
    String? currentInput,
    bool? isTtsSpeaking,
  }) {
    return SpellingBeeState(
      status: status ?? this.status,
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      currentInput: currentInput ?? this.currentInput,
      isTtsSpeaking: isTtsSpeaking ?? this.isTtsSpeaking,
    );
  }

  @override
  List<Object> get props => [
    status,
    words,
    currentIndex,
    score,
    currentInput,
    isTtsSpeaking,
  ];
}

// Bloc
class SpellingBeeBloc extends Bloc<SpellingBeeEvent, SpellingBeeState> {
  final WordRepository _wordRepository;
  final StatisticsRepository _statisticsRepository;
  final FlutterTts _flutterTts = FlutterTts();

  SpellingBeeBloc(this._wordRepository, this._statisticsRepository)
    : super(const SpellingBeeState()) {
    on<StartSpellingGame>(_onStartGame);
    on<PlayAudio>(_onPlayAudio);
    on<SubmitSpelling>(_onSubmitSpelling);
    on<NextSpellingWord>(_onNextWord);

    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      // Could emit speaking state
    });

    _flutterTts.setCompletionHandler(() {
      // Could emit stopped speaking state
    });

    _flutterTts.setErrorHandler((msg) {
      // Log error
    });
  }

  Future<void> _onStartGame(
    StartSpellingGame event,
    Emitter<SpellingBeeState> emit,
  ) async {
    emit(state.copyWith(status: SpellingStatus.loading));

    // Get 5 random words, prefer longer ones for spelling bee?
    // Using existing repository method
    try {
      final words = await _wordRepository.getWords(
        ['all'],
        5,
        8,
      ); // 8 letters max hard
      // Shuffle and take 5
      words.shuffle();
      final selectedWords = words.take(5).toList();

      if (selectedWords.isEmpty) {
        // Fallback
        selectedWords.addAll(['spelling', 'bee', 'flutter', 'dart', 'code']);
      }

      emit(
        state.copyWith(
          status: SpellingStatus.playing,
          words: selectedWords,
          currentIndex: 0,
          score: 0,
          currentInput: '',
        ),
      );

      // Auto-play first word
      add(const PlayAudio(slow: false));
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _onPlayAudio(
    PlayAudio event,
    Emitter<SpellingBeeState> emit,
  ) async {
    final word = state.targetWord;
    if (word.isEmpty) return;

    await _flutterTts.setSpeechRate(event.slow ? 0.2 : 0.5);
    await _flutterTts.speak(word);
  }

  Future<void> _onSubmitSpelling(
    SubmitSpelling event,
    Emitter<SpellingBeeState> emit,
  ) async {
    if (state.status != SpellingStatus.playing &&
        state.status != SpellingStatus.incorrect)
      return;

    final input = event.text.trim().toLowerCase();
    final target = state.targetWord.toLowerCase();

    if (input == target) {
      await _statisticsRepository.addPoints(10); // 10 points for spelling
      emit(
        state.copyWith(
          status: SpellingStatus.correct,
          score: state.score + 10,
          currentInput: input,
        ),
      );
    } else {
      emit(
        state.copyWith(status: SpellingStatus.incorrect, currentInput: input),
      );
    }
  }

  void _onNextWord(NextSpellingWord event, Emitter<SpellingBeeState> emit) {
    if (state.currentIndex >= state.words.length - 1) {
      emit(state.copyWith(status: SpellingStatus.finished));
    } else {
      emit(
        state.copyWith(
          status: SpellingStatus.playing,
          currentIndex: state.currentIndex + 1,
          currentInput: '',
        ),
      );
      add(const PlayAudio(slow: false));
    }
  }
}
