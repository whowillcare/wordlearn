import 'package:flutter/material.dart';

class NeonCapsule extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLocked;
  final bool showCheck;
  final VoidCallback onTap;

  const NeonCapsule({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isLocked = false,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isLocked
              ? Colors.black.withOpacity(0.3)
              : (isSelected ? Colors.white : Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isLocked
                ? Colors.grey.withOpacity(0.3)
                : (isSelected ? Colors.white : Colors.white.withOpacity(0.3)),
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected && !isLocked
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked) ...[
              const Icon(Icons.lock_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isLocked
                    ? Colors.white54
                    : (isSelected ? Colors.deepPurple : Colors.white),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            if (showCheck && isSelected && !isLocked) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.deepPurple,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
