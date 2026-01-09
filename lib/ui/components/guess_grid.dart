import 'package:flutter/material.dart';
import '../../logic/game_state.dart';

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

        if (index < guesses.length) {
          word = guesses[index];
        } else if (index == guesses.length) {
          word = currentGuess;
          isCurrent = true;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildRow(
            word,
            targetWord.length,
            isSubmitted: index < guesses.length,
            isCurrent: isCurrent,
          ),
        );
      }),
    );
  }

  Widget _buildRow(
    String word,
    int length, {
    required bool isSubmitted,
    required bool isCurrent,
  }) {
    List<Color> baseColors = List.filled(length, Colors.white.withOpacity(0.5));
    List<Gradient?> gradients = List.filled(length, null);
    Color textColor = Colors.deepPurple;
    List<BoxShadow> shadows = [];

    if (isSubmitted && word.isNotEmpty) {
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

      // Strict Wordle Logic
      final targetChars = targetWord.split('');
      final guessChars = word.split('');
      final targetCounts = <String, int>{};

      for (var char in targetChars) {
        targetCounts[char] = (targetCounts[char] ?? 0) + 1;
      }

      // Pass 1: Greens
      for (int i = 0; i < word.length; i++) {
        if (guessChars[i] == targetChars[i]) {
          gradients[i] = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF66BB6A), Color(0xFF43A047)], // Green 400-600
          );
          targetCounts[guessChars[i]] = targetCounts[guessChars[i]]! - 1;
        }
      }

      // Pass 2: Yellows/Greys
      for (int i = 0; i < word.length; i++) {
        if (gradients[i] != null) continue; // Already handled

        final letter = guessChars[i];
        if (targetCounts.containsKey(letter) && targetCounts[letter]! > 0) {
          gradients[i] = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFA726), Color(0xFFFB8C00)], // Orange 400-600
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

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (index) {
            String char = '';
            if (index < word.length) {
              char = word[index];
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: _buildBubble(
                char,
                isSubmitted,
                gradients[index],
                textColor,
                isCurrent &&
                    index == word.length, // Cursor effect could be added here
                shadows,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBubble(
    String char,
    bool isSubmitted,
    Gradient? gradient,
    Color textColor,
    bool isCursor,
    List<BoxShadow> shadows,
  ) {
    // Empty state for current row
    if (!isSubmitted && gradient == null) {
      if (char.isNotEmpty) {
        // Filled but not submitted (Current Guess Letters)
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF3E5F5),
          ], // White to very light purple
        );
        shadows = [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      } else {
        // Completely empty slot
        // Glassmorphism feel: translucent white with border
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
          ),
        );
      }
    }

    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: shadows,
      ),
      child: Text(
        char.toUpperCase(),
        style: TextStyle(
          fontSize: 24,
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
