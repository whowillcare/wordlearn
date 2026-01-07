import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('Verify JSON parsing for all data files', () async {
    final dataDir = Directory('assets/data');
    if (!await dataDir.exists()) {
      // Adjust path if running from root or elsewhere
      print('Current dir: ${Directory.current.path}');
      return;
    }

    final files = dataDir.listSync().where((f) => f.path.endsWith('.json'));

    for (var file in files) {
      print('Testing ${file.path}...');
      final jsonString = await File(file.path).readAsString();
      final dynamic jsonContent = json.decode(jsonString);
      final List<dynamic> words = [];

      // The logic we implemented in database_helper.dart
      if (jsonContent is List) {
        words.addAll(jsonContent);
      } else if (jsonContent is Map) {
        for (final value in jsonContent.values) {
          if (value is List) {
            words.addAll(value);
          } else {
            words.add(value);
          }
        }
      }

      print('Success: Parsed ${words.length} words from ${file.path}');
      expect(words, isNotEmpty);
      expect(
        words.first,
        isA<String>(),
      ); // Basic check that it's a list of something useful
    }
  });
}
