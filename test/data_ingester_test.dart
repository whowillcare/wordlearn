import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:word_learn_app/data/data_ingester.dart';
import 'package:word_learn_app/data/word_repository.dart';

class MockWordRepository extends Mock implements WordRepository {
  int count = 0;
  List<Map<String, dynamic>> insertedWords = [];

  @override
  Future<int> getWordCount() async => count;

  @override
  Future<void> bulkInsertWords(List<Map<String, dynamic>> words) async {
    insertedWords.addAll(words);
    count += words.length;
  }

  @override
  Future<List<String>> getCategories() async => [];

  @override
  Future<List<String>> getWords(
    String category,
    int minLength,
    int maxLength,
  ) async => [];

  @override
  Future<void> insertWord(String text, String category) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'DataIngester should parse manifest and ingest words',
    skip: true,
    () async {
      final mockRepo = MockWordRepository();
      final ingester = DataIngester(mockRepo);

      // Mock AssetManifest.json
      final manifest = {
        'assets/data/test_cat.json': ['assets/data/test_cat.json'],
      };

      // Mock file content
      final fileContent = json.encode(['apple', 'banana']);

      // Intercept rootBundle
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
            final String key = utf8.decode(message!.buffer.asUint8List());
            if (key == 'AssetManifest.json') {
              return ByteData.view(utf8.encode(json.encode(manifest)).buffer);
            } else if (key == 'assets/data/test_cat.json') {
              return ByteData.view(utf8.encode(fileContent).buffer);
            }
            return null;
          });

      final result = await ingester.ingestData();

      expect(result.success, true);
      expect(result.filesFound, 1);

      expect(mockRepo.count, 2);
      expect(mockRepo.insertedWords[0]['text'], 'apple');
      expect(mockRepo.insertedWords[0]['category'], 'test_cat');
    },
  );
}
