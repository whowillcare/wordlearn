import 'package:sqlite3/sqlite3.dart';
import 'database_helper.dart';

class WordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Insert a word (Single Category - Legacy compatibility helper)
  // In new system, prefer using bulk ingest or dedicated multi-category logic
  Future<void> insertWord(String text, String categoryTag) async {
    final db = await _dbHelper.database;

    // 1. Insert/Get Category
    db.execute('INSERT OR IGNORE INTO categories (tag, type) VALUES (?, ?)', [
      categoryTag,
      'Custom',
    ]);
    final catResult = db.select('SELECT id FROM categories WHERE tag = ?', [
      categoryTag,
    ]);
    final catId = catResult.first['id'];

    // 2. Insert/Get Word
    db.execute('INSERT OR IGNORE INTO words (text, length) VALUES (?, ?)', [
      text.toLowerCase(),
      text.length,
    ]);
    final wordResult = db.select('SELECT id FROM words WHERE text = ?', [
      text.toLowerCase(),
    ]);
    final wordId = wordResult.first['id'];

    // 3. Link
    db.execute(
      'INSERT OR IGNORE INTO word_categories (word_id, category_id) VALUES (?, ?)',
      [wordId, catId],
    );
  }

  Future<void> bulkInsertWords(List<Map<String, dynamic>> words) async {
    // This logic is mostly handled by data_ingester/database_helper now.
    // Keeping this stub or simple implementation if needed for runtime additions.
    // For now, simple loop wrapper.
    final db = await _dbHelper.database;
    db.execute('BEGIN TRANSACTION');
    try {
      for (var w in words) {
        await insertWord(w['text'], w['category']);
      }
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final ResultSet results = db.select(
      'SELECT DISTINCT tag FROM categories ORDER BY tag',
    );
    return results.map((row) => row['tag'] as String).toList();
  }

  Future<bool> isValidWord(String word) async {
    final db = await _dbHelper.database;
    final result = db.select(
      'SELECT 1 FROM words WHERE text = ? COLLATE NOCASE LIMIT 1',
      [word],
    );
    return result.isNotEmpty;
  }

  Future<List<String>> searchCategories(String query) async {
    final db = await _dbHelper.database;
    final result = db.select(
      'SELECT DISTINCT tag FROM categories WHERE tag LIKE ? ORDER BY tag',
      ['%$query%'],
    );
    return result.map((row) => row['tag'] as String).toList();
  }

  Future<int> getWordsCount(
    List<String> categories,
    int minLength,
    int maxLength,
  ) async {
    final db = await _dbHelper.database;
    if (categories.contains('all') || categories.isEmpty) {
      final result = db.select(
        'SELECT COUNT(*) as count FROM words WHERE length >= ? AND length <= ?',
        [minLength, maxLength],
      );
      return result.first['count'] as int;
    }

    final placeholders = List.filled(categories.length, '?').join(',');
    final result = db.select(
      '''
      SELECT COUNT(DISTINCT w.id) as count 
      FROM words w
      JOIN word_categories wc ON w.id = wc.word_id
      JOIN categories c ON wc.category_id = c.id
      WHERE c.tag IN ($placeholders) AND w.length >= ? AND w.length <= ?
      ''',
      [...categories, minLength, maxLength],
    );
    return result.first['count'] as int;
  }

  Future<List<String>> getWords(
    List<String> categories,
    int minLength,
    int maxLength,
  ) async {
    final db = await _dbHelper.database;
    if (categories.contains('all') || categories.isEmpty) {
      final stmt = db.prepare(
        'SELECT text FROM words WHERE length >= ? AND length <= ?',
      );
      final ResultSet results = stmt.select([minLength, maxLength]);
      stmt.close();
      return results.map((row) => row['text'] as String).toList();
    }

    final placeholders = List.filled(categories.length, '?').join(',');
    final stmt = db.prepare('''
      SELECT DISTINCT w.text 
      FROM words w
      JOIN word_categories wc ON w.id = wc.word_id
      JOIN categories c ON wc.category_id = c.id
      WHERE c.tag IN ($placeholders) AND w.length >= ? AND w.length <= ?
      ''');
    final ResultSet results = stmt.select([
      ...categories,
      minLength,
      maxLength,
    ]);
    stmt.close();
    return results.map((row) => row['text'] as String).toList();
  }

  Future<int> getWordCount() async {
    final db = await _dbHelper.database;
    final ResultSet result = db.select('SELECT COUNT(*) as count FROM words');
    return result.first['count'] as int;
  }

  Future<String> getWordCategory(String word) async {
    final db = await _dbHelper.database;
    // Returns the first found category for the word
    final result = db.select(
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
    // Note: We ignore categoryTag here regarding the UserProgress linkage,
    // because the word itself is linked to categories via the static data.
    // However, if we want to store *when* or *context* it was learnt, we might use it.
    // For now, we just mark the word as Learnt in user_progress.

    final db = await _dbHelper.database;

    // Ensure word exists
    final wordRes = db.select('SELECT id FROM words WHERE text = ?', [
      word.toLowerCase(),
    ]);
    if (wordRes.isEmpty) return; // Should not happen if game flow is correct
    final wordId = wordRes.first['id'];

    final stmt = db.prepare('''
      INSERT INTO user_progress (word_id, status, next_review_date)
      VALUES (?, 'Learnt', ?)
      ON CONFLICT(word_id) DO UPDATE SET status = 'Learnt', next_review_date = excluded.next_review_date
      ''');
    stmt.execute([wordId, DateTime.now().millisecondsSinceEpoch]);
    stmt.close();
  }

  Future<List<Map<String, dynamic>>> getLearntWords() async {
    final db = await _dbHelper.database;
    // Join user_progress with words and (optionally) one category for display
    final ResultSet results = db.select('''
      SELECT w.text, up.next_review_date, up.status
      FROM user_progress up
      JOIN words w ON up.word_id = w.id
      WHERE up.status IN ('Learnt', 'Mastered')
      ORDER BY up.next_review_date DESC
      ''');

    // We need to fetch a category for UI (legacy requirement)
    // We'll just fetch 'a' category. Ideally, UI handles lists of categories.
    final List<Map<String, dynamic>> output = [];

    for (final row in results) {
      final String text = row['text'];
      final String cat = await getWordCategory(text);

      output.add({
        'word': text,
        'date_added': row['next_review_date'],
        'category': cat,
        'is_favorite':
            row['status'] == 'Mastered', // Mapping Mastered to Favorite for now
      });
    }
    return output;
  }

  Future<void> toggleFavorite(String word, bool isFav) async {
    final db = await _dbHelper.database;
    final wordRes = db.select('SELECT id FROM words WHERE text = ?', [
      word.toLowerCase(),
    ]);
    if (wordRes.isEmpty) return;
    final wordId = wordRes.first['id'];

    final status = isFav ? 'Mastered' : 'Learnt';

    db.execute('UPDATE user_progress SET status = ? WHERE word_id = ?', [
      status,
      wordId,
    ]);
  }

  Future<void> deleteLearntWord(String word) async {
    final db = await _dbHelper.database;
    final wordRes = db.select('SELECT id FROM words WHERE text = ?', [
      word.toLowerCase(),
    ]);
    if (wordRes.isEmpty) return;
    final wordId = wordRes.first['id'];

    db.execute('DELETE FROM user_progress WHERE word_id = ?', [wordId]);
  }

  Future<bool> isWordLearnt(String word) async {
    final db = await _dbHelper.database;
    final result = db.select(
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
