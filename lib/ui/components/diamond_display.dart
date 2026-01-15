import 'package:flutter/material.dart';

class DiamondDisplay extends StatelessWidget {
  final int points;
  final VoidCallback? onTap;

  const DiamondDisplay({super.key, required this.points, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$points",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.diamond, size: 16, color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }
}
