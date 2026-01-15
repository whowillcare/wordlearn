import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/spelling_bee_bloc.dart';
import '../data/word_repository.dart';
import '../data/statistics_repository.dart';
import 'components/diamond_display.dart';
import 'components/points_action_dialog.dart';
import 'components/glass_container.dart';

class SpellingBeeScreen extends StatelessWidget {
  const SpellingBeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SpellingBeeBloc(
        context.read<WordRepository>(),
        context.read<StatisticsRepository>(),
      )..add(StartSpellingGame()),
      child: const SpellingBeeView(),
    );
  }
}

class SpellingBeeView extends StatefulWidget {
  const SpellingBeeView({super.key});

  @override
  State<SpellingBeeView> createState() => _SpellingBeeViewState();
}

class _SpellingBeeViewState extends State<SpellingBeeView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Spelling Bee",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
            colors: [Color(0xFFF9A825), Color(0xFFF57F17)], // Yellows/Bees
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BlocConsumer<SpellingBeeBloc, SpellingBeeState>(
          listener: (context, state) {
            if (state.status == SpellingStatus.correct) {
              _textController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Correct!"),
                  backgroundColor: Colors.green,
                ),
              );
              // Delay slightly before next?
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (context.mounted) {
                  context.read<SpellingBeeBloc>().add(NextSpellingWord());
                }
              });
            } else if (state.status == SpellingStatus.incorrect) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Incorrect. Try again!"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == SpellingStatus.finished) {
              return Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "🐝 Bee-autiful! 🐝",
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Total Score: ${state.score}",
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
                          foregroundColor: Colors.orange[800],
                        ),
                        child: const Text("Back to Menu"),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GlassContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Speaker Icon (Big)
                        GestureDetector(
                          onTap: () => context.read<SpellingBeeBloc>().add(
                            const PlayAudio(slow: false),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => context.read<SpellingBeeBloc>().add(
                            const PlayAudio(slow: true),
                          ),
                          icon: const Icon(Icons.speed, color: Colors.white70),
                          label: const Text(
                            "Listen Slow",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Input
                        TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            hintText: "Type word...",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                            ),
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (value) {
                            context.read<SpellingBeeBloc>().add(
                              SubmitSpelling(value),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        ElevatedButton(
                          onPressed: () {
                            if (_textController.text.isNotEmpty) {
                              context.read<SpellingBeeBloc>().add(
                                SubmitSpelling(_textController.text),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange[900],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text("CHECK"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
