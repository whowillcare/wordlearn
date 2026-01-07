import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/word_repository.dart';
import '../data/game_levels.dart';
import '../data/ingestion_result.dart';
import '../data/settings_repository.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'library_screen.dart';
import 'library_screen.dart';

class HomeScreen extends StatefulWidget {
  final IngestionResult? ingestionResult;
  const HomeScreen({super.key, this.ingestionResult});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  GameLevel _selectedLevel = gameLevels.first;
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // Show diagnostics if provided
    if (widget.ingestionResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only show if count is 0 or errors exist
        if (widget.ingestionResult!.finalCount == 0 ||
            widget.ingestionResult!.errors.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Data Load Status'),
              content: Text(widget.ingestionResult.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  Future<void> _loadCategories() async {
    final repo = context.read<WordRepository>();
    final settings = context.read<SettingsRepository>();
    final cats = await repo.getCategories();
    setState(() {
      _categories = cats;
      if (cats.isNotEmpty) {
        // Defaults
        final savedDefault = settings.defaultCategory;
        if (savedDefault != null && cats.contains(savedDefault)) {
          _selectedCategory = savedDefault;
        } else if (cats.contains('grade-11')) {
          _selectedCategory = 'grade-11';
        } else {
          _selectedCategory = cats.first;
        }
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('WordLearn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LibraryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select Category:', style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            const Text('Select Level:', style: TextStyle(fontSize: 18)),
            DropdownButton<GameLevel>(
              value: _selectedLevel,
              isExpanded: true,
              items: gameLevels.map((l) {
                return DropdownMenuItem(
                  value: l,
                  child: Text(
                    '${l.key.toUpperCase()} (Len: ${l.minLength}-${l.maxLength ?? "?"})',
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLevel = val);
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedCategory == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            category: _selectedCategory!,
                            level: _selectedLevel,
                          ),
                        ),
                      );
                    },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('START GAME', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
