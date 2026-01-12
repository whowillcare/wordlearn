import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'data/word_repository.dart';
import 'data/statistics_repository.dart';
import 'ui/home_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'data/settings_repository.dart';
import 'logic/game_bloc.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

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

  // Initialize HydratedStorage for state persistence
  // Initialize HydratedStorage for state persistence
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );

  final wordRepo = WordRepository();
  final statsRepo = await StatisticsRepository.init();
  final settingsRepo = await SettingsRepository.init();

  runApp(
    MyApp(
      repository: wordRepo,
      statsRepository: statsRepo,
      settingsRepository: settingsRepo,
    ),
  );
}

class MyApp extends StatelessWidget {
  final WordRepository repository;
  final StatisticsRepository statsRepository;
  final SettingsRepository settingsRepository;
  const MyApp({
    super.key,
    required this.repository,
    required this.statsRepository,
    required this.settingsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        RepositoryProvider.value(value: repository),
        RepositoryProvider.value(value: statsRepository),
        // Use ChangeNotifierProvider for SettingsRepository to enable context.watch()
        ChangeNotifierProvider.value(value: settingsRepository),
        BlocProvider(
          create: (context) =>
              GameBloc(repository, statsRepository, settingsRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Word-Le-Earn', // Updated Title
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
        home: const HomeScreen(),
      ),
    );
  }
}
