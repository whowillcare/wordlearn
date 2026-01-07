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
          padding: const EdgeInsets.only(bottom: 6.0),
          child: _buildRow(
            word,
            targetWord.length,
            isSubmitted: index < guesses.length,
          ),
        );
      }),
    );
  }

  Widget _buildRow(String word, int length, {required bool isSubmitted}) {
    List<Color> colors = List.filled(length, Colors.transparent);
    Color borderColor = Colors.grey[400]!;
    Color textColor = Colors.black;

    if (isSubmitted && word.isNotEmpty) {
      textColor = Colors.white;
      borderColor = Colors.transparent;

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
          colors[i] = Colors.green;
          targetCounts[guessChars[i]] = targetCounts[guessChars[i]]! - 1;
        }
      }

      // Pass 2: Yellows/Greys
      for (int i = 0; i < word.length; i++) {
        if (colors[i] == Colors.green) continue; // Already handled

        final letter = guessChars[i];
        if (targetCounts.containsKey(letter) && targetCounts[letter]! > 0) {
          colors[i] = Colors.orange;
          targetCounts[letter] = targetCounts[letter]! - 1;
        } else {
          colors[i] = Colors.grey[700]!;
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

            Color cellColor = Colors.transparent;
            if (isSubmitted && index < word.length) {
              cellColor = colors[index];
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: _buildLetterBox(
                char,
                isSubmitted,
                cellColor,
                borderColor,
                textColor,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLetterBox(
    String char,
    bool isSubmitted,
    Color color,
    Color borderColor,
    Color textColor,
  ) {
    if (char.isNotEmpty && !isSubmitted) {
      borderColor = Colors.black;
    }

    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        char.toUpperCase(),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
