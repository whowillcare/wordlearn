import 'package:flutter/material.dart';
import '../../logic/game_state.dart';
import 'word_detail_dialog.dart';

class GuessGrid extends StatelessWidget {
  final List<String> guesses;
  final String currentGuess;
  final String targetWord;
  final int maxAttempts;

  const GuessGrid({
    super.key,
    required this.guesses,
    required this.currentGuess,
    required this.targetWord,
    required this.maxAttempts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxAttempts, (index) {
        String word = '';
        bool isCurrent = false;
        bool isSubmitted = index < guesses.length;

        if (index < guesses.length) {
          word = guesses[index];
        } else if (index == guesses.length) {
          word = currentGuess;
          isCurrent = true;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GestureDetector(
            onTap: isSubmitted
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => WordDetailDialog(word: word),
                    );
                  }
                : null,
            child: _GuessRow(
              word: word,
              targetLength: targetWord.length,
              targetWord: targetWord,
              isSubmitted: isSubmitted,
              isCurrent: isCurrent,
            ),
          ),
        );
      }),
    );
  }
}

class _GuessRow extends StatefulWidget {
  final String word;
  final int targetLength;
  final String targetWord;
  final bool isSubmitted;
  final bool isCurrent;

  const _GuessRow({
    Key? key,
    required this.word,
    required this.targetLength,
    required this.targetWord,
    required this.isSubmitted,
    required this.isCurrent,
  }) : super(key: key);

  @override
  State<_GuessRow> createState() => _GuessRowState();
}

class _GuessRowState extends State<_GuessRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _GuessRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll logic update
    if (widget.isCurrent &&
        widget.word.length != oldWidget.word.length &&
        _scrollController.hasClients) {
      // Delay to ensure layout is updated for bounds/viewport check
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!_scrollController.hasClients) return;

        // Configuration
        const itemWidth = 62.0; // 50 bubble + 12 margin
        const rightPadding = 70.0; // Keep cursor a bit away from the edge

        final viewportWidth = _scrollController.position.viewportDimension;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentIndex = widget.word.length;

        // Calculate "Ideal" scroll position:
        // We want the end of the current cursor slot (index + 1) to be visible,
        // specifically at `viewportWidth - rightPadding` relative to the *visible* area.
        // Formula: ScrollOffset = (ItemRightEdge) - (ViewportWidth - Padding)

        final itemRightEdge = (currentIndex + 1) * itemWidth;
        double targetScroll = itemRightEdge - (viewportWidth - rightPadding);

        // Clamp logic
        if (targetScroll < 0) targetScroll = 0;
        if (targetScroll > maxScroll) targetScroll = maxScroll;

        // Animate
        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Compact Row Logic: Only for submitted words > 5 letters
    final bool useCompactMode = widget.isSubmitted && widget.targetLength > 5;

    // Determine style based on state
    final double bubbleSize = useCompactMode ? 34.0 : 50.0;
    final double padding = useCompactMode ? 2.0 : 6.0;
    final double fontSize = useCompactMode ? 18.0 : 24.0;

    // Pre-calculate colors if submitted
    List<Gradient?> gradients = List.filled(widget.targetLength, null);
    List<Color> textColors = List.filled(
      widget.targetLength,
      Colors.deepPurple,
    );
    List<BoxShadow> shadows = [];

    if (widget.isSubmitted) {
      _calculateColors(gradients, textColors);
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
    }

    final children = List.generate(widget.targetLength, (index) {
      String char = '';
      if (index < widget.word.length) {
        char = widget.word[index];
      }

      // Cursor logic: Only show styled cursor on active row at current index
      bool isCursor = widget.isCurrent && index == widget.word.length;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: padding),
        width: bubbleSize,
        height: bubbleSize,
        child: _buildBubble(
          char,
          widget.isSubmitted,
          gradients[index],
          widget.isSubmitted ? Colors.white : Colors.deepPurple,
          isCursor,
          shadows,
          fontSize,
        ),
      );
    });

    if (useCompactMode) {
      // Compact View: FittedBox ensures it scales down to fit screen width without scrolling
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      );
    } else {
      // Active/Standard View: Scrollable
      return Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      );
    }
  }

  void _calculateColors(List<Gradient?> gradients, List<Color> textColors) {
    final targetChars = widget.targetWord.split('');
    final guessChars = widget.word.split('');
    final targetCounts = <String, int>{};

    for (var char in targetChars) {
      targetCounts[char] = (targetCounts[char] ?? 0) + 1;
    }

    // Pass 1: Greens
    for (int i = 0; i < widget.word.length; i++) {
      if (i >= widget.targetLength) break;
      if (guessChars[i] == targetChars[i]) {
        gradients[i] = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
        );
        targetCounts[guessChars[i]] = targetCounts[guessChars[i]]! - 1;
      }
    }

    // Pass 2: Yellows/Greys
    for (int i = 0; i < widget.word.length; i++) {
      if (i >= widget.targetLength) break;
      if (gradients[i] != null) continue;

      final letter = guessChars[i];
      if (targetCounts.containsKey(letter) && targetCounts[letter]! > 0) {
        gradients[i] = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
        );
        targetCounts[letter] = targetCounts[letter]! - 1;
      } else {
        gradients[i] = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[400]!, Colors.grey[600]!],
        );
      }
    }
  }

  Widget _buildBubble(
    String char,
    bool isSubmitted,
    Gradient? gradient,
    Color textColor,
    bool isCursor,
    List<BoxShadow> shadows,
    double fontSize,
  ) {
    // Empty/Typing state
    if (!isSubmitted && gradient == null) {
      if (char.isNotEmpty) {
        // Current input
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF3E5F5)],
        );
        shadows = [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      } else {
        // Empty slot
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            boxShadow: isCursor
                ? [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: shadows,
        border: isCursor
            ? Border.all(color: Colors.deepPurpleAccent, width: 2)
            : null,
      ),
      child: Text(
        char.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
          shadows: isSubmitted
              ? [
                  const Shadow(
                    blurRadius: 2,
                    color: Colors.black26,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
