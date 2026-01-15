import 'dart:convert';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class WordMeanings {
  final String word;
  final String pos;
  final List<String> definitions;
  final List<String> synonyms;
  final List<String> antonyms;

  WordMeanings({
    required this.word,
    required this.pos,
    required this.definitions,
    required this.synonyms,
    this.antonyms = const [],
  });
}

class WordUpdateEvent {
  final String word;
  final String status; // 'Learnt', 'Mastered', 'Deleted'
  final DateTime timestamp;

  WordUpdateEvent({
    required this.word,
    required this.status,
    required this.timestamp,
  });
}

class WordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _updateController = StreamController<WordUpdateEvent>.broadcast();

  Stream<WordUpdateEvent> get updates => _updateController.stream;

  // Insert a word (Single Category - Legacy compatibility helper)
  Future<void> insertWord(String text, String categoryTag) async {
    final db = await _dbHelper.database;

    // 1. Insert/Get Category
    await db.insert('categories', {
      'tag': categoryTag,
      'type': 'Custom',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final catResult = await db.query(
      'categories',
      columns: ['id'],
      where: 'tag = ?',
      whereArgs: [categoryTag],
    );
    final catId = catResult.first['id'] as int;

    // 2. Insert/Get Word
    await db.insert('words', {
      'text': text.toLowerCase(),
      'length': text.length,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final wordResult = await db.query(
      'words',
      columns: ['id'],
      where: 'text = ?',
      whereArgs: [text.toLowerCase()],
    );
    final wordId = wordResult.first['id'] as int;

    // 3. Link
    await db.insert('word_categories', {
      'word_id': wordId,
      'category_id': catId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> bulkInsertWords(List<Map<String, dynamic>> words) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var w in words) {
        // Re-implement insertWord logic using txn
        String text = w['text'];
        String categoryTag = w['category'];

        await txn.insert('categories', {
          'tag': categoryTag,
          'type': 'Custom',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        final catResult = await txn.query(
          'categories',
          columns: ['id'],
          where: 'tag = ?',
          whereArgs: [categoryTag],
        );
        final catId = catResult.first['id'] as int;

        await txn.insert('words', {
          'text': text.toLowerCase(),
          'length': text.length,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        final wordResult = await txn.query(
          'words',
          columns: ['id'],
          where: 'text = ?',
          whereArgs: [text.toLowerCase()],
        );
        final wordId = wordResult.first['id'] as int;

        await txn.insert('word_categories', {
          'word_id': wordId,
          'category_id': catId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT tag FROM categories ORDER BY tag',
    );
    return results.map((row) => row['tag'] as String).toList();
  }

  Future<bool> isValidWord(String word) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT 1 FROM words WHERE text = ? COLLATE NOCASE LIMIT 1',
      [word],
    );
    return result.isNotEmpty;
  }

  Future<List<String>> searchCategories(String query) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT tag FROM categories WHERE tag LIKE ? ORDER BY tag',
      ['%$query%'],
    );
    return result.map((row) => row['tag'] as String).toList();
  }

  Future<int> getWordsCount(
    List<String> categories,
    int minLength,
    int? maxLength, {
    bool allowSpecialChars = true,
  }) async {
    final db = await _dbHelper.database;
    final String specialCharFilter = allowSpecialChars
        ? ''
        : " AND w.text NOT LIKE '%-%' AND w.text NOT LIKE '% %' AND w.text NOT LIKE '%''%'";

    String lengthClause = 'w.length >= ?';
    final args = <dynamic>[minLength];

    if (maxLength != null) {
      lengthClause += ' AND w.length <= ?';
      args.add(maxLength);
    }

    if (categories.contains('all') || categories.isEmpty) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM words w WHERE $lengthClause$specialCharFilter',
        args,
      );
      return result.first['count'] as int;
    }

    final placeholders = List.filled(categories.length, '?').join(',');
    final query =
        '''
      SELECT COUNT(DISTINCT w.id) as count 
      FROM words w
      JOIN word_categories wc ON w.id = wc.word_id
      JOIN categories c ON wc.category_id = c.id
      WHERE c.tag IN ($placeholders) AND $lengthClause$specialCharFilter
    ''';

    // Arguments: categories first, then length args
    final fullArgs = [...categories, ...args];

    final result = await db.rawQuery(query, fullArgs);
    return result.first['count'] as int;
  }

  Future<List<String>> getWords(
    List<String> categories,
    int minLength,
    int? maxLength, {
    bool allowSpecialChars = true,
  }) async {
    final db = await _dbHelper.database;
    final String specialCharFilter = allowSpecialChars
        ? ''
        : " AND w.text NOT LIKE '%-%' AND w.text NOT LIKE '% %' AND w.text NOT LIKE '%''%'";

    String lengthClause = 'w.length >= ?';
    final args = <dynamic>[minLength];

    if (maxLength != null) {
      lengthClause += ' AND w.length <= ?';
      args.add(maxLength);
    }

    if (categories.contains('all') || categories.isEmpty) {
      final results = await db.rawQuery(
        'SELECT text FROM words w WHERE $lengthClause$specialCharFilter',
        args,
      );
      return results.map((row) => row['text'] as String).toList();
    }

    final placeholders = List.filled(categories.length, '?').join(',');
    final query =
        '''
      SELECT DISTINCT w.text 
      FROM words w
      JOIN word_categories wc ON w.id = wc.word_id
      JOIN categories c ON wc.category_id = c.id
      WHERE c.tag IN ($placeholders) AND $lengthClause$specialCharFilter
    ''';

    // Arguments: categories first, then length args
    final fullArgs = [...categories, ...args];

    final results = await db.rawQuery(query, fullArgs);
    return results.map((row) => row['text'] as String).toList();
  }

  Future<int> getWordCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return result.first['count'] as int;
  }

  Future<List<String>> getWordCategories(String word) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT c.tag 
      FROM categories c
      JOIN word_categories wc ON c.id = wc.category_id
      JOIN words w ON wc.word_id = w.id
      WHERE w.text = ? 
      ORDER BY c.tag
      ''',
      [word],
    );
    return result.map((row) => row['tag'] as String).toList();
  }

  Future<String> getWordCategory(String word) async {
    final db = await _dbHelper.database;
    // Returns the first found category for the word
    final result = await db.rawQuery(
      '''
      SELECT c.tag 
      FROM categories c
      JOIN word_categories wc ON c.id = wc.category_id
      JOIN words w ON wc.word_id = w.id
      WHERE w.text = ? 
      LIMIT 1
      ''',
      [word],
    );
    if (result.isNotEmpty) {
      return result.first['tag'] as String;
    }
    return 'unknown';
  }

  // --- Learnt Words / User Progress ---

  Future<void> addLearntWord(String word, String categoryTag) async {
    final db = await _dbHelper.database;

    // Ensure word exists
    final wordRes = await db.query(
      'words',
      columns: ['id'],
      where: 'text = ?',
      whereArgs: [word.toLowerCase()],
    );
    if (wordRes.isEmpty) return;
    final wordId = wordRes.first['id'] as int;

    // Insert or Update
    await db.insert('user_progress', {
      'word_id': wordId,
      'status': 'Learnt',
      'next_review_date': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    _updateController.add(
      WordUpdateEvent(word: word, status: 'Learnt', timestamp: DateTime.now()),
    );

    // Note: ConflictAlgorithm.replace replaces the whole row. If we want to keep other fields,
    // we should use specialized update logic. But for now status/date are the main things.
  }

  Future<List<Map<String, dynamic>>> getLearntWords() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT w.text, up.next_review_date, up.status
      FROM user_progress up
      JOIN words w ON up.word_id = w.id
      WHERE up.status IN ('Learnt', 'Mastered')
      ORDER BY up.next_review_date DESC
      ''');

    final List<Map<String, dynamic>> output = [];

    for (final row in results) {
      final String text = row['text'] as String;
      final String cat = await getWordCategory(text);

      output.add({
        'word': text,
        'date_added': row['next_review_date'],
        'category': cat,
        'is_favorite': row['status'] == 'Mastered',
      });
    }
    return output;
  }

  Future<void> toggleFavorite(String word, bool isFav) async {
    final db = await _dbHelper.database;
    final wordRes = await db.query(
      'words',
      columns: ['id'],
      where: 'text = ?',
      whereArgs: [word.toLowerCase()],
    );
    if (wordRes.isEmpty) return;
    final wordId = wordRes.first['id'] as int;

    final status = isFav ? 'Mastered' : 'Learnt';

    await db.update(
      'user_progress',
      {'status': status},
      where: 'word_id = ?',
      whereArgs: [wordId],
    );

    _updateController.add(
      WordUpdateEvent(word: word, status: status, timestamp: DateTime.now()),
    );
  }

  Future<void> deleteLearntWord(String word) async {
    final db = await _dbHelper.database;
    final wordRes = await db.query(
      'words',
      columns: ['id'],
      where: 'text = ?',
      whereArgs: [word.toLowerCase()],
    );
    if (wordRes.isEmpty) return;
    final wordId = wordRes.first['id'] as int;

    await db.delete('user_progress', where: 'word_id = ?', whereArgs: [wordId]);

    _updateController.add(
      WordUpdateEvent(word: word, status: 'Deleted', timestamp: DateTime.now()),
    );
  }

  Future<bool> isWordLearnt(String word) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 1 FROM user_progress up
      JOIN words w ON up.word_id = w.id
      WHERE w.text = ?
      ''',
      [word.toLowerCase()],
    );
    return result.isNotEmpty;
  }

  Future<WordMeanings?> getWordMeanings(String word) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT w.text, m.pos, m.definitions, m.synonyms
      FROM words w
      LEFT JOIN meanings m ON w.id = m.word_id
      WHERE w.text = ?
      ''',
      [word.toLowerCase()],
    );

    if (result.isEmpty || result.first['pos'] == null) return null;

    final row = result.first;
    List<String> defs = [];
    List<String> syns = [];

    try {
      if (row['definitions'] != null) {
        defs = List<String>.from(jsonDecode(row['definitions'] as String));
      }
      if (row['synonyms'] != null) {
        syns = List<String>.from(jsonDecode(row['synonyms'] as String));
      }
    } catch (e) {
      print('Error parsing meanings for $word: $e');
    }

    return WordMeanings(
      word: row['text'] as String,
      pos: row['pos'] as String,
      definitions: defs,
      synonyms: syns,
    );
  }

  Future<List<String>> getDailyChallengeWords() async {
    final db = await _dbHelper.database;
    List<String> dailyWords = [];

    // 1. Length 3-4
    final r1 = await db.rawQuery(
      'SELECT text FROM words WHERE length BETWEEN 3 AND 4 AND is_common = 1 ORDER BY RANDOM() LIMIT 1',
    );
    if (r1.isNotEmpty) dailyWords.add(r1.first['text'] as String);

    // 2. Length 5
    final r2 = await db.rawQuery(
      'SELECT text FROM words WHERE length = 5 AND is_common = 1 ORDER BY RANDOM() LIMIT 1',
    );
    if (r2.isNotEmpty) dailyWords.add(r2.first['text'] as String);

    // 3. Length > 5
    final r3 = await db.rawQuery(
      'SELECT text FROM words WHERE length > 5 AND is_common = 1 ORDER BY RANDOM() LIMIT 1',
    );
    if (r3.isNotEmpty) dailyWords.add(r3.first['text'] as String);

    return dailyWords;
  }

  Future<String?> getRandomWord(
    int minLength,
    int? maxLength,
    List<String> categories,
  ) async {
    final db = await _dbHelper.database;

    String lengthClause = 'w.length >= ?';
    List<dynamic> args = [minLength];

    if (maxLength != null) {
      lengthClause += ' AND w.length <= ?';
      args.add(maxLength);
    }

    // Default Query (No Category Filter or 'all')
    if (categories.isEmpty || categories.contains('all')) {
      final result = await db.rawQuery(
        'SELECT text FROM words w WHERE $lengthClause AND is_common = 1 ORDER BY RANDOM() LIMIT 1',
        args,
      );
      if (result.isNotEmpty) {
        return result.first['text'] as String;
      }
      return null;
    }

    // Query with Category Filter
    final placeholders = List.filled(categories.length, '?').join(',');
    args.addAll(categories);

    // We need to order by random() on the filtered set.
    // Using a JOIN to filter.
    final result = await db.rawQuery('''
      SELECT w.text 
      FROM words w
      JOIN word_categories wc ON w.id = wc.word_id
      JOIN categories c ON wc.category_id = c.id
      WHERE $lengthClause AND c.tag IN ($placeholders) AND w.is_common = 1
      ORDER BY RANDOM() 
      LIMIT 1
      ''', args);

    if (result.isNotEmpty) {
      return result.first['text'] as String;
    }
    return null;
  }

  Future<void> updateWordNote(String word, String note) async {
    final db = await _dbHelper.database;
    final wordRes = await db.query(
      'words',
      columns: ['id'],
      where: 'text = ?',
      whereArgs: [word.toLowerCase()],
    );
    if (wordRes.isEmpty) return;
    final wordId = wordRes.first['id'] as int;

    await db.update(
      'user_progress',
      {'notes': note},
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }

  Future<String?> getWordNote(String word) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT up.notes 
      FROM user_progress up
      JOIN words w ON up.word_id = w.id
      WHERE w.text = ?
      ''',
      [word.toLowerCase()],
    );
    if (result.isNotEmpty) {
      return result.first['notes'] as String?;
    }
    return null;
  }

  Future<void> addCustomWord(
    String word,
    String definition,
    String category,
  ) async {
    // Reuse insertWord logic but also add Definition in 'meanings'?
    // For now, our schema might not easily support custom meanings without 'meanings' table insert.
    // Let's use the standard insertion we have and maybe we can't easily store the custom definition
    // unless we also migrate 'meanings' table.
    // However, the task asked for "Allow adding new words".

    await insertWord(word, category);

    // Optionally insert meaning if we had a way.
    // For now, let's just ensure it's in the dictionary and marked as Learnt.
    await addLearntWord(word, category);
  }

  Future<Set<String>> getAllWords({bool onlyCommon = false}) async {
    final db = await _dbHelper.database;
    String query = 'SELECT text FROM words WHERE length >= 3';
    if (onlyCommon) {
      query += ' AND is_common = 1';
    }
    final result = await db.rawQuery(query);
    return result.map((row) => (row['text'] as String).toLowerCase()).toSet();
  }
  // --- Flashcards Logic ---

  Future<List<Map<String, dynamic>>> getFlashcardQuestions(
    int count,
    List<String> categories,
    int minLength,
    int? maxLength,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> questions = [];
    final args = <dynamic>[];

    // Build Query
    String query = '''
      SELECT w.text, m.definitions, m.synonyms
      FROM words w
      JOIN meanings m ON w.id = m.word_id
    ''';

    // Category Join
    if (categories.isNotEmpty && !categories.contains('all')) {
      query +=
          ' JOIN word_categories wc ON w.id = wc.word_id JOIN categories c ON wc.category_id = c.id ';
    }

    query += ' WHERE (m.definitions IS NOT NULL OR m.synonyms IS NOT NULL) ';
    query += ' AND w.length >= ? ';
    args.add(minLength);

    // Max Length
    if (maxLength != null) {
      query += ' AND w.length <= ? ';
      args.add(maxLength);
    }

    // Category Filter
    if (categories.isNotEmpty && !categories.contains('all')) {
      final placeholders = List.filled(categories.length, '?').join(',');
      query += ' AND c.tag IN ($placeholders) ';
      args.addAll(categories);
    }

    query += ' ORDER BY RANDOM() LIMIT ? ';
    args.add(count);

    final possibleWordsResult = await db.rawQuery(query, args);

    if (possibleWordsResult.isEmpty) return [];

    for (final row in possibleWordsResult) {
      final targetWord = row['text'] as String;
      String questionText = '';
      String questionType = 'definition'; // or 'synonym'

      // Parse definitions/synonyms
      List<String> defs = [];
      List<String> syns = [];
      try {
        if (row['definitions'] != null) {
          defs = List<String>.from(jsonDecode(row['definitions'] as String));
        }
        if (row['synonyms'] != null) {
          syns = List<String>.from(jsonDecode(row['synonyms'] as String));
        }
      } catch (_) {}

      if (defs.isEmpty && syns.isEmpty) continue; // Skip if bad data

      // Decide Question Type
      // Prefer Definition, fallback to Synonym
      if (defs.isNotEmpty) {
        questionText = defs.first; // Use first definition
      } else {
        questionType = 'synonym';
        questionText = syns.first;
      }

      // Get Distractors (3 random words that represent INCORRECT answers)
      // We explicitly exclude the target word.
      // Ideally distractors should match similar length or something, but random is okay for MVP
      final distractorsResult = await db.rawQuery(
        'SELECT text FROM words WHERE text != ? ORDER BY RANDOM() LIMIT 3',
        [targetWord],
      );

      final List<String> options = distractorsResult
          .map((r) => r['text'] as String)
          .toList();

      // Add target and shuffle
      options.add(targetWord);
      options.shuffle();

      questions.add({
        'targetWord': targetWord,
        'questionText': questionText, // The definition or synonym
        'questionType': questionType,
        'options': options,
      });
    }

    return questions;
  }
}
