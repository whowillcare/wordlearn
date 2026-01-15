import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/daily_challenge_bloc.dart';
import '../data/daily_challenge_repository.dart';
import '../data/word_repository.dart';
import 'game_screen.dart';
import '../data/game_levels.dart';
import 'components/diamond_display.dart';
import '../data/statistics_repository.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DailyChallengeBloc(
        DailyChallengeRepository(
          wordRepository: context.read<WordRepository>(),
        ),
      )..add(LoadDailyChallenge()),
      child: const DailyChallengeView(),
    );
  }
}

class DailyChallengeView extends StatefulWidget {
  const DailyChallengeView({super.key});

  @override
  State<DailyChallengeView> createState() => _DailyChallengeViewState();
}

class _DailyChallengeViewState extends State<DailyChallengeView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DailyChallengeBloc, DailyChallengeState>(
      listener: (context, state) async {
        if (state.status == DailyChallengeStatus.playing) {
          await _playNextWord(context, state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF2E3192), // Dark Blue Theme
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              "Daily Challenge",
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Future<void> _playNextWord(
    BuildContext context,
    DailyChallengeState state,
  ) async {
    if (state.challenge == null ||
        state.currentWordIndex >= state.challenge!.words.length)
      return;

    final word = state.challenge!.words[state.currentWordIndex];

    // We navigate to GameScreen and wait for result
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          categories: const ['daily'],
          level: gameLevels.firstWhere(
            (l) => l.key == 'classic',
          ), // Or a special 'daily' level
          targetWord: word,
        ),
      ),
    );

    if (!mounted) return;

    // Dispatch result
    context.read<DailyChallengeBloc>().add(
      WordCompleted(word, result ?? false),
    );

    // If returned (popped), Bloc processes result.
    // If not finished, it stays in Playing state and listener triggers again?
    // Wait, if state updates currentWordIndex, status remains playing.
    // Listener is called on state change.
    // If index incremented, listener fires.
    // So we loop automatically!
  }

  Widget _buildBody(BuildContext context, DailyChallengeState state) {
    if (state.status == DailyChallengeStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (state.status == DailyChallengeStatus.error) {
      return Center(
        child: Text(
          "Error: ${state.errorMessage}",
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (state.status == DailyChallengeStatus.ready) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              "Daily Challenge\n${state.challenge?.date}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${state.challenge?.words.length ?? 0} Words",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.read<DailyChallengeBloc>().add(StartDailyGame());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "START",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == DailyChallengeStatus.playing) {
      // We are navigating in listener. Show loader in background.
      return const Center(
        child: Text(
          "Loading next word...",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (state.status == DailyChallengeStatus.finished) {
      return _buildSummary(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildSummary(BuildContext context, DailyChallengeState state) {
    int wins = state.results.where((r) => r).length;
    int total = state.results.length;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Challenge Complete!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultStat("Words", "$total", Colors.black87),
                _buildResultStat("Solved", "$wins", Colors.green),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            // Global Stats?
            if (state.challenge != null)
              _buildGlobalStats(state.challenge!.stats),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGlobalStats(Map<String, dynamic> stats) {
    final attempts = stats['attempts'] ?? 0;
    final wins =
        stats['wins'] ?? 0; // Does wins mean full completion or word wins?
    // Repository incrementStats called per word. So stats.attempts is word attempts?
    // Logic: _repository.incrementStats(won: event.success).
    // So 'attempts' is total word attempts by everyone. 'wins' is total word wins.

    if (attempts == 0) return const SizedBox.shrink();

    final winRate = (wins / attempts * 100).toStringAsFixed(1);

    return Column(
      children: [
        const Text(
          "Global Statistics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text("Community Attempts: $attempts"),
        Text("Global Win Rate: $winRate%"),
      ],
    );
  }
}
