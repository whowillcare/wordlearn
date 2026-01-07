import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/word_repository.dart';
import '../../logic/library_bloc.dart';
import 'package:intl/intl.dart';
import 'word_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LibraryBloc(context.read<WordRepository>())..add(LoadLibrary()),
      child: const LibraryView(),
    );
  }
}

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, state) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  if (value == 'APP_FILTER_FAVS') {
                    context.read<LibraryBloc>().add(
                      FilterLibrary(
                        category: state.selectedCategory,
                        onlyFavorites: !state.showFavoritesOnly,
                      ),
                    );
                  } else if (value == 'APP_FILTER_ALL') {
                    context.read<LibraryBloc>().add(
                      const FilterLibrary(category: null, onlyFavorites: false),
                    );
                  } else {
                    // Specific category
                    context.read<LibraryBloc>().add(
                      FilterLibrary(
                        category: value,
                        onlyFavorites: state.showFavoritesOnly,
                      ),
                    );
                  }
                },
                itemBuilder: (context) {
                  // Get unique categories from allWords, not just filtered
                  final categories = state.allWords
                      .map((w) => w['category'] as String?)
                      .where((c) => c != null)
                      .toSet()
                      .toList();
                  categories.sort();

                  return [
                    CheckedPopupMenuItem(
                      checked: state.showFavoritesOnly,
                      value: 'APP_FILTER_FAVS',
                      child: const Text('Favorites Only'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'APP_FILTER_ALL',
                      child: Text('All Categories'),
                    ),
                    ...categories.map(
                      (c) => PopupMenuItem(value: c, child: Text(c!)),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.filteredWords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.allWords.isEmpty
                        ? 'No words learnt yet!'
                        : 'No results found.',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.filteredWords.length,
            itemBuilder: (context, index) {
              final wordData = state.filteredWords[index];
              final word = wordData['word'] as String;
              final category = wordData['category'] as String? ?? 'Unknown';
              final dateAdded = DateTime.fromMillisecondsSinceEpoch(
                wordData['date_added'] as int,
              );
              final isFav = wordData['is_favorite'] == true;

              return Dismissible(
                key: Key(word),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  context.read<LibraryBloc>().add(DeleteWord(word));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed "$word"'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          context.read<LibraryBloc>().add(
                            UndoDeleteWord(word, category, isFav),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(
                      word.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$category • ${DateFormat.yMMMd().format(dateAdded)}',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WordDetailScreen(word: word),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : null,
                          ),
                          onPressed: () {
                            context.read<LibraryBloc>().add(
                              ToggleFavorite(word, !isFav),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {
                            // Trigger deletion with Undo option
                            context.read<LibraryBloc>().add(DeleteWord(word));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Removed "$word"'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () {
                                    context.read<LibraryBloc>().add(
                                      UndoDeleteWord(word, category, isFav),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
