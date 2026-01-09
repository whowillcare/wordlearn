import 'package:flutter/material.dart';
import '../../logic/game_state.dart';

class Keyboard extends StatelessWidget {
  final bool allowSpecialChars;
  final Map<String, LetterStatus> letterStatus;
  final void Function(String) onKeyTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onEnterTap;

  const Keyboard({
    super.key,
    required this.letterStatus,
    required this.onKeyTap,
    required this.onDeleteTap,
    required this.onEnterTap,
    this.allowSpecialChars = false,
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
            padding: 2.0, // Reduced padding for tighter fit
          ),
          const SizedBox(height: keySpacing),
          _buildRow(
            [
              if (allowSpecialChars) '-',
              if (allowSpecialChars) '\'',
              'z',
              'x',
              'c',
              'v',
              'b',
              'n',
              'm',
            ],
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
              icon: Icons.check,
              onTap: onEnterTap,
              height: height,
              flex: 3,
              color: Colors.greenAccent.shade700,
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
              icon: Icons.backspace_outlined,
              onTap: onDeleteTap,
              height: height,
              flex: 3,
              color: Colors.redAccent.shade200,
            ),
        ],
      ),
    );
  }

  Widget _buildKey(String letter, double height) {
    final status = letterStatus[letter] ?? LetterStatus.initial;
    final gradient = _getGradient(status);
    final textColor = status == LetterStatus.initial
        ? Colors.deepPurple
        : Colors.white;

    return GestureDetector(
      onTap: () => onKeyTap(letter),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(24), // Pill shape
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
    required IconData icon,
    required VoidCallback onTap,
    required double height,
    required Color color,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Gradient _getGradient(LetterStatus status) {
    switch (status) {
      case LetterStatus.correct:
        return const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
        );
      case LetterStatus.wrongPosition:
        return const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
        );
      case LetterStatus.notInWord:
        return LinearGradient(colors: [Colors.grey[400]!, Colors.grey[600]!]);
      case LetterStatus.initial:
      default:
        return const LinearGradient(colors: [Colors.white, Color(0xFFF3E5F5)]);
    }
  }
}
