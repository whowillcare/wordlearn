import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

class WordDetailScreen extends StatefulWidget {
  final String word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void dispose() {
    flutterTts.stop();
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
      body: Padding(
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
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _speak,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Pronounce'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // External Links
              const Text(
                'External Resources',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Disclaimer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This app is not affiliated with the dictionary providers listed above. These links open external websites in a browser view for educational purposes only.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
