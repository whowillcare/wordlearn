import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';
import '../data/game_levels.dart';
import '../logic/game_bloc.dart';
import '../logic/game_state.dart';
import '../data/settings_repository.dart';
import 'components/guess_grid.dart';
import 'components/keyboard.dart';
import '../l10n/app_localizations.dart';

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

  String _getCategoryTitle(BuildContext context) {
    // localized later if categories become keys, currently dynamic strings
    if (widget.categories.length == 1) {
      if (widget.categories.first == 'all') return 'Everything';
      return widget
          .categories
          .first; // Capitalize first letter logic can be added here
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
        // "Low Key" Theme Background
        backgroundColor: const Color(0xFFE6E1F4), // Matte Light Purple
        appBar: AppBar(
          backgroundColor: const Color(0xFFE6E1F4),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.deepPurple,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Column(
            children: [
              Text(
                _getCategoryTitle(context).toUpperCase(),
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                widget.level.key.toUpperCase(),
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          actions: [
            // Score Display
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  // Placeholder for score if exist in state, else standard level info
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${state.categoryWordCount ?? '?'} Words",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: BlocConsumer<GameBloc, GameState>(
          listener: (context, state) {
            if (state.status == GameStatus.won) {
              _confettiController.play();
              _showVictoryDialog(context, state);
            } else if (state.status == GameStatus.lost) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.gameOver)),
              );
            }
          },
          builder: (context, state) {
            if (state.status == GameStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;
                final settings = context.read<SettingsRepository>();

                // Content Wrappers
                final gridSection = Center(
                  child: SingleChildScrollView(
                    child: GuessGrid(
                      guesses: state.guesses,
                      currentGuess: state.currentGuess,
                      targetWord: state.targetWord,
                      maxAttempts: state.level?.attempts ?? 6,
                    ),
                  ),
                );

                final controlsSection = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Power-up Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPowerUpButton(
                            context,
                            icon: Icons.lightbulb,
                            label: AppLocalizations.of(context)!.hint,
                            onTap: state.status == GameStatus.playing
                                ? () => context.read<GameBloc>().add(
                                    HintRequested(),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          _buildPowerUpButton(
                            context,
                            icon: Icons.shuffle,
                            label: AppLocalizations.of(context)!.shuffle,
                            // No op for now, just visual placeholder or future feature
                            onTap: null,
                          ),
                        ],
                      ),
                    ),

                    Keyboard(
                      letterStatus: state.letterStatus,
                      allowSpecialChars: settings.isSpecialCharsAllowed,
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
                    const SizedBox(height: 20),
                  ],
                );

                return Stack(
                  children: [
                    if (isLandscape)
                      Row(
                        children: [
                          Expanded(flex: 1, child: gridSection),
                          Expanded(flex: 1, child: controlsSection),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Expanded(child: gridSection),
                          controlsSection,
                        ],
                      ),

                    // Confetti
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

                    // Error Messages
                    if (state.errorMessage != null)
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 8),
                              ],
                            ),
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPowerUpButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: Icon(icon, size: 20, color: Colors.orangeAccent),
        label: Text(label),
      ),
    );
  }

  void _showVictoryDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (_) {
        // Re-wrap in BlocProvider.value to access the same Bloc instance
        return BlocProvider.value(
          value: context.read<GameBloc>(),
          child: Builder(
            builder: (dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'Victory! 🎉',
                  style: const TextStyle(color: Colors.deepOrange),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Based on: ${state.targetWord.toUpperCase()}'),
                    const SizedBox(height: 10),
                    // Future: Add definition or details here
                  ],
                ),
                actions: [
                  if (!state.isWordSaved)
                    TextButton.icon(
                      onPressed: () {
                        dialogContext.read<GameBloc>().add(
                          AddToLibraryRequested(),
                        );
                        // Force rebuild or visual update to show 'Saved'
                        // Since dialog is stateless in this quick impl, we rely on bloc listening
                        // But better UX is to close and show toast, or update state.
                        // For now, let's close and show toast.
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Word saved to Library!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bookmark_add),
                      label: Text(AppLocalizations.of(context)!.library),
                    ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Awesome'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
