class GameLevel {
  final int number; // order
  final String key; // save key
  final int minLength; // min word len
  final int? maxLength; // max word length
  final int? attempts;

  bool get awardsAchievement => false; // Simplifying for now

  String get name => key[0].toUpperCase() + key.substring(1);

  int get wordLen {
    /* 
    Legacy logic:
    if (maxLen == null) return len;
    var rnd = Random();
    return len + rnd.nextInt(maxLen! - len + 1);
    We will just expose ranges and let logic decide
    */
    return minLength;
  }

  const GameLevel({
    required this.number,
    required this.minLength,
    required this.key,
    this.attempts,
    this.maxLength,
  }) : assert(
         (maxLength == null || (maxLength >= minLength)),
         'MaxLength must be >= MinLength',
       );
}

const gameLevels = [
  GameLevel(number: 1, minLength: 2, maxLength: 3, key: 'casual'),
  GameLevel(number: 2, minLength: 3, maxLength: 4, key: 'interesting'),
  GameLevel(number: 3, minLength: 5, key: 'classic'),
  GameLevel(number: 4, minLength: 6, maxLength: 9, key: 'playable'),
  GameLevel(
    number: 5, // Re-sequencing number 7 -> 5 for logical progression
    minLength: 10,
    maxLength: 16,
    key: 'advanced',
  ),
  GameLevel(number: 6, minLength: 17, maxLength: 33, key: 'insane'),
];
