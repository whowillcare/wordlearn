import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/word_repository.dart';
import '../../l10n/app_localizations.dart';
import 'banner_ad_widget.dart';

class WordDetailDialog extends StatefulWidget {
  final String word;

  const WordDetailDialog({Key? key, required this.word}) : super(key: key);

  @override
  State<WordDetailDialog> createState() => _WordDetailDialogState();
}

class _WordDetailDialogState extends State<WordDetailDialog> {
  bool? _isLearnt;
  bool _isLoading = true;
  WordMeanings? _meanings;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<WordRepository>();
      final isLearnt = await repo.isWordLearnt(widget.word);
      final meanings = await repo.getWordMeanings(widget.word);

      if (mounted) {
        setState(() {
          _isLearnt = isLearnt;
          _meanings = meanings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading word details: $e');
      if (mounted) {
        setState(() {
          _isLearnt = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleStatus() async {
    bool currentStatus = _isLearnt ?? false;
    setState(() => _isLoading = true);

    final repo = context.read<WordRepository>();
    try {
      if (currentStatus) {
        await repo.deleteLearntWord(widget.word);
        if (mounted) setState(() => _isLearnt = false);
      } else {
        final category = await repo.getWordCategory(widget.word);
        await repo.addLearntWord(widget.word, category);
        if (mounted) setState(() => _isLearnt = true);
      }
    } catch (e) {
      print('Error toggling status: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating library: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.word.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_meanings != null) ...[
                if (_meanings!.pos.isNotEmpty)
                  Text(
                    _meanings!.pos,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 10),
                if (_meanings!.definitions.isNotEmpty)
                  ..._meanings!.definitions
                      .take(3)
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(d, textAlign: TextAlign.center),
                        ),
                      ),

                if (_meanings!.synonyms.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Synonyms:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    _meanings!.synonyms.take(5).join(', '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ],
              ] else
                const Text(
                  "No definitions found.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),

              const SizedBox(height: 20),

              const Text(
                "Tap the bookmark to add or remove from library.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 10),
              IconButton(
                onPressed: _toggleStatus,
                icon: Icon(
                  _isLearnt == true ? Icons.bookmark : Icons.bookmark_border,
                  size: 48,
                  color: _isLearnt == true ? Colors.deepPurple : Colors.grey,
                ),
                tooltip: _isLearnt == true
                    ? 'Remove from Library'
                    : 'Add to Library',
              ),
              if (_isLearnt == true)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text("Saved!", style: TextStyle(color: Colors.green)),
                ),
            ],
            const SizedBox(height: 10),
            const BannerAdWidget(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _isLearnt),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
