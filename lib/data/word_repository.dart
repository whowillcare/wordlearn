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
    stmt.dispose();
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
      stmt.dispose();
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

  Future<List<String>> getWords(
    String category,
    int minLength,
    int maxLength,
  ) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare(
      'SELECT text FROM words WHERE category = ? AND length >= ? AND length <= ?',
    );
    final ResultSet results = stmt.select([category, minLength, maxLength]);
    stmt.dispose();
    return results.map((row) => row['text'] as String).toList();
  }

  Future<int> getWordCount() async {
    final db = await _dbHelper.database;
    final ResultSet result = db.select('SELECT COUNT(*) as count FROM words');
    return result.first['count'] as int;
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
    stmt.dispose();
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
    stmt.dispose();
  }

  Future<void> deleteLearntWord(String word) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare('DELETE FROM learnt_words WHERE word = ?');
    stmt.execute([word.toLowerCase()]);
    stmt.dispose();
  }

  Future<bool> isWordLearnt(String word) async {
    final db = await _dbHelper.database;
    final stmt = db.prepare('SELECT 1 FROM learnt_words WHERE word = ?');
    final ResultSet results = stmt.select([word.toLowerCase()]);
    stmt.dispose();
    return results.isNotEmpty;
  }
}
