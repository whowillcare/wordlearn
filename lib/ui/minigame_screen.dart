import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/minigame_bloc.dart';
import '../data/word_repository.dart';
import '../data/settings_repository.dart';
import '../data/statistics_repository.dart';
import '../l10n/app_localizations.dart';
import 'components/glass_container.dart';
import 'components/diamond_display.dart';
import 'components/points_action_dialog.dart';
import '../config/economy_constants.dart';
import '../data/game_levels.dart';
import '../utils/category_utils.dart';

class MiniGameScreen extends StatelessWidget {
  const MiniGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MiniGameBloc(
        context.read<WordRepository>(),
        context.read<SettingsRepository>(),
        context.read<StatisticsRepository>(),
      )..add(StartNewGame()),
      child: const MiniGameView(),
    );
  }
}

class MiniGameView extends StatefulWidget {
  const MiniGameView({super.key});

  @override
  State<MiniGameView> createState() => _MiniGameViewState();
}

class _MiniGameViewState extends State<MiniGameView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showGameInfo(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    final levelKey = settings.gameLevel;
    final level = gameLevels.firstWhere(
      (l) => l.key == levelKey,
      orElse: () => gameLevels[2],
    );
    final categories = settings.defaultCategories;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Game Configuration",
          style: TextStyle(color: Colors.deepPurple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Categories: ${categories.isEmpty ? 'All' : categories.map((c) => CategoryUtils.formatName(c)).join(', ')}",
            ),
            const SizedBox(height: 8),
            Text("Level: ${level.name}"),
            const SizedBox(height: 8),
            Text(
              "Word Length: ${level.minLength}${level.maxLength != null ? '-${level.maxLength}' : '+'} letters",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _confirmHint(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Use Hint?"),
        content: Text(
          "Reveal a letter for ${EconomyConstants.hintCost} diamonds?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MiniGameBloc>().add(RequestHint());
            },
            child: const Text("Reveal (-5 💎)"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsRepository>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () => _showGameInfo(context),
          child: Column(
            children: [
              Text(
                l10n.minigames,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                "${settings.gameLevel.toUpperCase()} • ${settings.defaultCategories.isEmpty
                    ? 'ALL'
                    : settings.defaultCategories.length > 1
                    ? 'MIXED'
                    : CategoryUtils.formatName(settings.defaultCategories.first).toUpperCase()}",
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        actions: [
          StreamBuilder<int>(
            stream: context.read<StatisticsRepository>().pointsStream,
            builder: (context, snapshot) {
              final points =
                  snapshot.data ??
                  context.read<StatisticsRepository>().currentPoints;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DiamondDisplay(
                  points: points,
                  onTap: () => PointsActionDialog.show(context),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BlocConsumer<MiniGameBloc, MiniGameState>(
          listener: (context, state) {
            if (state.status == GameStatus.won) {
              _controller.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Correct! Well done!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state.message.isNotEmpty &&
                state.status != GameStatus.won &&
                !state.message.startsWith('Added')) {
              // Don't show snackbar for library add (handled by button text change or separate toast)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == GameStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (state.status == GameStatus.lost) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Error loading game.',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<MiniGameBloc>().add(StartNewGame()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final isWon = state.status == GameStatus.won;
            final isLearnt = state.isWordLearnt;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60), // AppBar spacer
                    // Game Area
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'UNSCRAMBLE',
                            style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isWon
                                ? state.targetWord.toUpperCase()
                                : state.scrambledWord.toUpperCase(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: isWon ? Colors.greenAccent : Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // HINT TEXT DISPLAY
                          if (state.hintText.isNotEmpty && !isWon) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Starts with: ${state.hintText.toUpperCase()}...',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],

                          const SizedBox(height: 30),
                          if (!isWon)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.shuffle,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => context
                                      .read<MiniGameBloc>()
                                      .add(ShuffleLetters()),
                                  tooltip: 'Shuffle Letters',
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.amberAccent,
                                  ),
                                  onPressed: () => _confirmHint(context),
                                  tooltip:
                                      'Get Hint (-${EconomyConstants.hintCost} 💎)',
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Input Field
                    if (!isWon)
                      TextField(
                        controller: _controller,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'TYPE HERE',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            context.read<MiniGameBloc>().add(
                              SubmitGuess(value),
                            );
                          }
                        },
                      ),

                    const SizedBox(height: 20),

                    // Buttons
                    if (isWon) ...[
                      // Add to Library Button
                      OutlinedButton.icon(
                        onPressed: isLearnt
                            ? null
                            : () {
                                context.read<MiniGameBloc>().add(
                                  AddToLibrary(),
                                );
                              },
                        icon: Icon(
                          isLearnt ? Icons.check : Icons.library_add,
                          color: Colors.white,
                        ),
                        label: Text(
                          isLearnt ? 'ADDED TO LIBRARY' : 'ADD TO LIBRARY',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white54),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<MiniGameBloc>().add(StartNewGame());
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('NEXT WORD'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black87,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                context.read<MiniGameBloc>().add(SkipWord());
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(color: Colors.white30),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('SKIP'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_controller.text.isNotEmpty) {
                                  context.read<MiniGameBloc>().add(
                                    SubmitGuess(_controller.text),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepPurple,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              child: const Text('CHECK'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
