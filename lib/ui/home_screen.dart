import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added
import '../data/auth_repository.dart'; // Added

import '../data/game_levels.dart';
import '../logic/game_bloc.dart';
import '../logic/game_state.dart'; // Ensure state enum is visible
import '../data/statistics_repository.dart';
import '../data/settings_repository.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'library_screen.dart';
import 'components/points_action_dialog.dart';
import 'components/rewarded_ad_controller.dart';
import 'components/glass_container.dart';
import 'components/neon_capsule.dart';
import 'components/diamond_display.dart';
import 'shop_screen.dart';
import 'minigames_menu.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_utils.dart';
import 'daily_challenge_screen.dart';

import 'dart:math' as math;
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _gradientController;
  late RewardedAdController _rewardedAdController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _rewardedAdController = RewardedAdController();
    _rewardedAdController.loadAd();

    // Check Daily Bonus
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDailyBonus());
  }

  void _showPointsActionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => PointsActionDialog(
        onWatchAd: () {
          _rewardedAdController.showAd(
            onUserEarnedReward: (amount) async {
              await context.read<StatisticsRepository>().addPoints(amount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.earnedDiamonds(amount))),
              );
              _rewardedAdController.loadAd(); // Preload next
            },
          );
        },
        onGoToShop: () {
          setState(() {
            _selectedIndex = 2; // Switch to Shop tab
          });
        },
      ),
    );
  }

  Future<void> _checkDailyBonus() async {
    final stats = context.read<StatisticsRepository>();
    final result = await stats.checkDailyBonus();
    if (result['claimed'] == false && mounted) {
      final reward = result['reward'];
      final streak = result['streak'];
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.dailyBonusTitle,
            style: const TextStyle(color: Colors.orange),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.dailyBonusContent(streak)),
              const SizedBox(height: 10),
              Text(
                "+$reward Diamonds",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.claim),
            ),
          ],
        ),
      );
      setState(() {}); // Refresh points display
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Pages for Bottom Nav
    final List<Widget> pages = [
      _HomeContent(
        onGoToShop: () {
          setState(() {
            _selectedIndex = 2; // Switch to Shop tab
          });
        },
      ),
      const LibraryScreen(),
      ShopScreen(
        onWatchAd: () {
          _rewardedAdController.showAd(
            onUserEarnedReward: (amount) async {
              await context.read<StatisticsRepository>().addPoints(amount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.earnedDiamonds(amount))),
              );
              _rewardedAdController.loadAd(); // Preload next
            },
          );
        },
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allow body to go behind nav bar
      body: Stack(
        children: [
          // 1. Dynamic Mesh Gradient Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return CustomPaint(
                  painter: MeshGradientPainter(
                    animationValue: _gradientController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildGamificationHeader(context),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: pages[_selectedIndex],
                  ),
                ),
                // Add padding for bottom nav
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(l10n),
    );
  }

  Widget _buildGlassBottomNav(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_rounded, l10n.appTitle),
              _buildNavItem(1, Icons.menu_book_rounded, l10n.library),
              _buildNavItem(2, Icons.storefront_rounded, l10n.shop),
              _buildNavItem(3, Icons.settings, l10n.settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleProfileTap(BuildContext context, User? user) {
    if (user == null) {
      // Not logged in -> Show Login options
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    } else {
      // Logged in -> Show Logout confirmation
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.signOut),
          content: Text(
            "Are you sure you want to sign out, ${user.displayName ?? 'User'}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                context.read<AuthRepository>().signOut();
                Navigator.pop(ctx);
              },
              child: const Text("Sign Out"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildGamificationHeader(BuildContext context) {
    // Connect to real points
    final statsRepo = context.watch<StatisticsRepository>();
    final authRepo = context.read<AuthRepository>();

    return StreamBuilder<User?>(
      stream: authRepo.user,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        // Logic: specific features or logged-in status defines VIP for now
        final isVip = user != null;

        return StreamBuilder<int>(
          stream: statsRepo.pointsStream,
          builder: (context, pointsSnapshot) {
            final points = pointsSnapshot.data ?? 0;
            final l10n = AppLocalizations.of(context)!;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _handleProfileTap(context, user),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              child: user?.photoURL == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.deepPurple,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isVip) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.amber, Colors.orange],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.vipMode.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else
                            // Prompt to Login if not VIP
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "GUEST",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    DiamondDisplay(
                      points: points,
                      onTap: () => _showPointsActionDialog(context),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  final VoidCallback onGoToShop;
  const _HomeContent({required this.onGoToShop});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  // Note: _formatCategory is replaced by CategoryUtils.formatName dynamically

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _startGame(
    BuildContext context, {
    bool isResuming = false,
  }) async {
    final settings = context.read<SettingsRepository>();
    final categories = settings.defaultCategories;
    final levelKey = settings.gameLevel;
    final level = gameLevels.firstWhere(
      (l) => l.key == levelKey,
      orElse: () => gameLevels[2],
    );

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          categories: categories.isEmpty ? ['all'] : categories,
          level: level,
          isResuming: isResuming,
        ),
      ),
    );

    if (result == 'GO_TO_SHOP' && mounted) {
      widget.onGoToShop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsRepository>();
    final gameState = context.watch<GameBloc>().state;
    final isGameActive = gameState.status == GameStatus.playing;

    // Derived State
    final levelKey = settings.gameLevel;
    final level = gameLevels.firstWhere(
      (l) => l.key == levelKey,
      orElse: () => gameLevels[2],
    );
    final levelSummary =
        "${level.name} (${level.minLength}-${level.maxLength ?? '+'})";

    final cats = settings.defaultCategories;
    String categorySummary;
    if (cats.isEmpty || cats.contains('all')) {
      categorySummary = "All Categories"; // Could localize if needed
    } else if (cats.length == 1) {
      categorySummary = CategoryUtils.formatName(cats.first);
    } else {
      categorySummary = "${cats.length} Categories Selected";
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),

          // Hero Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Text(
                        "WORD-LE-ARN", // Updated to Word-Le-Arn as requested
                        style: TextStyle(
                          fontSize:
                              40, // Slightly reduced to fit better with icon
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- Category Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSectionHeader("CATEGORIES"),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _navigateToSettings,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NeonCapsule(
                label: categorySummary,
                isSelected: true,
                onTap: _navigateToSettings,
                showCheck: false,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // --- Word Length Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSectionHeader("WORD LENGTH"),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _navigateToSettings,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NeonCapsule(
                label: levelSummary,
                isSelected: true,
                onTap: _navigateToSettings,
                showCheck: false,
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Actions
          if (isGameActive) ...[
            GestureDetector(
              onTap: () => _startGame(context, isResuming: true),
              child: _buildMainButton(
                context,
                label: l10n.resumeGame.toUpperCase(),
                icon: Icons.play_arrow_rounded,
                colors: [const Color(0xFF69F0AE), const Color(0xFF00E676)],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _startGame(context, isResuming: false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.startNewGame.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => _startGame(context, isResuming: false),
              child: _buildMainButton(
                context,
                label: l10n.play.toUpperCase(),
                icon: Icons.play_arrow_rounded,
                colors: [const Color(0xFFFFAB40), const Color(0xFFFF6D00)],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Mini Games
          GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MiniGamesMenu())),
            child: _buildMainButton(
              context,
              label: l10n.minigames.toUpperCase(),
              icon: Icons.extension,
              colors: [Colors.purpleAccent, Colors.deepPurple],
            ),
          ),

          const SizedBox(height: 40),

          // Daily Challenge
          GlassContainer(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.dailyChallenge.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyChallengeScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TODAY'S WORDS",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "3 Words • Global Stats",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.5),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.white30,
            offset: Offset(0, -2),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white, size: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(
          title == "CATEGORIES"
              ? Icons.category_rounded
              : Icons.straighten_rounded,
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
}

// --- Components ---

// Custom Painter for Mesh Gradient
class MeshGradientPainter extends CustomPainter {
  final double animationValue;

  MeshGradientPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * 2 * math.pi;
    final center = Offset(size.width / 2, size.height / 2);

    // Warm, Game-like Palette
    final colors = [
      const Color(0xFF6A1B9A), // Deep Purple
      const Color(0xFF8E24AA), // Purple
      const Color(0xFFD81B60), // Pink
      const Color(0xFFFF6D00), // Orange
      const Color(0xFFFFD600), // Yellow
    ];

    // Create a mesh of points
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Draw dynamic blobs
    void drawBlob(Offset offset, Color color, double radius) {
      final p = Paint()
        ..color = color.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
      canvas.drawCircle(offset, radius, p);
    }

    // Moving blobs
    drawBlob(
      Offset(
        size.width * 0.2 + math.cos(t) * 50,
        size.height * 0.3 + math.sin(t) * 50,
      ),
      colors[0],
      size.width * 0.5,
    );

    drawBlob(
      Offset(
        size.width * 0.8 - math.sin(t) * 50,
        size.height * 0.2 + math.cos(t) * 50,
      ),
      colors[3],
      size.width * 0.4,
    );

    drawBlob(
      Offset(
        size.width * 0.5 + math.sin(t * 0.5) * 100,
        size.height * 0.8 + math.cos(t * 0.5) * 30,
      ),
      colors[2],
      size.width * 0.6,
    );

    // Overlay to ensure text legibility (darken slightly)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.1),
    );
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
