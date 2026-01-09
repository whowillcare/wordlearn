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
      -- Words Table
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL UNIQUE,
        length INTEGER NOT NULL,
        phonetic TEXT,
        definition TEXT
      );
      
      -- Categories Table
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL
      );

      -- Junction Table (Word <-> Category)
      CREATE TABLE IF NOT EXISTS word_categories (
        word_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        PRIMARY KEY (word_id, category_id),
        FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      );

      -- Synonyms Table (Thesaurus)
      CREATE TABLE IF NOT EXISTS synonyms (
        word_id INTEGER NOT NULL,
        synonym_text TEXT NOT NULL,
        PRIMARY KEY (word_id, synonym_text),
        FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
      );

      -- User Progress (Legacy 'learnt_words' replaced/upgraded)
      CREATE TABLE IF NOT EXISTS user_progress (
        word_id INTEGER PRIMARY KEY,
        status TEXT DEFAULT 'New', -- New, Learnt, Mastered
        next_review_date INTEGER,
        synonyms_found_count INTEGER DEFAULT 0,
        FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
      );
      
      -- Indices for performance
      CREATE INDEX IF NOT EXISTS idx_word_text ON words(text);
      CREATE INDEX IF NOT EXISTS idx_category_tag ON categories(tag);
    ''');

    // Simple count check to trigger population
    final result = db.select('SELECT count(*) as count FROM words');
    if (result.isNotEmpty && result.first['count'] == 0) {
      await _populateDatabase(db);
    }

    // Legacy migration support (Optional: if we want to migrate old 'learnt_words' to 'user_progress',
    // we would do it here, but for this complete overhaul, we start fresh or assume user is ok with reset
    // strictly for the structure update).
    // For now, we leave legacy 'learnt_words' as is to avoid data loss, but the app will use 'user_progress'.

    return db;
  }

  Future<void> _populateDatabase(Database db, {List<String>? onlyFiles}) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      List<String> wordFiles;

      if (onlyFiles != null) {
        wordFiles = onlyFiles;
      } else {
        wordFiles = manifest
            .listAssets()
            .where(
              (String key) =>
                  key.startsWith('assets/data/') && key.endsWith('.json'),
            )
            .toList();
      }

      if (wordFiles.isEmpty) {
        print('No word files found in assets.');
        return;
      }

      final insertWordStmt = db.prepare(
        'INSERT OR IGNORE INTO words (text, length) VALUES (?, ?)',
      );
      final selectWordIdStmt = db.prepare(
        'SELECT id FROM words WHERE text = ?',
      );
      final insertCategoryStmt = db.prepare(
        'INSERT OR IGNORE INTO categories (tag, type) VALUES (?, ?)',
      );
      final selectCategoryIdStmt = db.prepare(
        'SELECT id FROM categories WHERE tag = ?',
      );
      final insertWordCategoryStmt = db.prepare(
        'INSERT OR IGNORE INTO word_categories (word_id, category_id) VALUES (?, ?)',
      );

      db.execute('BEGIN TRANSACTION');

      for (final file in wordFiles) {
        try {
          final jsonString = await rootBundle.loadString(file);
          final dynamic jsonContent = json.decode(jsonString);
          final List<String> words = [];

          // Helper to extract strings
          void addWords(dynamic content) {
            if (content is List) {
              for (var item in content) {
                if (item is String) words.add(item);
              }
            } else if (content is Map) {
              for (var value in content.values) {
                addWords(value);
              }
            }
          }

          addWords(jsonContent);

          // Category derivation from filename
          // e.g., "assets/data/grade-1-math.json" -> tag: "grade-1-math", type: "Topic" (simplified)
          String categoryTag = basenameWithoutExtension(file);
          // Simple heuristic for category type, can be refined later
          String categoryType = 'Topic';
          if (categoryTag.startsWith('grade')) categoryType = 'Grade';

          // Insert Category
          insertCategoryStmt.execute([categoryTag, categoryType]);
          final catIdResult = selectCategoryIdStmt.select([categoryTag]);
          if (catIdResult.isEmpty) {
            print('Error: Failed to retrieve ID for category: $categoryTag');
            continue;
          }
          final categoryId = catIdResult.first['id'];
          print('Processing category: $categoryTag (ID: $categoryId)');

          for (final word in words) {
            if (word.isNotEmpty) {
              // Insert Word
              insertWordStmt.execute([word, word.length]);

              // Get Word ID
              final wordIdResult = selectWordIdStmt.select([word]);
              if (wordIdResult.isNotEmpty) {
                final wordId = wordIdResult.first['id'];
                // Link Word to Category
                insertWordCategoryStmt.execute([wordId, categoryId]);
              }
            }
          }
          print('Loaded ${words.length} tags for "$categoryTag"');
        } catch (e) {
          print('Error loading $file: $e');
        }
      }

      db.execute('COMMIT');
      insertWordStmt.dispose();
      selectWordIdStmt.dispose();
      insertCategoryStmt.dispose();
      selectCategoryIdStmt.dispose();
      insertWordCategoryStmt.dispose();

      print('Database populated successfully with Multi-Category support.');
    } catch (e) {
      print('Error populating database: $e');
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
    }
  }
}
