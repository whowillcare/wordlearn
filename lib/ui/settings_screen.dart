import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/settings_repository.dart';
import '../data/word_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isSoundEnabled;
  late bool _isVip;
  String? _defaultCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsRepository>();
    _isSoundEnabled = settings.isSoundEnabled;
    _isVip = settings.isVip;
    _defaultCategory = settings.defaultCategory;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await context.read<WordRepository>().getCategories();
    setState(() {
      _categories = cats;
    });
  }

  Future<void> _toggleSound(bool value) async {
    await context.read<SettingsRepository>().setSoundEnabled(value);
    setState(() {
      _isSoundEnabled = value;
    });
  }

  Future<void> _toggleVip(bool value) async {
    await context.read<SettingsRepository>().setVip(value);
    setState(() {
      _isVip = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound Effects'),
            subtitle: const Text('Enable sound effects during game'),
            value: _isSoundEnabled,
            onChanged: _toggleSound,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('VIP Mode'),
            subtitle: const Text('Unlock exclusive features (Simulation)'),
            value: _isVip,
            onChanged: _toggleVip,
          ),
          const Divider(),
          ListTile(
            title: const Text('Default Category'),
            subtitle: Text(_defaultCategory ?? 'None'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                await context.read<SettingsRepository>().setDefaultCategory(
                  value,
                );
                setState(() {
                  _defaultCategory = value;
                });
              },
              itemBuilder: (context) {
                return _categories
                    .map((c) => PopupMenuItem(value: c, child: Text(c)))
                    .toList();
              },
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Language'),
            subtitle: Text('English (Default)'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}
