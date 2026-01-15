import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // For Timer

import '../data/word_repository.dart';
import '../data/auth_repository.dart';

class WordDetailScreen extends StatefulWidget {
  final String word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _noteController = TextEditingController();
  WordMeanings? _meanings;
  bool _isLoading = true;
  Timer? _debounce;
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _checkVipStatus();
    _loadData();
  }

  void _checkVipStatus() {
    // Simple check: if user is logged in, they are VIP (for now)
    final user = context.read<AuthRepository>().currentUser;
    setState(() {
      _isVip = user != null;
    });
  }

  Future<void> _loadData() async {
    final repo = context.read<WordRepository>();

    // Load Meanings
    final meanings = await repo.getWordMeanings(widget.word);

    // Load Note
    final note = await repo.getWordNote(widget.word);

    if (mounted) {
      setState(() {
        _meanings = meanings;
        if (note != null) {
          _noteController.text = note;
        }
        _isLoading = false;
      });
    }
  }

  void _saveNote(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      context.read<WordRepository>().updateWordNote(widget.word, value);
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    _noteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _speak() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(widget.word);
  }

  Future<void> _openDictionary(String name, String urlTemplate) async {
    final uri = Uri.parse(
      urlTemplate.replaceAll('{word}', widget.word.toLowerCase()),
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $name')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.word.toUpperCase())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Word & TTS
                    Center(
                      child: Column(
                        children: [
                          Text(
                            widget.word.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_meanings?.pos != null)
                            Text(
                              _meanings!.pos, // e.g., 'noun', 'verb'
                              style: const TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _speak,
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Pronounce'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Definitions
                    if (_meanings?.definitions.isNotEmpty ?? false) ...[
                      _buildSectionTitle('Definitions'),
                      ..._meanings!.definitions.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(child: Text(d)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Synonyms
                    if (_meanings?.synonyms.isNotEmpty ?? false) ...[
                      _buildSectionTitle('Synonyms'),
                      Wrap(
                        spacing: 8.0,
                        children: _meanings!.synonyms
                            .map(
                              (s) => Chip(
                                label: Text(s),
                                backgroundColor: Colors.deepPurple[50],
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // VIP Notes
                    _buildSectionTitle(
                      'Personal Notes ${_isVip ? "(VIP)" : "(Locked)"}',
                    ),
                    if (_isVip)
                      TextField(
                        controller: _noteController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Add your own notes, mnemonics, or examples here...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: _saveNote,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Only VIP members can add personal notes.",
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),

                    // External Links
                    const Text(
                      'External Resources',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDictButton(
                      'Google Dictionary',
                      'https://www.google.com/search?q=define+{word}',
                      Icons.search,
                    ),
                    _buildDictButton(
                      'Cambridge Dictionary',
                      'https://dictionary.cambridge.org/dictionary/english/{word}',
                      Icons.menu_book,
                    ),
                    _buildDictButton(
                      'Merriam-Webster',
                      'https://www.merriam-webster.com/dictionary/{word}',
                      Icons.book,
                    ),

                    const SizedBox(height: 30),
                    // Disclaimer...
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildDictButton(String name, String url, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(name),
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: () => _openDictionary(name, url),
      ),
    );
  }
}
