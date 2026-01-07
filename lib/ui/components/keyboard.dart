import 'package:flutter/material.dart';
import '../../logic/game_state.dart';

class Keyboard extends StatelessWidget {
  final Map<String, LetterStatus> letterStatus;
  final Function(String) onKeyTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onEnterTap;

  const Keyboard({
    super.key,
    required this.letterStatus,
    required this.onKeyTap,
    required this.onDeleteTap,
    required this.onEnterTap,
  });

  @override
  Widget build(BuildContext context) {
    const double keyHeight = 48;
    const double keySpacing = 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(
            ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
            keyHeight,
            keySpacing,
          ),
          const SizedBox(height: keySpacing),
          _buildRow(
            ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
            keyHeight,
            keySpacing,
            padding: 20.0,
          ), // Padding to center row 2 visualy
          const SizedBox(height: keySpacing),
          _buildRow(
            ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
            keyHeight,
            keySpacing,
            hasSpecialKeys: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    List<String> keys,
    double height,
    double spacing, {
    bool hasSpecialKeys = false,
    double padding = 0.0,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasSpecialKeys)
            _buildActionKey(
              label: 'ENTER',
              onTap: onEnterTap,
              height: height,
              flex: 3,
            ),
          if (hasSpecialKeys) SizedBox(width: spacing),
          ...keys.map((key) {
            return Expanded(
              flex: 2,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: _buildKey(key, height),
              ),
            );
          }).toList(),
          if (hasSpecialKeys) SizedBox(width: spacing),
          if (hasSpecialKeys)
            _buildActionKey(
              label: '⌫',
              onTap: onDeleteTap,
              height: height,
              flex: 3,
            ),
        ],
      ),
    );
  }

  Widget _buildKey(String letter, double height) {
    final status = letterStatus[letter] ?? LetterStatus.initial;
    final color = _getColor(status);
    final textColor = status == LetterStatus.initial
        ? Colors.black
        : Colors.white;

    return InkWell(
      onTap: () => onKeyTap(letter),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required String label,
    required VoidCallback onTap,
    required double height,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(LetterStatus status) {
    switch (status) {
      case LetterStatus.correct:
        return Colors.green;
      case LetterStatus.wrongPosition:
        return Colors.orange;
      case LetterStatus.notInWord:
        return Colors.grey[700]!;
      case LetterStatus.initial:
      default:
        return Colors.grey[300]!;
    }
  }
}
