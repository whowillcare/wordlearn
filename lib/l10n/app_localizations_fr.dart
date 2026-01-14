// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'WordLearn';

  @override
  String get gameWon => 'You Won!';

  @override
  String get gameOver => 'Game Over!';

  @override
  String get settings => 'Settings';

  @override
  String get sound => 'Sound';

  @override
  String get vipMode => 'VIP Mode';

  @override
  String get language => 'Language';

  @override
  String get play => 'Play';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get library => 'Library';

  @override
  String get points => 'Points';

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String get shop => 'Shop';

  @override
  String get searchWords => 'Search your words...';

  @override
  String get mastered => 'Mastered';

  @override
  String get learning => 'Learning';

  @override
  String get newWord => 'New';

  @override
  String get level => 'Level';

  @override
  String get score => 'Score';

  @override
  String get hint => 'Hint';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get allowSpecialChars => 'Allow Special Characters';

  @override
  String get allowSpecialCharsDesc =>
      'Include words with hyphens and apostrophes';

  @override
  String get theme => 'Theme';

  @override
  String get about => 'About';

  @override
  String get filter => 'Filter';

  @override
  String get favoritesOnly => 'Favorites Only';

  @override
  String get allCategories => 'All Categories';

  @override
  String get noWordsLearnt => 'No words learnt yet!';

  @override
  String get noResults => 'No results found.';

  @override
  String get undo => 'UNDO';

  @override
  String get removed => 'Removed';

  @override
  String get dailyBonusTitle => 'Daily Bonus! 🎉';

  @override
  String dailyBonusContent(Object streak) {
    return 'You maintained a $streak day streak!';
  }

  @override
  String get claim => 'Claim';

  @override
  String earnedDiamonds(Object amount) {
    return 'Earned $amount Diamonds!';
  }

  @override
  String get resumeGame => 'Resume Game';

  @override
  String get startNewGame => 'Start New Game';

  @override
  String get categories => 'Categories';

  @override
  String get wordLength => 'Word Length';

  @override
  String get noChallengesToday => 'No challenges today!';

  @override
  String challengeLevel(Object length, Object number) {
    return 'Challenge $number: $length Letters';
  }
}
