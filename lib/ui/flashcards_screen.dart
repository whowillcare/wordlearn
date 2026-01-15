import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/flashcards_bloc.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';
import '../data/settings_repository.dart';
import '../utils/category_utils.dart';
import 'components/diamond_display.dart';
import 'components/points_action_dialog.dart';
import 'components/glass_container.dart';
import 'components/word_detail_dialog.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlashcardsBloc(
        context.read<WordRepository>(),
        context.read<StatisticsRepository>(),
        context.read<SettingsRepository>(),
      )..add(StartFlashcards()),
      child: const FlashcardsView(),
    );
  }
}

class FlashcardsView extends StatelessWidget {
  const FlashcardsView({super.key});

  void _showGameInfo(BuildContext context) {
    // Basic info dialog to match others
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Game Info",
          style: TextStyle(color: Colors.deepPurple),
        ),
        content: const Text(
          "Flashcards: Read the definition or synonym and choose the correct word. Earn points for correct answers!",
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

  @override
  Widget build(BuildContext context) {
    final settings = context
        .read<
          SettingsRepository
        >(); // Read once for title (or watch if it changes dynamically?) - Watch is better
    // Actually, settings won't change mid-game usually, but let's use watch if we want to be safe, or just read.
    // The screen is stateless, so we can't easily watch without building again.
    // Let's use Builder or just assume context.watch if we convert to stateful?
    // It is Stateless. context.watch<SettingsRepository>() works fine in build.

    // Re-getting settings for display
    // Note: The previous BlocProvider wrapping is in parent widget.
    // We can just use context.watch

    final categories = settings.defaultCategories;
    final catText = categories.isEmpty
        ? 'ALL'
        : categories.length > 1
        ? 'MIXED'
        : CategoryUtils.formatName(categories.first).toUpperCase();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () => _showGameInfo(context),
          child: Column(
            children: [
              const Text(
                "Flashcards",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                "${settings.gameLevel.toUpperCase()} • $catText",
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: StreamBuilder<int>(
              stream: context.read<StatisticsRepository>().pointsStream,
              builder: (context, snapshot) {
                final points =
                    snapshot.data ??
                    context.read<StatisticsRepository>().currentPoints;
                return DiamondDisplay(
                  points: points,
                  onTap: () => PointsActionDialog.show(context),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF880E4F), Color(0xFF1A237E)], // Pink to Deep Blue
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BlocConsumer<FlashcardsBloc, FlashcardsState>(
          listener: (context, state) {
            // Can add sound effects here
          },
          builder: (context, state) {
            if (state.status == FlashcardsStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (state.status == FlashcardsStatus.error) {
              return const Center(
                child: Text(
                  "Error loading cards. Try checking your library.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            if (state.status == FlashcardsStatus.finished) {
              return Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "🎉 Finished! 🎉",
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Score: ${state.score} / ${state.questions.length}",
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text("Back to Menu"),
                      ),
                    ],
                  ),
                ),
              );
            }

            final question = state.currentQuestion;
            if (question == null) return const SizedBox.shrink();

            final targetWord = question['targetWord'] as String;
            final definition = question['questionText'] as String;
            final type = question['questionType'] as String;
            final options = question['options'] as List<String>;

            return SafeArea(
              child: Column(
                children: [
                  // Progress
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: LinearProgressIndicator(
                      value: (state.currentIndex + 1) / state.questions.length,
                      backgroundColor: Colors.white24,
                      color: Colors.amberAccent,
                    ),
                  ),

                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: GlassContainer(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                type == 'definition' ? "DEFINITION" : "SYNONYM",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  letterSpacing: 2,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                definition,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ListView(
                        primary:
                            false, // Let parent handle scrolling if needed, but here it's bounded by Expanded
                        children: [
                          ...options.map((option) {
                            final isSelected = state.selectedAnswer == option;
                            final isCorrect = option == targetWord;

                            Color color = Colors.white.withOpacity(0.1);
                            if (state.status == FlashcardsStatus.answered) {
                              if (isCorrect)
                                color = Colors.green.withOpacity(0.6);
                              if (isSelected && !isCorrect)
                                color = Colors.red.withOpacity(0.6);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    if (state.status ==
                                        FlashcardsStatus.answered) {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            WordDetailDialog(word: option),
                                      );
                                    } else {
                                      context.read<FlashcardsBloc>().add(
                                        CheckAnswer(option),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          option.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        if (state.status ==
                                            FlashcardsStatus.answered)
                                          const Text(
                                            "(Tap for info)",
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          if (state.status == FlashcardsStatus.answered)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => context
                                    .read<FlashcardsBloc>()
                                    .add(NextQuestion()),
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text("NEXT"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
