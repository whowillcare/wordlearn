import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final filename = join(docsDir.path, 'wordlearn.db');
    final db = sqlite3.open(filename);

    db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        length INTEGER NOT NULL,
        category TEXT NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_category_length ON words (category, length);

      CREATE TABLE IF NOT EXISTS learnt_words (
        word TEXT PRIMARY KEY,
        date_added INTEGER NOT NULL
      );
    ''');

    final result = db.select('SELECT count(*) as count FROM words');
    if (result.isNotEmpty && result.first['count'] == 0) {
      await _populateDatabase(db);
    }

    // Migrations
    try {
      db.execute(
        'ALTER TABLE learnt_words ADD COLUMN is_favorite INTEGER DEFAULT 0',
      );
    } catch (_) {} // Column likely exists

    try {
      db.execute('ALTER TABLE learnt_words ADD COLUMN category TEXT');
    } catch (_) {} // Column likely exists

    return db;
  }

  Future<void> _populateDatabase(Database db) async {
    try {
      // final manifestContent = await rootBundle.loadString('AssetManifest.json');
      // final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final wordFiles = manifest
          .listAssets()
          .where(
            (String key) =>
                key.startsWith('assets/data/') && key.endsWith('.json'),
          )
          .toList();

      if (wordFiles.isEmpty) {
        print('No word files found in assets.');
        return;
      }

      final stmt = db.prepare(
        'INSERT INTO words (text, length, category) VALUES (?, ?, ?)',
      );

      db.execute('BEGIN TRANSACTION');

      for (final file in wordFiles) {
        try {
          final jsonString = await rootBundle.loadString(file);
          final List<dynamic> words = json.decode(jsonString);
          // file is like "assets/words/grade-1.json"
          String category = basenameWithoutExtension(file);
          // basenameWithoutExtension needs package:path, which is already imported as join coming from there?
          // Wait, 'package:path/path.dart' gives `join`. `basenameWithoutExtension` is also in there.

          for (final word in words) {
            if (word is String && word.isNotEmpty) {
              stmt.execute([word, word.length, category]);
            }
          }
          print('Loaded ${words.length} words from $category');
        } catch (e) {
          print('Error loading $file: $e');
        }
      }

      db.execute('COMMIT');
      stmt.dispose();
      print('Database populated successfully.');
    } catch (e) {
      print('Error populating database: $e');
      // Ensure transaction is rolled back if meaningful, or just log.
      // Since we manually controlled transaction, let's keep it simple for now.
    }
  }
}
