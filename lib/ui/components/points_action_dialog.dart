import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/statistics_repository.dart';

class PointsActionDialog extends StatelessWidget {
  final VoidCallback? onWatchAd;
  final VoidCallback? onGoToShop;

  const PointsActionDialog({super.key, this.onWatchAd, this.onGoToShop});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PointsActionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Get More Diamonds'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.ondemand_video, color: Colors.deepPurple),
            title: const Text('Watch Ad (+10 💎)'),
            subtitle: const Text('Coming soon!'),
            onTap: () {
              Navigator.pop(context);
              if (onWatchAd != null) {
                onWatchAd!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ads not implemented yet!')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
            title: const Text('Visit Shop'),
            onTap: () {
              Navigator.pop(context);
              if (onGoToShop != null) {
                onGoToShop!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shop coming soon!')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.orange),
            title: const Text('Free Daily Reward'),
            onTap: () async {
              Navigator.pop(context);
              final repo = context.read<StatisticsRepository>();
              await repo.addPoints(10);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You got +10 Free Diamonds!')),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
