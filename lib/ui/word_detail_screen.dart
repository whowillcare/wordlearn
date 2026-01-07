import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WordDetailScreen extends StatefulWidget {
  final String word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();
  // Since we don't have local definitions working yet, we'll placeholder or use a webview?
  // For MVP, just the word and pronunciation button.

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.word.toUpperCase())),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              widget.word.toUpperCase(),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _speak,
              icon: const Icon(Icons.volume_up),
              label: const Text('Pronounce'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Definition',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Definition feature is currently using placeholder data as local dictionary files were unavailable. Future updates will fetch from online dictionary.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
