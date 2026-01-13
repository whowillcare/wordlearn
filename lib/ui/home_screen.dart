import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/game_levels.dart';
import '../logic/game_bloc.dart';
import '../logic/game_state.dart'; // Ensure state enum is visible
import '../data/statistics_repository.dart';
import '../data/settings_repository.dart';
import '../data/word_repository.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'library_screen.dart';
import 'components/points_action_dialog.dart';
import 'components/rewarded_ad_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_utils.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => PointsActionDialog(
        onWatchAd: () {
          _rewardedAdController.showAd(
            onUserEarnedReward: (amount) async {
              await context.read<StatisticsRepository>().addPoints(amount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Earned $amount Diamonds!")),
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "Daily Bonus! 🎉",
            style: TextStyle(color: Colors.orange),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("You maintained a $streak day streak!"),
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
              child: const Text("Claim"),
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
            _selectedIndex = 2;
          });
        },
      ),
      const LibraryScreen(),
      _PlaceholderScreen(title: l10n.shop),
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

  Widget _buildGamificationHeader(BuildContext context) {
    // Connect to real points
    final statsRepo = context.watch<StatisticsRepository>();

    return StreamBuilder<int>(
      // Changed from FutureBuilder
      stream: statsRepo.pointsStream,
      builder: (context, snapshot) {
        final points = snapshot.data ?? 0;
        const isVip = true; // Placeholder
        final l10n = AppLocalizations.of(context)!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 18,
                    child: Icon(Icons.person, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(width: 12),
                if (isVip)
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
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.white),
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: GestureDetector(
                    // Added interaction
                    onTap: () => _showPointsActionDialog(context),
                    child: Row(
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
                        const Icon(
                          Icons.diamond,
                          size: 16,
                          color: Colors.cyanAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  // _formatCategory replaced by CategoryUtils.formatName
  List<String> _dailyWords = [];
  bool _loadingDaily = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDailyChallenge());
  }

  Future<void> _loadDailyChallenge() async {
    try {
      final fetched = await context
          .read<WordRepository>()
          .getDailyChallengeWords();
      if (mounted) {
        setState(() {
          _dailyWords = fetched;
          _loadingDaily = false;
        });
      }
    } catch (e) {
      print("Error loading daily challenge: $e");
      if (mounted) setState(() => _loadingDaily = false);
    }
  }

  // ... (existing helper methods)

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

    // If starting NEW game, we might want to confirm if one exists?
    // For now, straightforward push. GameScreen will handle the "Start" event if !isResuming.

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          categories: categories.isEmpty ? ['all'] : categories,
          level: level,
          isResuming: isResuming,
        ),
      ),
    );

    // Handle navigation request from GameScreen
    if (result == 'GO_TO_SHOP' && mounted) {
      widget.onGoToShop();
    }
  }

  void _launchDailyGame(BuildContext context, String word) {
    // Find appropriate level based on length to set attempts/difficulty
    var bestLevel = gameLevels[2];
    if (word.length <= 4)
      bestLevel = gameLevels[0]; // Kindergarten
    else if (word.length >= 7)
      bestLevel = gameLevels[5]; // Grade 6+
    // Or roughly match:
    for (final l in gameLevels) {
      if (word.length >= l.minLength &&
          (l.maxLength == null || word.length <= l.maxLength!)) {
        bestLevel = l;
        break;
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          categories: const ['all'],
          level: bestLevel,
          isResuming: false,
          targetWord: word,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsRepository>();
    final gameState = context.watch<GameBloc>().state;
    final isGameActive = gameState.status == GameStatus.playing;

    // Derive Level Summary
    final levelKey = settings.gameLevel;
    final level = gameLevels.firstWhere(
      (l) => l.key == levelKey,
      orElse: () => gameLevels[2],
    );
    final levelSummary =
        "${level.name} (${level.minLength}-${level.maxLength ?? '+'})";

    // Derive Category Summary
    final cats = settings.defaultCategories;
    String categorySummary;
    if (cats.isEmpty || cats.contains('all')) {
      categorySummary = "All Categories";
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
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Colors.white70],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              l10n.appTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
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

          const SizedBox(height: 40),

          // --- Category Section (Read Only) ---
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

          // --- Word Length Section (Read Only) ---
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
            // RESUME BUTTON
            GestureDetector(
              onTap: () => _startGame(context, isResuming: true),
              child: _buildMainButton(
                context,
                label: "RESUME GAME",
                icon: Icons.play_arrow_rounded,
                colors: [Color(0xFF69F0AE), Color(0xFF00E676)], // Green
              ),
            ),
            const SizedBox(height: 16),
            // NEW GAME BUTTON (Small)
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
                child: const Text(
                  "START NEW GAME",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ] else ...[
            // PLAY BUTTON
            GestureDetector(
              onTap: () => _startGame(context, isResuming: false),
              child: _buildMainButton(
                context,
                label: l10n.play.toUpperCase(),
                icon: Icons.play_arrow_rounded,
                colors: [Color(0xFFFFAB40), Color(0xFFFF6D00)], // Orange
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Daily Challenge Card
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
                if (_loadingDaily)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else if (_dailyWords.isEmpty)
                  const Text(
                    "No challenges today!",
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  Column(
                    children: _dailyWords.asMap().entries.map((entry) {
                      final word = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ElevatedButton(
                          onPressed: () => _launchDailyGame(context, word),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 40),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Challenge ${entry.key + 1}: ${word.length} Letters"
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
              fontSize: 24, // Slightly smaller to fit "RESUME GAME"
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// --- Components ---

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

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
