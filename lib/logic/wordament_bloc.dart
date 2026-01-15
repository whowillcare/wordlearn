import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';

// Events
abstract class WordamentEvent extends Equatable {
  const WordamentEvent();
  @override
  List<Object> get props => [];
}

class StartGame extends WordamentEvent {}

class ExtendTime extends WordamentEvent {}

class DragStart extends WordamentEvent {
  final int index;
  const DragStart(this.index);
}

class DragUpdate extends WordamentEvent {
  final int index;
  const DragUpdate(this.index);
}

class DragEnd extends WordamentEvent {}

class Tick extends WordamentEvent {}

// State
enum WordamentStatus { initial, loading, playing, finished }

class WordamentState extends Equatable {
  final WordamentStatus status;
  final List<String> grid;
  final List<int> currentPath;
  final Set<String> foundWords;
  final Set<String> allPossibleWords; // To show stats at end
  final int score;
  final int timeLeft;
  final String currentWord; // Word being formed visually
  final String? errorMessage;

  const WordamentState({
    this.status = WordamentStatus.initial,
    this.grid = const [],
    this.currentPath = const [],
    this.foundWords = const {},
    this.allPossibleWords = const {},
    this.score = 0,
    this.timeLeft = 120,
    this.currentWord = '',
    this.errorMessage,
  });

  WordamentState copyWith({
    WordamentStatus? status,
    List<String>? grid,
    List<int>? currentPath,
    Set<String>? foundWords,
    Set<String>? allPossibleWords,
    int? score,
    int? timeLeft,
    String? currentWord,
    String? errorMessage,
  }) {
    return WordamentState(
      status: status ?? this.status,
      grid: grid ?? this.grid,
      currentPath: currentPath ?? this.currentPath,
      foundWords: foundWords ?? this.foundWords,
      allPossibleWords: allPossibleWords ?? this.allPossibleWords,
      score: score ?? this.score,
      timeLeft: timeLeft ?? this.timeLeft,
      currentWord: currentWord ?? this.currentWord,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    grid,
    currentPath,
    foundWords,
    allPossibleWords,
    score,
    timeLeft,
    currentWord,
    errorMessage,
  ];
}

// Bloc
class WordamentBloc extends Bloc<WordamentEvent, WordamentState> {
  final WordRepository _wordRepository;
  final StatisticsRepository _statisticsRepository;
  Set<String>? _dictionary; // Cache

  // Standard Boggle Dice (New Version)
  static final List<String> _dice = [
    'AAEEGN',
    'ABBJOO',
    'ACHOPS',
    'AFFKPS',
    'AOOTTW',
    'CIMOTU',
    'DEILRX',
    'DELRVY',
    'DISTTY',
    'EEGHNW',
    'EEINSU',
    'EHRTVW',
    'EIOSST',
    'ELRTTY',
    'HIMNQU',
    'HLNNRZ',
  ];

  WordamentBloc(this._wordRepository, this._statisticsRepository)
    : super(const WordamentState()) {
    on<StartGame>(_onStartGame);
    on<ExtendTime>(_onExtendTime);
    on<DragStart>(_onDragStart);
    on<DragUpdate>(_onDragUpdate);
    on<DragEnd>(_onDragEnd);
    on<Tick>(_onTick);
  }

  Future<void> _onStartGame(
    StartGame event,
    Emitter<WordamentState> emit,
  ) async {
    emit(state.copyWith(status: WordamentStatus.loading));

    if (_dictionary == null) {
      _dictionary = await _wordRepository.getAllWords(onlyCommon: true);
    }

    // Generate Grid
    final grid = _generateGrid();

    // Solve Board
    final possible = _solveBoard(grid, _dictionary!);

    emit(
      state.copyWith(
        status: WordamentStatus.playing,
        grid: grid,
        allPossibleWords: possible,
        foundWords: {},
        score: 0,
        timeLeft: 120,
        currentPath: [],
        currentWord: '',
      ),
    );
  }

  List<String> _generateGrid() {
    List<String> grid = [];
    final random = Random();
    List<String> shuffledDice = List.from(_dice)..shuffle(random);

    for (String die in shuffledDice) {
      String char = die[random.nextInt(die.length)];
      if (char == 'Q') char = 'Qu'; // Handle Qu
      grid.add(char);
    }
    return grid;
  }

  void _onDragStart(DragStart event, Emitter<WordamentState> emit) {
    if (state.status != WordamentStatus.playing) return;
    emit(
      state.copyWith(
        currentPath: [event.index],
        currentWord: state.grid[event.index],
      ),
    );
  }

  void _onDragUpdate(DragUpdate event, Emitter<WordamentState> emit) {
    if (state.status != WordamentStatus.playing) return;
    if (state.currentPath.isEmpty) return;

    final last = state.currentPath.last;
    final current = event.index;

    // Must be neighbor and not already in path
    if (state.currentPath.contains(current)) {
      // Allow backtracking? Usually user just lifts finger.
      // Or if they go back to previous cell, pop the last one?
      if (state.currentPath.length > 1 &&
          state.currentPath[state.currentPath.length - 2] == current) {
        // Backtracked
        final newPath = List<int>.from(state.currentPath)..removeLast();
        emit(
          state.copyWith(
            currentPath: newPath,
            currentWord: _pathToString(newPath),
          ),
        );
      }
      return;
    }

    if (_isNeighbor(last, current)) {
      final newPath = List<int>.from(state.currentPath)..add(current);
      emit(
        state.copyWith(
          currentPath: newPath,
          currentWord: _pathToString(newPath),
        ),
      );
    }
  }

  void _onDragEnd(DragEnd event, Emitter<WordamentState> emit) {
    if (state.status != WordamentStatus.playing) return;

    final word = state.currentWord.toLowerCase();

    if (word.length >= 3 &&
        !state.foundWords.contains(word) &&
        state.allPossibleWords.contains(word)) {
      final newScore = state.score + _calculateScore(word);
      final newFound = Set<String>.from(state.foundWords)..add(word);

      emit(
        state.copyWith(
          foundWords: newFound,
          score: newScore,
          currentPath: [],
          currentWord:
              '', // Clear immediately? Or show "Found!" feedback then clear?
          // UI can handle "last found" animation.
        ),
      );
    } else {
      emit(state.copyWith(currentPath: [], currentWord: ''));
    }
  }

  Future<void> _onExtendTime(
    ExtendTime event,
    Emitter<WordamentState> emit,
  ) async {
    const cost = 30; // Cost to extend
    final success = await _statisticsRepository.deductPoints(cost);
    if (success) {
      emit(
        state.copyWith(
          status: WordamentStatus.playing,
          timeLeft: state.timeLeft + 30, // Add 30s
        ),
      );
    } else {
      // Show error
      emit(state.copyWith(errorMessage: "Not enough diamonds!"));
      // Clear error after a bit? Or UI consumes it.
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(errorMessage: null));
    }
  }

  void _onTick(Tick event, Emitter<WordamentState> emit) {
    if (state.status != WordamentStatus.playing) return;
    if (state.timeLeft > 0) {
      emit(state.copyWith(timeLeft: state.timeLeft - 1));
    } else {
      emit(
        state.copyWith(
          status: WordamentStatus.finished,
          currentPath: [],
          currentWord: '',
        ),
      );
    }
  }

  // Helpers
  String _pathToString(List<int> path) {
    return path.map((i) => state.grid[i]).join('');
  }

  bool _isNeighbor(int i1, int i2) {
    final x1 = i1 % 4;
    final y1 = i1 ~/ 4;
    final x2 = i2 % 4;
    final y2 = i2 ~/ 4;
    return (x1 - x2).abs() <= 1 && (y1 - y2).abs() <= 1;
  }

  int _calculateScore(String word) {
    // Simple Boggle scoring
    int len = word.length;
    if (len <= 2) return 0; // Should be handled by valid check
    if (len <= 4) return 1;
    if (len == 5) return 2;
    if (len == 6) return 3;
    if (len == 7) return 5;
    return 11;
  }

  // Solver
  Set<String> _solveBoard(List<String> grid, Set<String> dictionary) {
    Set<String> found = {};
    for (int i = 0; i < 16; i++) {
      _dfs(i, [i], grid[i], grid, dictionary, found);
    }
    return found;
  }

  void _dfs(
    int idx,
    List<int> visited,
    String currentWord,
    List<String> grid,
    Set<String> dictionary,
    Set<String> found,
  ) {
    // Pruning: Check if currentWord is a prefix of ANY word in dictionary.
    // This is slow without a Trie.
    // For MVP with ~4000 words, iterating dictionary might be ok?
    // Or create a prefix set on the fly?
    // Or just limit depth?

    // Optimization: Filter dictionary to only words starting with current letter initially?

    // Let's implement a rudimentary prefix check if performance is bad.
    // Actually, if dictionary is small (4k), `dictionary.any((w) => w.startsWith(currentWord.toLowerCase()))` is O(N).
    // 16 start points * many paths... might be slow.

    // Better: Build a Trie in Bloc constructor?
    // Let's rely on simple recursion constraint for now (length <= 16).
    // And maybe simplified "is prefix" check.

    // Actually, standard Boggle is 3 mins. We pre-calc.
    // Even 5 seconds load time is fine.

    if (currentWord.length >= 3) {
      if (dictionary.contains(currentWord.toLowerCase())) {
        found.add(currentWord.toLowerCase());
      }
    }

    // Optim: If no word in dictionary starts with currentWord, return.
    // We can just query `dictionary` once for prefixes?
    // Let's skip optimization for MVP unless it hangs.

    // Neighbors
    final x = idx % 4;
    final y = idx ~/ 4;

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < 4 && ny >= 0 && ny < 4) {
          final nIdx = ny * 4 + nx;
          if (!visited.contains(nIdx)) {
            if (currentWord.length < 8) {
              // Soft limit to prevent explosion? Boggle words can be long.
              _dfs(
                nIdx,
                [...visited, nIdx],
                currentWord + grid[nIdx],
                grid,
                dictionary,
                found,
              );
            }
          }
        }
      }
    }
  }
}
