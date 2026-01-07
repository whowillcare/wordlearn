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
  final String category;
  final GameLevel level;

  const GameScreen({super.key, required this.category, required this.level});

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc(
        RepositoryProvider.of<WordRepository>(context),
        RepositoryProvider.of<StatisticsRepository>(context),
        RepositoryProvider.of<SettingsRepository>(context),
      )..add(GameStarted(level: widget.level, category: widget.category)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.category} (${widget.level.name})'),
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
            BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: state.status == GameStatus.playing
                      ? () => context.read<GameBloc>().add(SolutionRequested())
                      : null,
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<GameBloc, GameState>(
          listener: (context, state) {
            if (state.status == GameStatus.won) {
              _confettiController.play();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Victory! 🎉'),
                  content: Text(
                    'You guessed the word: ${state.targetWord.toUpperCase()}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('AWESOME'),
                    ),
                  ],
                ),
              );
            } else if (state.status == GameStatus.lost) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Game Over!')));
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
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
                          context.read<GameBloc>().add(LetterEntered(letter));
                        },
                        onDeleteTap: () {
                          context.read<GameBloc>().add(const LetterDeleted());
                        },
                        onEnterTap: () {
                          context.read<GameBloc>().add(const GuessSubmitted());
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
              ],
            );
          },
        ),
      ),
    );
  }
}
