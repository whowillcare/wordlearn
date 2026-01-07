import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'word_repository.dart';
import 'ingestion_result.dart';

class DataIngester {
  final WordRepository _repository;

  DataIngester(this._repository);

  Future<IngestionResult> ingestData() async {
    final int currentCount = await _repository.getWordCount();
    final List<String> errors = [];
    int filesFound = 0;

    // We proceed even if count > 0 to gather stats, but skip insert if > 0
    if (currentCount > 0) {
      return IngestionResult(
        success: true,
        initialCount: currentCount,
        finalCount: currentCount,
        filesFound: 0, // Skipped scan
        errors: [],
      );
    }
    print('Starting explicit data ingestion check...');

    try {
      // final manifestContent = await rootBundle.loadString('AssetManifest.json');
      // final Map<String, dynamic> manifest = json.decode(manifestContent);

      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final wordFiles = manifest
          .listAssets()
          .where(
            (key) => key.startsWith('assets/data/') && key.endsWith('.json'),
          )
          .toList();

      filesFound = wordFiles.length;
      print('Found ${filesFound} data files to ingest.');

      for (final filePath in wordFiles) {
        try {
          final String fileName = p.basename(filePath);
          final String category = fileName.replaceAll('.json', '');

          final String jsonContent = await rootBundle.loadString(filePath);
          final dynamic parsed = json.decode(jsonContent);

          if (parsed is List) {
            final List<String> words = parsed.map((e) => e.toString()).toList();
            if (words.isNotEmpty) {
              final List<Map<String, dynamic>> batch = words
                  .map((w) => {'text': w, 'category': category})
                  .toList();

              await _repository.bulkInsertWords(batch);
              print('Ingested ${words.length} words for category: $category');
            }
          }
        } catch (e) {
          String err = 'Error ingesting file $filePath: $e';
          print(err);
          errors.add(err);
        }
      }
      print(
        'Data ingestion complete. Total words: ${await _repository.getWordCount()}',
      );
    } catch (e) {
      String err = 'Error loading asset manifest: $e';
      print(err);
      errors.add(err);
      return IngestionResult(
        success: false,
        initialCount: currentCount,
        finalCount: await _repository.getWordCount(),
        filesFound: filesFound,
        errors: errors,
      );
    }

    return IngestionResult(
      success: errors.isEmpty,
      initialCount: currentCount,
      finalCount: await _repository.getWordCount(),
      filesFound: filesFound,
      errors: errors,
    );
  }
}
