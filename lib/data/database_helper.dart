import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_learn_app/core/logger.dart';

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
    final path = join(docsDir.path, 'dictionary.db');

    final file = File(path);
    try {
      final ByteData data = await rootBundle.load('assets/dictionary.db');
      final List<int> bytes = data.buffer.asUint8List();

      // Check version
      String assetVersion = '0';
      try {
        assetVersion = await rootBundle.loadString('assets/version.txt');
      } catch (_) {
        Log.i('No asset version found, defaulting to size check.');
      }

      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getString('db_version') ?? '0';

      bool shouldUpdate = false;

      if (!await file.exists()) {
        shouldUpdate = true;
        Log.i('First run: Copying database...');
      } else if (int.tryParse(assetVersion) != null &&
          int.tryParse(localVersion) != null &&
          int.parse(assetVersion) > int.parse(localVersion)) {
        shouldUpdate = true;
        Log.i(
          'Newer database version detected ($assetVersion > $localVersion). Updating...',
        );
      } else if (await file.length() != bytes.length) {
        // Fallback to size check if versions invalid or identical but sizes differ (corruption?)
        // Actually, let's trust version mostly. If versions equal, assume it's fine.
        // But if version file missing, we use size.
        if (assetVersion == '0') {
          shouldUpdate = true;
          Log.i('Size mismatch (no version). Updating...');
        }
      }

      if (shouldUpdate) {
        // Close DB if open (unlikely here as we init)
        // Check if DB file is locked?

        // Backup user progress?
        // NOTE: We are overwriting the DB. User progress in 'user_progress' table in this DB will be LOST
        // unless we migrate it.
        // Current requirement implies we simply replace the DB.

        await file.writeAsBytes(bytes, flush: true);
        await prefs.setString('db_version', assetVersion);
        Log.i('Database updated to version $assetVersion');
      }
    } catch (e, s) {
      Log.e('Error ensuring database integrity', e, s);
    }

    final db = await openDatabase(path, version: 1, readOnly: false);

    // Schema Migration: Add notes column if missing
    try {
      await db.execute('ALTER TABLE user_progress ADD COLUMN notes TEXT');
    } catch (_) {
      // Column likely already exists or table structure is different; ignore
    }

    return db;
  }
}
