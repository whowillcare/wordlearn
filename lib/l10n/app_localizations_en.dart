// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
}
