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
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: _buildLetterBox(char, index, isSubmitted),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLetterBox(String char, int index, bool isSubmitted) {
    Color color = Colors.transparent;
    Color borderColor = Colors.grey[400]!;
    Color textColor = Colors.black;

    if (isSubmitted && char.isNotEmpty) {
      textColor = Colors.white;
      borderColor = Colors.transparent;

      final targetChar = targetWord[index];
      if (char == targetChar) {
        color = Colors.green;
      } else if (targetWord.contains(char)) {
        // Simple logic for now, doesn't handle double letters perfectly visually in grid
        // (logic is usually handled in logic layer for strict wordle)
        color = Colors.orange;
      } else {
        color = Colors.grey[700]!;
      }
    } else if (char.isNotEmpty) {
      borderColor = Colors.black; // Active typing
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
