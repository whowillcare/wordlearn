import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_learn_app/data/statistics_repository.dart';
import 'package:word_learn_app/ui/components/glass_container.dart';
import 'package:word_learn_app/l10n/app_localizations.dart';

class ShopScreen extends StatelessWidget {
  final VoidCallback? onWatchAd;

  const ShopScreen({super.key, this.onWatchAd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = context.watch<StatisticsRepository>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          // Header
          Text(
            l10n.shop.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${stats.currentPoints}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.diamond, size: 20, color: Colors.cyanAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Free Rewards Section
          _buildSectionHeader("FREE REWARDS"),
          const SizedBox(height: 16),
          _buildShopItem(
            context,
            title: "Watch Video",
            subtitle: "+20 Diamonds",
            icon: Icons.play_circle_fill_rounded,
            color: Colors.orange,
            onTap: onWatchAd,
            isFree: true,
          ),

          const SizedBox(height: 32),

          // Point Packs Section
          _buildSectionHeader("POINT PACKS"),
          const SizedBox(height: 16),
          _buildShopItem(
            context,
            title: "Handful of Diamonds",
            subtitle: "500 Diamonds",
            price: "\$0.99",
            icon: Icons.diamond_outlined,
            color: Colors.cyan,
            onTap: () {
              // TODO: Implement IAP
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
            },
          ),
          const SizedBox(height: 12),
          _buildShopItem(
            context,
            title: "Bag of Diamonds",
            subtitle: "1500 Diamonds",
            price: "\$2.99",
            icon: Icons.local_mall_outlined,
            color: Colors.purpleAccent,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
            },
          ),
          const SizedBox(height: 12),
          _buildShopItem(
            context,
            title: "Chest of Diamonds",
            subtitle: "5000 Diamonds",
            price: "\$8.99",
            icon: Icons.all_inbox_rounded,
            color: Colors.amberAccent,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
            },
          ),

          const SizedBox(height: 32),

          // Premium
          _buildSectionHeader("PREMIUM"),
          const SizedBox(height: 16),
          _buildShopItem(
            context,
            title: "VIP Status",
            subtitle: "Remove Ads + Infinite Energy",
            price: "\$9.99",
            icon: Icons.star_rounded,
            color: Colors.amber,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
            },
            isVIP: true,
          ),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(
          Icons.store_mall_directory_rounded,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildShopItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? price,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isFree = false,
    bool isVIP = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (price != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            else if (isFree)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.teal],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "WATCH",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
