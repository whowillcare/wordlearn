import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/word_repository.dart';
import '../../logic/library_bloc.dart';
import 'package:intl/intl.dart';
import 'word_detail_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_utils.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(
        0xFFFAEBD7,
      ), // Linen/Antique White for "Paper/Tool" feel
      appBar: AppBar(
        title: Text(
          l10n.library,
          style: const TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        actions: [
          BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, state) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.deepPurple),
                tooltip: l10n.filter,
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
                      child: Text(l10n.favoritesOnly),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'APP_FILTER_ALL',
                      child: Text(l10n.allCategories),
                    ),
                    ...categories.map(
                      (c) => PopupMenuItem(
                        value: c,
                        child: Text(CategoryUtils.formatName(c!)),
                      ),
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
                    Icons.auto_stories,
                    size: 80,
                    color: Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.allWords.isEmpty
                        ? l10n.noWordsLearnt
                        : l10n.noResults,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
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
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  context.read<LibraryBloc>().add(DeleteWord(word));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.removed} "$word"'),
                      action: SnackBarAction(
                        label: l10n.undo,
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
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isFav
                          ? Colors.amber[100]
                          : Colors.grey[100],
                      child: Text(
                        word[0].toUpperCase(),
                        style: TextStyle(
                          color: isFav ? Colors.deepOrange : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      word.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${CategoryUtils.formatName(category)} • ${DateFormat.yMMMd().format(dateAdded)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WordDetailScreen(word: word),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        color: isFav ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        context.read<LibraryBloc>().add(
                          ToggleFavorite(word, !isFav),
                        );
                      },
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
