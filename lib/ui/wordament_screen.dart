import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/wordament_bloc.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';
import 'components/diamond_display.dart';
import 'components/points_action_dialog.dart';

import 'package:flutter/services.dart'; // For HapticFeedback

class WordamentScreen extends StatelessWidget {
  const WordamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WordamentBloc(
        context.read<WordRepository>(),
        context.read<StatisticsRepository>(),
      )..add(StartGame()),
      child: const WordamentView(),
    );
  }
}

class WordamentView extends StatefulWidget {
  const WordamentView({super.key});

  @override
  State<WordamentView> createState() => _WordamentViewState();
}

class _WordamentViewState extends State<WordamentView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      context.read<WordamentBloc>().add(Tick());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Game Info"),
                content: const Text(
                  "Find as many words as possible.\nConfiguration: Standard (All Categories)",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          },
          child: Column(
            children: [
              const Text(
                "GRID SEARCH",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "STANDARD MODE",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: BlocBuilder<WordamentBloc, WordamentState>(
              builder: (context, state) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${state.timeLeft}s",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Stats
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: BlocBuilder<WordamentBloc, WordamentState>(
                  builder: (context, state) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard("SCORE", "${state.score}"),
                        _buildStatCard(
                          "FOUND",
                          "${state.foundWords.length}/${state.allPossibleWords.length}",
                        ),
                      ],
                    );
                  },
                ),
              ),

              const Spacer(),

              // Current Word Display
              BlocBuilder<WordamentBloc, WordamentState>(
                builder: (context, state) {
                  return Text(
                    state.currentWord.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: BlocBuilder<WordamentBloc, WordamentState>(
                    builder: (context, state) {
                      if (state.status == WordamentStatus.loading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (state.status == WordamentStatus.finished) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "GAME OVER",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<WordamentBloc>().add(
                                        StartGame(),
                                      );
                                    },
                                    child: const Text("Play Again"),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<WordamentBloc>().add(
                                        ExtendTime(),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                    child: const Text("Extend (+30s)"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final cellSize = constraints.maxWidth / 4;
                          return GestureDetector(
                            onPanStart: (details) => _handleInput(
                              context,
                              details.localPosition,
                              cellSize,
                            ),
                            onPanUpdate: (details) => _handleInput(
                              context,
                              details.localPosition,
                              cellSize,
                            ),
                            onPanEnd: (_) =>
                                context.read<WordamentBloc>().add(DragEnd()),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 16,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                  ),
                              itemBuilder: (context, index) {
                                final isSelected = state.currentPath.contains(
                                  index,
                                );
                                final isLast =
                                    state.currentPath.isNotEmpty &&
                                    state.currentPath.last == index;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.orangeAccent
                                        : Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isLast
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    state.grid[index],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const Spacer(),

              // Found Words List (Horizontal Scroll)
              SizedBox(
                height: 50,
                child: BlocBuilder<WordamentBloc, WordamentState>(
                  builder: (context, state) {
                    final words = state.foundWords.toList().reversed.toList();
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: words.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Chip(
                          label: Text(words[index].toUpperCase()),
                          backgroundColor: Colors.white24,
                          labelStyle: const TextStyle(color: Colors.white),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _handleInput(BuildContext context, Offset localPos, double cellSize) {
    final col = (localPos.dx / cellSize).floor();
    final row = (localPos.dy / cellSize).floor();

    if (col >= 0 && col < 4 && row >= 0 && row < 4) {
      final index = row * 4 + col;
      final bloc = context.read<WordamentBloc>();
      // Determine if Start or Update based on path state?
      // Actually simpler: if path empty -> DragStart, else Update.
      // But PanStart calls this too.
      // Bloc handles state check.
      if (bloc.state.currentPath.isEmpty) {
        bloc.add(DragStart(index));
        HapticFeedback.selectionClick();
      } else {
        if (bloc.state.currentPath.last != index) {
          bloc.add(DragUpdate(index));
          HapticFeedback.selectionClick();
        }
      }
    }
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
