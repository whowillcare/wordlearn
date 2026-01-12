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

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final repo = context.read<WordRepository>();
      final isLearnt = await repo.isWordLearnt(widget.word);
      if (mounted) {
        setState(() {
          _isLearnt = isLearnt;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking word status: $e');
      if (mounted) {
        setState(() {
          _isLearnt = false; // Default to false
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
        // We need a category. For now, fetch generic or existing.
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Tap the bookmark to add or remove this word from your library.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const CircularProgressIndicator()
          else
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
          if (_isLearnt == true && !_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text("Saved!", style: TextStyle(color: Colors.green)),
            ),
          const SizedBox(height: 10),
          const BannerAdWidget(),
        ],
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
