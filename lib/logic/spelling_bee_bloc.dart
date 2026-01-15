import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';
import '../data/settings_repository.dart';
import '../data/game_levels.dart';

import '../config/economy_constants.dart';

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

class RequestHint extends SpellingBeeEvent {}

// State
enum SpellingStatus { initial, loading, playing, correct, incorrect, finished }

class SpellingBeeState extends Equatable {
  final SpellingStatus status;
  final List<String> words;
  final int currentIndex;
  final int score;
  final String currentInput;
  final bool isTtsSpeaking;
  final String hintText;
  final String definition;
  final int hintsUsed;
  final String? message;

  const SpellingBeeState({
    this.status = SpellingStatus.initial,
    this.words = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.currentInput = '',
    this.isTtsSpeaking = false,
    this.hintText = '',
    this.definition = '',
    this.hintsUsed = 0,
    this.message,
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
    String? hintText,
    String? definition,
    int? hintsUsed,
    String? message,
  }) {
    return SpellingBeeState(
      status: status ?? this.status,
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      currentInput: currentInput ?? this.currentInput,
      isTtsSpeaking: isTtsSpeaking ?? this.isTtsSpeaking,
      hintText: hintText ?? this.hintText,
      definition: definition ?? this.definition,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    words,
    currentIndex,
    score,
    currentInput,
    isTtsSpeaking,
    hintText,
    definition,
    hintsUsed,
    message,
  ];
}

// Bloc
class SpellingBeeBloc extends Bloc<SpellingBeeEvent, SpellingBeeState> {
  final WordRepository _wordRepository;
  final StatisticsRepository _statisticsRepository;
  final SettingsRepository _settingsRepository;
  final FlutterTts _flutterTts = FlutterTts();

  SpellingBeeBloc(
    this._wordRepository,
    this._statisticsRepository,
    this._settingsRepository,
  ) : super(const SpellingBeeState()) {
    on<StartSpellingGame>(_onStartGame);
    on<PlayAudio>(_onPlayAudio);
    on<SubmitSpelling>(_onSubmitSpelling);
    on<RequestHint>(_onRequestHint);

    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);

    // _flutterTts.setStartHandler(() {});
    // _flutterTts.setCompletionHandler(() {});
    _flutterTts.setErrorHandler((msg) {
      // print("TTS Error: $msg");
    });
  }

  Future<void> _onStartGame(
    StartSpellingGame event,
    Emitter<SpellingBeeState> emit,
  ) async {
    emit(state.copyWith(status: SpellingStatus.loading));

    try {
      // Get Settings
      final levelKey = _settingsRepository.gameLevel;
      final categories = _settingsRepository.defaultCategories;

      // Get Level Info
      final level = gameLevels.firstWhere(
        (l) => l.key == levelKey,
        orElse: () => gameLevels[2], // Default to medium
      );

      final words = await _wordRepository.getWords(
        categories,
        level.minLength,
        level.maxLength,
      );
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
          hintText: '',
          definition: '',
          hintsUsed: 0,
          message: null,
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

  Future<void> _onRequestHint(
    RequestHint event,
    Emitter<SpellingBeeState> emit,
  ) async {
    if (state.status != SpellingStatus.playing &&
        state.status != SpellingStatus.incorrect) {
      return;
    }

    // Check funds
    final success = await _statisticsRepository.deductPoints(
      EconomyConstants.hintCost,
    );
    if (!success) {
      emit(state.copyWith(message: "Not enough diamonds for hint!"));
      // Clear message after delay? UI can handle it or we null it on next action
      return;
    }

    final target = state.targetWord;

    // 1. Show Definition first
    if (state.definition.isEmpty) {
      final meanings = await _wordRepository.getWordMeanings(target);
      String def = "No definition found.";
      if (meanings != null && meanings.definitions.isNotEmpty) {
        def = meanings.definitions.first;
      }
      emit(
        state.copyWith(
          definition: def,
          hintsUsed: state.hintsUsed + 1,
          message: "Definition revealed! (-${EconomyConstants.hintCost} 💎)",
        ),
      );
      return;
    }

    // 2. Reveal Letters
    // Hint text format: "_ _ _ _"
    // We want to reveal one more letter than currently shown.
    // If empty, start with empty list of underscores? Or reveal index 0?
    // Let's assume hintText is just the revealed part "S _ _ _ _"

    // Initialize if empty
    String currentHint = state.hintText;
    if (currentHint.isEmpty) {
      currentHint = List.filled(target.length, '_').join(' ');
    }

    // Parse current hint
    final chars = currentHint.split(' ');

    // Find first underscore
    int indexToReveal = -1;
    for (int i = 0; i < chars.length; i++) {
      if (chars[i] == '_') {
        indexToReveal = i;
        break;
      }
    }

    if (indexToReveal == -1) {
      emit(state.copyWith(message: "Word fully revealed!"));
      return;
    }

    chars[indexToReveal] = target[indexToReveal].toUpperCase();
    final newHint = chars.join(' ');

    emit(
      state.copyWith(
        hintText: newHint,
        hintsUsed: state.hintsUsed + 1,
        message: "Letter revealed! (-${EconomyConstants.hintCost} 💎)",
      ),
    );
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
          hintText: '',
          definition: '',
          message: null,
          // hintsUsed resets? Or accum? Usually reset per word.
          hintsUsed: 0,
        ),
      );
      add(const PlayAudio(slow: false));
    }
  }
}
