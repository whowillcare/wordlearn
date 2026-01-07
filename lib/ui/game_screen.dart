import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';
import '../data/game_levels.dart';
import '../logic/game_bloc.dart';
import '../logic/game_state.dart';
import '../data/settings_repository.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';
import '../data/game_levels.dart';
import 'components/guess_grid.dart';
import 'components/keyboard.dart';
import 'package:confetti/confetti.dart';

class GameScreen extends StatefulWidget {
  final List<String> categories;
  final GameLevel level;

  const GameScreen({super.key, required this.categories, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String get _categoryTitle {
    if (widget.categories.length == 1) {
      if (widget.categories.first == 'all') return 'Everything';
      return widget.categories.first;
    }
    return '${widget.categories.length} Categories';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc(
        RepositoryProvider.of<WordRepository>(context),
        RepositoryProvider.of<StatisticsRepository>(context),
        RepositoryProvider.of<SettingsRepository>(context),
      )..add(GameStarted(level: widget.level, categories: widget.categories)),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_categoryTitle (${widget.level.name})'),
              BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  if (state.categoryWordCount == null) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${state.categoryWordCount} words',
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ],
          ),
          actions: [
            BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.lightbulb),
                  onPressed: state.status == GameStatus.playing
                      ? () => context.read<GameBloc>().add(HintRequested())
                      : null,
                );
              },
            ),
            // (Solution button removed as event was removed)
          ],
        ),
        body: BlocConsumer<GameBloc, GameState>(
          listener: (context, state) {
            if (state.status == GameStatus.won) {
              _confettiController.play();
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<GameBloc>(),
                  child: BlocBuilder<GameBloc, GameState>(
                    builder: (context, state) {
                      return AlertDialog(
                        title: const Text('Victory! 🎉'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'You guessed the word: ${state.targetWord.toUpperCase()}',
                            ),
                          ],
                        ),
                        actions: [
                          if (!state.isWordSaved)
                            TextButton.icon(
                              onPressed: () {
                                context.read<GameBloc>().add(
                                  AddToLibraryRequested(),
                                );
                              },
                              icon: const Icon(Icons.bookmark_add),
                              label: const Text('ADD TO LIBRARY'),
                            )
                          else
                            TextButton.icon(
                              onPressed: null,
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              label: const Text(
                                'SAVED',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('AWESOME'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            } else if (state.status == GameStatus.lost) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Game Over!')));
            }
          },
          builder: (context, state) {
            if (state.status == GameStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: GuessGrid(
                            guesses: state.guesses,
                            currentGuess: state.currentGuess,
                            targetWord: state.targetWord,
                            maxAttempts: state.level?.attempts ?? 6,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Keyboard(
                        letterStatus: state.letterStatus,
                        onKeyTap: (letter) {
                          context.read<GameBloc>().add(GuessEntered(letter));
                        },
                        onDeleteTap: () {
                          context.read<GameBloc>().add(GuessDeleted());
                        },
                        onEnterTap: () {
                          context.read<GameBloc>().add(GuessSubmitted());
                        },
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                    ],
                  ),
                ),
                if (state.errorMessage != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
