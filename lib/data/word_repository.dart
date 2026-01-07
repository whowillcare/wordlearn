import 'package:sqlite3/sqlite3.dart';
import 'database_helper.dart';

class WordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertWord(String text, String category) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare(
      'INSERT INTO words (text, length, category) VALUES (?, ?, ?)',
    );
    stmt.execute([text.toLowerCase(), text.length, category]);
    stmt.close();
  }

  Future<void> bulkInsertWords(List<Map<String, dynamic>> words) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare(
      'INSERT INTO words (text, length, category) VALUES (?, ?, ?)',
    );
    db.execute('BEGIN TRANSACTION');
    try {
      for (var word in words) {
        stmt.execute([
          word['text'].toString().toLowerCase(),
          word['text'].toString().length,
          word['category'],
        ]);
      }
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.close();
    }
  }

  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final ResultSet results = db.select(
      'SELECT DISTINCT category FROM words ORDER BY category',
    );
    return results.map((row) => row['category'] as String).toList();
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
      'SELECT DISTINCT category FROM words WHERE category LIKE ? ORDER BY category',
      ['%$query%'],
    );
    return result.map((row) => row['category'] as String).toList();
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
      'SELECT COUNT(*) as count FROM words WHERE category IN ($placeholders) AND length >= ? AND length <= ?',
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
    final stmt = db.prepare(
      'SELECT text FROM words WHERE category IN ($placeholders) AND length >= ? AND length <= ?',
    );
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
    final result = db.select(
      'SELECT category FROM words WHERE text = ? LIMIT 1',
      [word],
    );
    if (result.isNotEmpty) {
      return result.first['category'] as String;
    }
    return 'unknown';
  }

  Future<void> addLearntWord(String word, String category) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare(
      'INSERT OR IGNORE INTO learnt_words (word, date_added, category, is_favorite) VALUES (?, ?, ?, 0)',
    );
    stmt.execute([
      word.toLowerCase(),
      DateTime.now().millisecondsSinceEpoch,
      category,
    ]);
    stmt.close();
  }

  Future<List<Map<String, dynamic>>> getLearntWords() async {
    final db = await _dbHelper.database;
    final ResultSet results = db.select(
      'SELECT * FROM learnt_words ORDER BY date_added DESC',
    );
    return results
        .map(
          (row) => {
            'word': row['word'] as String,
            'date_added': row['date_added'] as int,
            'category': row['category'] as String?,
            'is_favorite': (row['is_favorite'] as int?) == 1,
          },
        )
        .toList();
  }

  Future<void> toggleFavorite(String word, bool isFav) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare(
      'UPDATE learnt_words SET is_favorite = ? WHERE word = ?',
    );
    stmt.execute([isFav ? 1 : 0, word.toLowerCase()]);
    stmt.close();
  }

  Future<void> deleteLearntWord(String word) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare('DELETE FROM learnt_words WHERE word = ?');
    stmt.execute([word.toLowerCase()]);
    stmt.close();
  }

  Future<bool> isWordLearnt(String word) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare('SELECT 1 FROM learnt_words WHERE word = ?');
    final ResultSet results = stmt.select([word.toLowerCase()]);
    stmt.close();
    return results.isNotEmpty;
  }
}
