import 'package:flutter/material.dart';

class PointsActionDialog extends StatelessWidget {
  final VoidCallback onWatchAd;
  final VoidCallback onGoToShop;

  const PointsActionDialog({
    super.key,
    required this.onWatchAd,
    required this.onGoToShop,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Need more Diamonds?",
        style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "Earn diamonds by watching a short video or visit the shop for more options.",
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onGoToShop();
          },
          icon: const Icon(Icons.shopping_bag, color: Colors.orange),
          label: const Text(
            "Go to Shop",
            style: TextStyle(color: Colors.orange),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onWatchAd();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.videocam),
          label: const Text("Watch Video (+50 Diamonds)"),
        ),
      ],
    );
  }
}
