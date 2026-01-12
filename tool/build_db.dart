import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final cwd = Directory.current.path;
  print('Building dictionary.db from $cwd ...');

  final dbPath = p.join(cwd, 'assets', 'dictionary.db');
  final dbFile = File(dbPath);

  if (dbFile.existsSync()) {
    print('Deleting existing DB at $dbPath');
    dbFile.deleteSync();
  }

  // Ensure assets directory exists
  dbFile.parent.createSync(recursive: true);

  final db = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) async {
      await _createSchema(db);
    },
  );

  // 2. Ingest Word Data
  await _ingestWordData(db);

  // 3. Ingest Thesaurus
  await _ingestThesaurus(db);

  print('Database built successfully at $dbPath');
  await db.close();

  // Verify size
  final stat = await dbFile.stat();
  print('Final DB Size: ${stat.size} bytes');
}

Future<void> _createSchema(Database db) async {
  print('Creating schema...');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tag TEXT NOT NULL UNIQUE
    );
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      text TEXT NOT NULL UNIQUE,
      length INTEGER,
      is_common INTEGER DEFAULT 0
    );
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS word_categories (
      word_id INTEGER,
      category_id INTEGER,
      PRIMARY KEY (word_id, category_id),
      FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
    );
  ''');

  // Thesaurus Tables
  await db.execute('''
    CREATE TABLE IF NOT EXISTS meanings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word_id INTEGER NOT NULL,
      pos TEXT, 
      definitions TEXT, -- JSON array
      synonyms TEXT, -- JSON array
      FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
    );
  ''');

  // Index for faster lookups
  await db.execute('CREATE INDEX IF NOT EXISTS idx_word_text ON words(text);');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_meanings_word_id ON meanings(word_id);',
  );
}

Future<void> _ingestWordData(Database db) async {
  print('Ingesting word data...');
  final dataDir = Directory(
    p.join(Directory.current.path, 'dictionary', 'data'),
  );
  if (!dataDir.existsSync()) {
    print('Error: dictionary/data directory not found at ${dataDir.path}!');
    return;
  }

  final files = dataDir.listSync().where((f) => f.path.endsWith('.json'));
  final Map<String, int> categoryCache = {};
  int wordCount = 0;

  await db.transaction((txn) async {
    // Helper to insert word and link categories
    Future<void> insertWord(String wordRaw, List<String> categories) async {
      String? word = wordRaw.toString().toLowerCase().trim();
      if (word.isEmpty) return;

      List<Map> res = await txn.query(
        'words',
        columns: ['id'],
        where: 'text = ?',
        whereArgs: [word],
      );
      int wordId;
      if (res.isNotEmpty) {
        wordId = res.first['id'] as int;
      } else {
        wordId = await txn.insert('words', {
          'text': word,
          'length': word.length,
          'is_common': 1,
        });
        wordCount++;
      }

      for (var cat in categories) {
        String tag = cat.toString().trim();
        if (tag.isEmpty) continue;

        int catId;
        if (categoryCache.containsKey(tag)) {
          catId = categoryCache[tag]!;
        } else {
          List<Map> cRes = await txn.query(
            'categories',
            columns: ['id'],
            where: 'tag = ?',
            whereArgs: [tag],
          );
          if (cRes.isNotEmpty) {
            catId = cRes.first['id'] as int;
          } else {
            catId = await txn.insert('categories', {'tag': tag});
          }
          categoryCache[tag] = catId;
        }
        await txn.insert('word_categories', {
          'word_id': wordId,
          'category_id': catId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    for (final file in files) {
      if (file is File) {
        print('Processing ${p.basename(file.path)}...');
        final content = file.readAsStringSync();
        dynamic jsonContent;
        try {
          jsonContent = jsonDecode(content);
        } catch (e) {
          print('Error parsing JSON in ${file.path}: $e');
          continue;
        }

        if (jsonContent is List) {
          if (jsonContent.isEmpty) continue;

          if (jsonContent.first is String) {
            // Format 1: ["word1", "word2"] -> Category is filename
            String filename = p.basename(file.path);
            String category = filename.substring(0, filename.lastIndexOf('.'));
            for (var item in jsonContent) {
              await insertWord(item.toString(), [category]);
            }
          } else if (jsonContent.first is Map) {
            // Format 3: [{"word": "...", "categories": [...]}]
            for (var item in jsonContent) {
              if (item is Map) {
                await insertWord(
                  item['word']?.toString() ?? '',
                  (item['categories'] as List<dynamic>?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      [],
                );
              }
            }
          }
        } else if (jsonContent is Map) {
          // Format 2: {"category": ["word", ...]}
          for (var entry in jsonContent.entries) {
            String category = entry.key;
            if (entry.value is List) {
              for (var item in entry.value) {
                await insertWord(item.toString(), [category]);
              }
            }
          }
        }
      }
    }
  });
  print('Ingested $wordCount new words.');
}

Future<void> _ingestThesaurus(Database db) async {
  print('Ingesting thesaurus...');
  final file = File(
    p.join(Directory.current.path, 'dictionary', 'other', 'en_thesaurus.jsonl'),
  );
  if (!file.existsSync()) {
    print('Thesaurus file not found at ${file.path}, skipping.');
    return;
  }

  final lines = await file.readAsLines();
  int count = 0;
  const int batchSize = 1000;

  for (int i = 0; i < lines.length; i += batchSize) {
    int end = (i + batchSize < lines.length) ? i + batchSize : lines.length;
    var batchLines = lines.sublist(i, end);

    await db.transaction((txn) async {
      for (final line in batchLines) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          String word = data['word'].toString().toLowerCase().trim();

          int wordId;
          List<Map> res = await txn.query(
            'words',
            columns: ['id'],
            where: 'text = ?',
            whereArgs: [word],
          );
          if (res.isNotEmpty) {
            wordId = res.first['id'] as int;
          } else {
            wordId = await txn.insert('words', {
              'text': word,
              'length': word.length,
              'is_common': 0,
            });
          }

          String pos = data['pos'] ?? '';
          String defs = jsonEncode(data['desc'] ?? []);
          String syns = jsonEncode(data['synonyms'] ?? []);

          await txn.insert('meanings', {
            'word_id': wordId,
            'pos': pos,
            'definitions': defs,
            'synonyms': syns,
          });
          count++;
        } catch (e) {
          print('Error parsing line: $e');
        }
      }
    });
    print('Processed $end / ${lines.length} thesaurus entries...');
  }
  print('Ingested $count thesaurus entries.');
}
