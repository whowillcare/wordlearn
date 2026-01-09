import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/word_repository.dart';
import 'data/data_ingester.dart';
import 'data/statistics_repository.dart';
import 'data/ingestion_result.dart';
import 'ui/home_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'data/settings_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb if needed, or just default

import 'package:provider/provider.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase init failed: $e");
  }

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    print("AdMob init failed: $e");
  }

  final wordRepo = WordRepository();
  final statsRepo = await StatisticsRepository.init();
  final settingsRepo = await SettingsRepository.init();
  final ingestionResult = await DataIngester(wordRepo).ingestData();

  runApp(
    MyApp(
      repository: wordRepo,
      statsRepository: statsRepo,
      settingsRepository: settingsRepo,
      ingestionResult: ingestionResult,
    ),
  );
}

class MyApp extends StatelessWidget {
  final WordRepository repository;
  final StatisticsRepository statsRepository;
  final SettingsRepository settingsRepository;
  final IngestionResult ingestionResult;

  const MyApp({
    super.key,
    required this.repository,
    required this.statsRepository,
    required this.settingsRepository,
    required this.ingestionResult,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        RepositoryProvider.value(value: repository),
        RepositoryProvider.value(value: statsRepository),
        // Use ChangeNotifierProvider for SettingsRepository to enable context.watch()
        ChangeNotifierProvider.value(value: settingsRepository),
      ],
      child: MaterialApp(
        title: 'WordLearn',
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('zh'), // Chinese (Simplified)
          Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
          ), // Chinese (Traditional)
          Locale('fr'), // French
          Locale('es'), // Spanish
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: HomeScreen(ingestionResult: ingestionResult),
      ),
    );
  }
}
