import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import '../data/game_levels.dart';
import '../logic/game_bloc.dart';
import '../logic/game_state.dart';
import '../data/statistics_repository.dart';
import '../data/settings_repository.dart';
import '../data/word_repository.dart';

import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:wakelock_plus/wakelock_plus.dart';

import 'components/guess_grid.dart';
import 'components/keyboard.dart';
import 'components/interstitial_ad_controller.dart';
import 'components/banner_ad_widget.dart';
import 'components/word_detail_dialog.dart';
import 'components/rewarded_ad_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_utils.dart';
import 'components/diamond_display.dart';
import 'components/points_action_dialog.dart';

class GameScreen extends StatefulWidget {
  final List<String> categories;
  final GameLevel level;
  final bool isResuming;
  final String? targetWord;

  const GameScreen({
    super.key,
    required this.categories,
    required this.level,
    this.isResuming = false,
    this.targetWord,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ConfettiController _confettiController;
  late InterstitialAdController _adController;
  late RewardedAdController _rewardedAdController;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isWakelockEnabled = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _adController = InterstitialAdController();
    _adController.loadAd();
    _rewardedAdController = RewardedAdController();
    _rewardedAdController = RewardedAdController();
    _rewardedAdController.loadAd();

    // Enable Wakelock by default (Screensaver Disabled)
    WakelockPlus.enable();

    // If NOT resuming, start a new game
    if (!widget.isResuming) {
      context.read<GameBloc>().add(
        GameStarted(
          level: widget.level,
          categories: widget.categories,
          targetWord: widget.targetWord,
        ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _adController.dispose();
    _rewardedAdController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  String _getCategoryTitle(BuildContext context) {
    if (widget.categories.length == 1) {
      return CategoryUtils.formatName(widget.categories.first);
    }
    return '${widget.categories.length} Categories';
  }

  void _showPointsActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => PointsActionDialog(
        onWatchAd: () {
          _rewardedAdController.showAd(
            onUserEarnedReward: (amount) async {
              await context.read<StatisticsRepository>().addPoints(amount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Earned $amount Diamonds!")),
              );
              _rewardedAdController.loadAd();
            },
          );
        },
        onGoToShop: () {
          // Return specific signal to home screen
          Navigator.of(context).pop('GO_TO_SHOP');
        },
      ),
    );
  }

  void _toggleWakelock() {
    setState(() {
      _isWakelockEnabled = !_isWakelockEnabled;
    });
    WakelockPlus.toggle(enable: _isWakelockEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isWakelockEnabled ? "Screen will stay ON" : "Screen sleep allowed",
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // "Low Key" Theme Background
      backgroundColor: const Color(0xFFE6E1F4), // Matte Light Purple
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6E1F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.deepPurple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
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
                    Text("Categories: ${_getCategoryTitle(context)}"),
                    const SizedBox(height: 8),
                    Text("Level: ${widget.level.name}"),
                    const SizedBox(height: 8),
                    Text(
                      "Word Length: ${widget.level.minLength} - ${widget.level.maxLength ?? '+'} letters",
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Word Candidates: ${context.read<GameBloc>().state.categoryWordCount ?? '?'} words",
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
          },
          child: Column(
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
        ),
        actions: [
          // Score Display
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: StreamBuilder<int>(
              stream: context.read<StatisticsRepository>().pointsStream,
              builder: (context, snapshot) {
                final points = snapshot.data ?? 0;
                return DiamondDisplay(
                  points: points,
                  onTap: () => _showPointsActionDialog(context),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.deepPurple),
            tooltip: 'Ask for Help',
            onPressed: () => _shareGameplay(),
          ),
          // More Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.deepPurple),
            onSelected: (value) {
              if (value == 'toggle_wakelock') {
                _toggleWakelock();
              }
            },
            itemBuilder: (BuildContext context) {
              final state = context.read<GameBloc>().state;
              return [
                // Word Count Info
                PopupMenuItem<String>(
                  enabled: false, // Info only
                  value: 'word_count',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_list_numbered,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${state.categoryWordCount ?? '?'} Words",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                // Screensaver Toggle
                PopupMenuItem<String>(
                  value: 'toggle_wakelock',
                  child: Row(
                    children: [
                      Icon(
                        _isWakelockEnabled
                            ? Icons.wb_incandescent
                            : Icons.wb_incandescent_outlined,
                        color: _isWakelockEnabled ? Colors.amber : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isWakelockEnabled
                            ? "Keep Screen ON"
                            : "Allow Screen Sleep",
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      body: Screenshot(
        controller: _screenshotController,
        child: BlocConsumer<GameBloc, GameState>(
          listener: (context, state) {
            if (state.status == GameStatus.won) {
              _adController.showAd();
              _confettiController.play();
              _showVictoryDialog(context, state);
            } else if (state.errorMessage != null &&
                state.errorMessage!.contains('Not enough points')) {
              // Intercept specific point errors
              _showPointsActionDialog(context);
              // TODO: Ideally verify if we need to clear error here or if Bloc does it
            } else if (state.status == GameStatus.lost) {
              _adController.showAd();
              // Show Defeat/Revive Dialog
              _showDefeatDialog(context, state);
            }
          },
          builder: (context, state) {
            if (state.status == GameStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                const BannerAdWidget(),
                Expanded(
                  child: LayoutBuilder(
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
                            maxAttempts:
                                (state.level?.attempts ?? 6) +
                                state.bonusAttempts,
                            revealedIndices: state.revealedIndices,
                          ),
                        ),
                      );

                      // Calculate special chars needed for the specific target word
                      final requiredSpecialChars = <String>{};
                      if (state.targetWord.contains('-'))
                        requiredSpecialChars.add('-');
                      if (state.targetWord.contains('\''))
                        requiredSpecialChars.add('\'');
                      if (state.targetWord.contains(' '))
                        requiredSpecialChars.add(' ');

                      final controlsSection = SingleChildScrollView(
                        child: Column(
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
                                  _buildHintButton(context, state),
                                  const SizedBox(width: 16),
                                  _buildPowerUpButton(
                                    context,
                                    icon: Icons.shuffle,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.shuffle,
                                    onTap: null, // Placeholder
                                  ),
                                ],
                              ),
                            ),

                            if (state.status == GameStatus.won)
                              _buildPostGameControls(context, state)
                            else
                              Keyboard(
                                letterStatus: state.letterStatus,
                                allowSpecialChars:
                                    settings.isSpecialCharsAllowed,
                                visibleSpecialChars: requiredSpecialChars,
                                onKeyTap: (letter) {
                                  context.read<GameBloc>().add(
                                    GuessEntered(letter),
                                  );
                                },
                                onDeleteTap: () {
                                  context.read<GameBloc>().add(GuessDeleted());
                                },
                                onEnterTap: () {
                                  context.read<GameBloc>().add(
                                    GuessSubmitted(),
                                  );
                                },
                              ),
                            if (state.isCategoryRevealed)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    state.hintMessage ?? "Category: ...",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                          ],
                        ),
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
                              blastDirectionality:
                                  BlastDirectionality.explosive,
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
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                      ),
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
                  ),
                ),
              ],
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

  Widget _buildHintButton(BuildContext context, GameState state) {
    return _buildPowerUpButton(
      context,
      icon: Icons.lightbulb,
      label: AppLocalizations.of(context)!.hint,
      onTap: state.status == GameStatus.playing
          ? () => _showHintMenu(context)
          : null,
    );
  }

  void _showHintMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Choose a Hint',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.orange),
                title: const Text('Reveal Letter'),
                subtitle: const Text('Cost: 10 pts'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<GameBloc>().add(
                    const HintRequested(HintType.letter),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.blueAccent),
                title: const Text('Reveal Synonym / Meaning'),
                subtitle: const Text('Cost: 20 pts'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<GameBloc>().add(
                    const HintRequested(HintType.synonym),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showDefeatDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Game Over',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You ran out of guesses!'),
            const SizedBox(height: 20),
            if (!state
                .isCategoryRevealed) // Logic check: hide word if possible? No, user lost.
              // Actually, we usually show the word on loss.
              // But if we want them to Review, maybe we hide it?
              // "Revive (+3 Guesses) - 20 pts" implies they continue attempting.
              // So we DON'T reveal the word yet if they might revive.
              // But the listener triggers on 'lost'.
              // If they give up, we reveal it? Or just show it now?
              // If we show it, reviving is pointless for guessing.
              // So: Dialog must NOT show word yet.
              const Text(
                'Revive for 30 Points?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            const Text('+3 Extra Guesses'),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                _rewardedAdController.showAd(
                  onUserEarnedReward: (amount) {
                    context.read<GameBloc>().add(PointsEarned(amount));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You earned $amount points!')),
                    );
                    // Optionally auto-revive if they have enough now?
                    // Or just stay in dialog.
                  },
                );
              },
              icon: const Icon(Icons.video_library, color: Colors.green),
              label: const Text('Watch Ad (+50 Pts)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              // Now show the word in a snackbar as "official" give up
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Game Over! Word was: ${state.targetWord.toUpperCase()}',
                  ),
                ),
              );
            },
            child: const Text('Give Up', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GameBloc>().add(GameRevived());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revive (30 pts)'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareVictory() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/victory.png').create();
      await imagePath.writeAsBytes(image);

      if (mounted) {
        // Close dialog first if we want clean share/resume flow, or keep it open.
        // Usually keeping it open is fine.
        await Share.shareXFiles([
          XFile(imagePath.path),
        ], text: 'I just won in Word-Le-Earn! 🏆 Can you beat me? #WordLeEarn');
      }
    } catch (e) {
      print('Share error: $e');
    }
  }

  Future<void> _shareGameplay() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/gameplay.png').create();
      await imagePath.writeAsBytes(image);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text:
              'Stuck on this word in Word-Le-Earn! 😫 Can you help me out? #WordLeEarn',
        );
      }
    } catch (e) {
      print('Share error: $e');
    }
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
                    FutureBuilder<WordMeanings?>(
                      future: context.read<WordRepository>().getWordMeanings(
                        state.targetWord,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          final m = snapshot.data!;
                          if (m.definitions.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                m.definitions.first,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
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
                  TextButton.icon(
                    onPressed: () => _shareVictory(),
                    icon: const Icon(Icons.share, color: Colors.blueAccent),
                    label: const Text('Share'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
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

  Widget _buildPostGameControls(BuildContext context, GameState state) {
    // We use a FutureBuilder or just a direct logic to open the dialog
    // Actually, let's keep it simple: A button that says "Library Actions" or just uses the dialog logic.
    // Or better: The button itself is the toggle, but to be consistent with request "click word to add/remove",
    // we can also just make this button open the dialog for the target word.

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => WordDetailDialog(word: state.targetWord),
            ).then((value) {
              // Update Bloc state if needed, but dialog handles repo directly.
              // We might want to trigger a refresh event if we want strict consistency,
              // but for now visual consistency in dialog is enough.
              // Actually, if we add it, 'isWordSaved' in Bloc might be stale.
              // Let's rely on the Dialog for truth.
              if (value == true) {
                context.read<GameBloc>().add(AddToLibraryRequested());
              }
            });
          },
          icon: const Icon(Icons.bookmark_border),
          label: const Text('Manage in Library'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
    );
  }
}
