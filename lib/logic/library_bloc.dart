import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/word_repository.dart';

// Events
abstract class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object?> get props => [];
}

class LoadLibrary extends LibraryEvent {}

class ToggleFavorite extends LibraryEvent {
  final String word;
  final bool isFavorite;
  const ToggleFavorite(this.word, this.isFavorite);
}

class DeleteWord extends LibraryEvent {
  final String word;
  const DeleteWord(this.word);
}

class UndoDeleteWord extends LibraryEvent {
  final String word;
  final String? category;
  final bool wasFavorite;
  const UndoDeleteWord(this.word, this.category, this.wasFavorite);
}

class FilterLibrary extends LibraryEvent {
  final String? category;
  final bool onlyFavorites;
  const FilterLibrary({this.category, this.onlyFavorites = false});
}

class SearchLibrary extends LibraryEvent {
  final String query;
  const SearchLibrary(this.query);
}

// State
class LibraryState extends Equatable {
  final List<Map<String, dynamic>> allWords;
  final List<Map<String, dynamic>> filteredWords;
  final bool isLoading;
  final String? selectedCategory;
  final bool showFavoritesOnly;
  final String searchQuery;

  const LibraryState({
    this.allWords = const [],
    this.filteredWords = const [],
    this.isLoading = true,
    this.selectedCategory,
    this.showFavoritesOnly = false,
    this.searchQuery = '',
  });

  LibraryState copyWith({
    List<Map<String, dynamic>>? allWords,
    List<Map<String, dynamic>>? filteredWords,
    bool? isLoading,
    String? selectedCategory,
    bool? showFavoritesOnly,
    String? searchQuery,
  }) {
    return LibraryState(
      allWords: allWords ?? this.allWords,
      filteredWords: filteredWords ?? this.filteredWords,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory:
          selectedCategory ??
          this.selectedCategory, // Allow nullable update? logic below handles it
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Custom copyWith to allow setting nullable category to null
  LibraryState copyWithCategory(
    String? category, {
    List<Map<String, dynamic>>? allWords,
    List<Map<String, dynamic>>? filteredWords,
    bool? isLoading,
    bool? showFavoritesOnly,
    String? searchQuery,
  }) {
    return LibraryState(
      allWords: allWords ?? this.allWords,
      filteredWords: filteredWords ?? this.filteredWords,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: category,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    allWords,
    filteredWords,
    isLoading,
    selectedCategory,
    showFavoritesOnly,
    searchQuery,
  ];
}

// Bloc
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final WordRepository _repository;

  LibraryBloc(this._repository) : super(const LibraryState()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<ToggleFavorite>(_onToggleFavorite);
    on<DeleteWord>(_onDeleteWord);
    on<UndoDeleteWord>(_onUndoDeleteWord);
    on<FilterLibrary>(_onFilterLibrary);
    on<SearchLibrary>(_onSearchLibrary);
  }

  Future<void> _onLoadLibrary(
    LoadLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final words = await _repository.getLearntWords();
    emit(
      state.copyWith(
        isLoading: false,
        allWords: words,
        filteredWords: _applyFilter(
          words,
          state.selectedCategory,
          state.showFavoritesOnly,
          state.searchQuery,
        ),
      ),
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<LibraryState> emit,
  ) async {
    await _repository.toggleFavorite(event.word, event.isFavorite);
    add(LoadLibrary()); // Refresh
  }

  Future<void> _onDeleteWord(
    DeleteWord event,
    Emitter<LibraryState> emit,
  ) async {
    await _repository.deleteLearntWord(event.word);
    add(LoadLibrary());
  }

  Future<void> _onUndoDeleteWord(
    UndoDeleteWord event,
    Emitter<LibraryState> emit,
  ) async {
    await _repository.addLearntWord(event.word, event.category ?? 'unknown');
    if (event.wasFavorite) {
      await _repository.toggleFavorite(event.word, true);
    }
    add(LoadLibrary());
  }

  void _onFilterLibrary(FilterLibrary event, Emitter<LibraryState> emit) {
    // Handling nullable category update properly
    final newCategory = event.category;
    // If event.category is null, does it mean "clear filter" or "keep same"?
    // Let's assume FilterLibrary passes the DESIRED state completely.

    // Actually, passing null for category usually means "All Categories".

    final filtered = _applyFilter(
      state.allWords,
      event.category,
      event.onlyFavorites,
      state.searchQuery,
    );

    emit(
      state.copyWithCategory(
        event.category,
        filteredWords: filtered,
        showFavoritesOnly: event.onlyFavorites,
      ),
    );
  }

  void _onSearchLibrary(SearchLibrary event, Emitter<LibraryState> emit) {
    final filtered = _applyFilter(
      state.allWords,
      state.selectedCategory,
      state.showFavoritesOnly,
      event.query,
    );
    emit(state.copyWith(searchQuery: event.query, filteredWords: filtered));
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> words,
    String? category,
    bool favoritesOnly,
    String query,
  ) {
    return words.where((w) {
      if (favoritesOnly && w['is_favorite'] != true) return false;
      if (category != null && w['category'] != category) return false;
      if (query.isNotEmpty &&
          !(w['word'] as String).toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }
}
