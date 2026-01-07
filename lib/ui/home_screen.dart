import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/word_repository.dart';
import '../data/game_levels.dart';
import '../data/ingestion_result.dart';
import '../data/settings_repository.dart';
import '../utils/category_utils.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'library_screen.dart';

class HomeScreen extends StatefulWidget {
  final IngestionResult? ingestionResult;
  const HomeScreen({super.key, this.ingestionResult});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Using Set for easier management, converted to List for API
  Set<String> _selectedCategories = {'all'};
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

    // Sort
    cats.sort(CategoryUtils.compareCategories);

    // Add 'all' if not present
    if (!cats.contains('all')) {
      cats.insert(0, 'all');
    }

    setState(() {
      _categories = cats;
      if (cats.isNotEmpty) {
        // Defaults
        final savedDefault = settings.defaultCategory;
        if (savedDefault != null && cats.contains(savedDefault)) {
          if (savedDefault == 'all') {
            _selectedCategories = {'all'};
          } else {
            _selectedCategories = {savedDefault};
          }
        }
      }
      _isLoading = false;
    });
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return CategoryPicker(
            categories: _categories,
            initialSelected: _selectedCategories.toList(),
            onChanged: (newSelection) {
              setState(() => _selectedCategories = newSelection.toSet());
            },
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  String get _categoryButtonText {
    if (_selectedCategories.contains('all')) return 'Everything';
    if (_selectedCategories.isEmpty) return 'Select Category';
    if (_selectedCategories.length == 1) {
      return CategoryUtils.formatName(_selectedCategories.first);
    }
    return '${_selectedCategories.length} Categories Selected';
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
            const SizedBox(height: 8),
            InkWell(
              onTap: _showCategoryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _categoryButtonText,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
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
              onPressed: _selectedCategories.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            categories: _selectedCategories.toList(),
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

class CategoryPicker extends StatefulWidget {
  final List<String> categories;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onChanged;
  final ScrollController scrollController;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.initialSelected,
    required this.onChanged,
    required this.scrollController,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  late List<String> _filtered;
  late Set<String> _currentSelection;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.categories;
    _currentSelection = widget.initialSelected.toSet();
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = widget.categories);
    } else {
      setState(() {
        _filtered = widget.categories.where((c) {
          final nice = CategoryUtils.formatName(c).toLowerCase();
          return nice.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _toggle(String category) {
    setState(() {
      if (category == 'all') {
        _currentSelection = {'all'};
      } else {
        _currentSelection.remove('all');
        if (_currentSelection.contains(category)) {
          _currentSelection.remove(category);
        } else {
          _currentSelection.add(category);
        }

        if (_currentSelection.isEmpty) {
          _currentSelection = {'all'}; // Fallback to all if nothing selected
        }
      }
      widget.onChanged(_currentSelection.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search Categories',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filter,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${_currentSelection.length} selected",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cat = _filtered[index];
              final isSelected = _currentSelection.contains(cat);
              return CheckboxListTile(
                title: Text(CategoryUtils.formatName(cat)),
                value: isSelected,
                onChanged: (_) => _toggle(cat),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
        ),
      ],
    );
  }
}
