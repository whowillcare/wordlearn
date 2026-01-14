import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/settings_repository.dart';
import '../data/word_repository.dart';
import '../data/game_levels.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';

import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _allCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final wordRepo = context.read<WordRepository>();
    final cats = await wordRepo.getCategories();
    if (mounted) {
      setState(() {
        _allCategories = ['all', ...cats];
        _isLoadingCategories = false;
      });
    }
  }

  // Helper for friendly names
  String _formatCategory(String tag) {
    if (tag == 'all') return 'All Categories';

    // Friendly name mapping
    final Map<String, String> displayNames = {
      'freq': 'Most Frequent',
      'grade-1': 'Grade 1',
      'grade-2': 'Grade 2',
      'grade-3': 'Grade 3',
      'grade-4': 'Grade 4',
      'grade-5': 'Grade 5',
      'grade-6': 'Grade 6',
      'grade-7': 'Grade 7',
      'grade-8': 'Grade 8',
      'grade-9': 'Grade 9',
      'grade-10': 'Grade 10',
      'grade-11': 'Grade 11',
      'grade-12': 'Grade 12',
      'svl': 'Sec. School Voc.',
      'msvl': 'Mid. School Voc.',
      'tof': 'TOEFL',
      'sat': 'S.A.T.',
      'gre': 'GRE',
      'ielts': 'IELTS',
      'svl - math': 'Sec. School Math',
      'svl - biology': 'Sec. School Biology',
      'svl - chemistry': 'Sec. School Chemistry',
      'svl - ecnomics':
          'Sec. School Economics', // Correcting typo from filename if needed, or mapping exact filename
      'svl - english': 'Sec. School English',
      'svl - geography': 'Sec. School Geography',
      'svl - history': 'Sec. School History',
      'svl - physics': 'Sec. School Physics',
      'academic (avl)': 'Academic (AVL)',
      'science word list': 'Science Word List',
    };

    if (displayNames.containsKey(tag)) return displayNames[tag]!;

    return tag
        .split('-')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join(' ');
  }

  void _showCategoryDialog(
    List<String> currentSelection,
    SettingsRepository settings,
  ) {
    if (_isLoadingCategories) return;

    showDialog(
      context: context,
      builder: (context) => _CategoryMultiSelectDialog(
        allCategories: _allCategories,
        selectedCategories: currentSelection,
        formatCategory: _formatCategory, // Pass the formatter
        onSave: (List<String> newSelection) async {
          await settings.setDefaultCategories(newSelection);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsRepository>();

    // Derive state from settings
    final isSoundEnabled = settings.isSoundEnabled;
    final isVip = settings.isVip;
    final isSpecialCharsAllowed = settings.isSpecialCharsAllowed;
    final selectedLevelKey = settings.gameLevel;

    var selectedCategories = settings.defaultCategories;
    if (selectedCategories.isEmpty) selectedCategories = ['all'];

    // Format selected categories for subtitle
    final selectedSubtitle = selectedCategories.contains('all')
        ? "All Categories"
        : selectedCategories.length == 1
        ? _formatCategory(selectedCategories.first)
        : "${selectedCategories.length} selected";

    // Find current level object
    final currentLevel = gameLevels.firstWhere(
      (l) => l.key == selectedLevelKey,
      orElse: () => gameLevels[2],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), elevation: 0),
      body: ListView(
        children: [
          // --- Game Settings ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "GAMEPLAY",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          ListTile(
            title: Text(l10n.selectCategory),
            subtitle: Text(
              selectedSubtitle,
              style: const TextStyle(color: Colors.deepPurple),
            ),
            trailing: _isLoadingCategories
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCategoryDialog(selectedCategories, settings),
          ),
          const Divider(),

          ListTile(
            title: const Text("Game Level (Word Length)"),
            subtitle: Text(
              "${currentLevel.name} (${currentLevel.minLength}-${currentLevel.maxLength ?? '+'})",
            ),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLevelKey,
                onChanged: (String? value) async {
                  if (value != null) {
                    final level = gameLevels.firstWhere((l) => l.key == value);
                    if (level.number > 3 && !isVip) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Upgrade to VIP to unlock this level!"),
                        ),
                      );
                      return;
                    }
                    await settings.setGameLevel(value);
                  }
                },
                items: gameLevels.map((level) {
                  final isLocked = !isVip && level.number > 3;
                  return DropdownMenuItem(
                    value: level.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLocked)
                          const Icon(Icons.lock, size: 14, color: Colors.grey),
                        if (isLocked) const SizedBox(width: 8),
                        Text(
                          level.name,
                          style: TextStyle(
                            color: isLocked ? Colors.grey : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(),

          // --- App Settings ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "PREFERENCES",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          SwitchListTile(
            title: Text(l10n.sound),
            value: isSoundEnabled,
            onChanged: (val) => settings.setSoundEnabled(val),
            secondary: const Icon(Icons.volume_up_rounded),
          ),
          SwitchListTile(
            title: Text(l10n.allowSpecialChars),
            subtitle: Text(l10n.allowSpecialCharsDesc),
            value: isSpecialCharsAllowed,
            onChanged: (val) => settings.setSpecialCharsAllowed(val),
            secondary: const Icon(Icons.keyboard_alt_rounded),
          ),

          const Divider(),

          // --- Account ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "ACCOUNT",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          SwitchListTile(
            title: Text(l10n.vipMode),
            subtitle: const Text("Unlock all levels & remove ads"),
            value: isVip,
            onChanged: (val) => settings.setVip(val),
            secondary: const Icon(Icons.star_rounded, color: Colors.amber),
            activeColor: Colors.amber,
          ),

          // Google Account Integration
          StreamBuilder<User?>(
            stream: context.read<AuthRepository>().user,
            builder: (context, snapshot) {
              final user = snapshot.data;
              final isConnected = user != null;

              if (isConnected) {
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user.displayName ?? "User"),
                      subtitle: Text(user.email ?? "Connected"),
                      trailing: TextButton(
                        onPressed: () async {
                          await context.read<AuthRepository>().signOut();
                        },
                        child: const Text("Sign Out"),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Your progress is synced to the cloud.",
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                );
              } else {
                return ListTile(
                  leading: const Icon(Icons.cloud_off, color: Colors.grey),
                  title: const Text("Connect Account"),
                  subtitle: const Text("Sync progress & save stats"),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text("Connect"),
                    onPressed: () async {
                      try {
                        await context.read<AuthRepository>().signInWithGoogle();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Login Failed: $e")),
                        );
                      }
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryMultiSelectDialog extends StatefulWidget {
  final List<String> allCategories;
  final List<String> selectedCategories;
  final Function(List<String>) onSave;
  final String Function(String)? formatCategory;

  const _CategoryMultiSelectDialog({
    required this.allCategories,
    required this.selectedCategories,
    required this.onSave,
    this.formatCategory,
  });

  @override
  State<_CategoryMultiSelectDialog> createState() =>
      _CategoryMultiSelectDialogState();
}

class _CategoryMultiSelectDialogState
    extends State<_CategoryMultiSelectDialog> {
  late List<String> _currentSelection;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentSelection = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final displayedCategories = widget.allCategories.where((cat) {
      if (_searchQuery.isEmpty) return true;
      return cat.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort logic (optional but good for UX)
    displayedCategories.sort((a, b) {
      if (a == 'all') return -1;
      if (b == 'all') return 1;
      return a.compareTo(b);
    });

    return AlertDialog(
      title: const Text("Select Categories"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar
            TextField(
              decoration: const InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),

            // Toggle Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _currentSelection = ['all'];
                  }),
                  child: const Text("Reset to All"),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _currentSelection.clear();
                  }),
                  child: const Text("Clear"),
                ),
              ],
            ),

            const Divider(),

            // List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: displayedCategories.length,
                itemBuilder: (context, index) {
                  final cat = displayedCategories[index];
                  final isChecked = _currentSelection.contains(cat);

                  // Use formatter if available
                  String label = cat;
                  if (cat == 'all') {
                    label = "All Categories";
                  } else if (widget.formatCategory != null) {
                    label = widget.formatCategory!(cat);
                  }

                  return CheckboxListTile(
                    title: Text(label),
                    value: isChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        if (cat == 'all') {
                          // Exclusive 'all' logic
                          if (value == true) {
                            _currentSelection = ['all'];
                          } else {
                            _currentSelection.remove('all');
                          }
                        } else {
                          // Specific category logic
                          if (_currentSelection.contains('all')) {
                            _currentSelection.remove('all');
                          }

                          if (value == true) {
                            _currentSelection.add(cat);
                          } else {
                            _currentSelection.remove(cat);
                          }

                          // Safety fallback
                          if (_currentSelection.isEmpty) {
                            _currentSelection.add('all');
                          }
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_currentSelection);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
