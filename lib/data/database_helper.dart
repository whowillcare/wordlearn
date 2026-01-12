import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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

      // Check if file exists
      if (await file.exists()) {
        final int localSize = await file.length();
        final int assetSize = bytes.length;

        // If sizes differ, we assume the asset is newer/changed (e.g. dev build)
        // Note: This will wipe user progress if stored in the same DB!
        // For production, we would use a version migration or separate user DB.
        if (localSize != assetSize) {
          print(
            'Database update detected (size mismatch: $localSize vs $assetSize). Overwriting...',
          );
          await file.delete();
          await file.writeAsBytes(bytes, flush: true);
        }
      } else {
        // First install
        print('Copying dictionary.db from assets...');
        await file.writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      print('Error ensuring database integrity: $e');
    }

    return await openDatabase(
      path,
      version: 1,
      readOnly: false, // We might write user progress?
    );
  }
}
