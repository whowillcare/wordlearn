import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class WordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
    int maxLength, {
    bool allowSpecialChars = true,
  }) async {
    final db = await _dbHelper.database;
    final String specialCharFilter = allowSpecialChars
        ? ''
        : " AND w.text NOT LIKE '%-%' AND w.text NOT LIKE '% %' AND w.text NOT LIKE '%''%'";

    if (categories.contains('all') || categories.isEmpty) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM words w WHERE length >= ? AND length <= ?$specialCharFilter',
        [minLength, maxLength],
      );
      return result.first['count'] as int;
    }

    final placeholders = List.filled(categories.length, '?').join(',');
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT w.id) as count 
      FROM words w
      JOIN word_categories wc ON w.id = wc.word_id
      JOIN categories c ON wc.category_id = c.id
      WHERE c.tag IN ($placeholders) AND w.length >= ? AND w.length <= ?$specialCharFilter
      ''',
      [...categories, minLength, maxLength],
    );
    return result.first['count'] as int;
  }

  Future<List<String>> getWords(
    List<String> categories,
    int minLength,
    int maxLength, {
    bool allowSpecialChars = true,
  }) async {
    final db = await _dbHelper.database;
    final String specialCharFilter = allowSpecialChars
        ? ''
        : " AND w.text NOT LIKE '%-%' AND w.text NOT LIKE '% %' AND w.text NOT LIKE '%''%'";

    if (categories.contains('all') || categories.isEmpty) {
      final results = await db.rawQuery(
        'SELECT text FROM words w WHERE length >= ? AND length <= ?$specialCharFilter',
        [minLength, maxLength],
      );
      return results.map((row) => row['text'] as String).toList();
    }

    final placeholders = List.filled(categories.length, '?').join(',');
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT w.text 
      FROM words w
      JOIN word_categories wc ON w.id = wc.word_id
      JOIN categories c ON wc.category_id = c.id
      WHERE c.tag IN ($placeholders) AND w.length >= ? AND w.length <= ?$specialCharFilter
      ''',
      [...categories, minLength, maxLength],
    );
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
}
