class CategoryUtils {
  static const Map<String, String> _displayNames = {
    'freq': 'Most Frequent',
    'grade-1': 'Grade 1',
    'grade-2': 'Grade 2',
    'grade-3': 'Grade 3',
    'grade-4': 'Grade 4',
    'grade-5': 'Grade 5',
    'grade-6': 'Grade 6',
    'grade-7': 'Grade 7',
    'grade-8': 'Grade 8',
    'grade-9': 'Grade 9',
    'grade-10': 'Grade 10',
    'grade-11': 'Grade 11',
    'grade-12': 'Grade 12',
    'svl': 'Sec. School Voc.',
    'msvl': 'Mid. School Voc.',
    'tof': 'TOEFL',
    'sat': 'S.A.T.',
    'gre': 'GRE',
    'ielts': 'IELTS',
    'svl - math': 'Sec. School Math',
    'svl - biology': 'Sec. School Biology',
    'svl - chemistry': 'Sec. School Chemistry',
    'svl - economics':
        'Sec. School Economics', // Fixed typo 'ecnomics' assumption
    'svl - ecnomics': 'Sec. School Economics', // Keep legacy just in case
    'svl - english': 'Sec. School English',
    'svl - geography': 'Sec. School Geography',
    'svl - history': 'Sec. School History',
    'svl - physics': 'Sec. School Physics',
    'academic (avl)': 'Academic (AVL)',
    'science word list': 'Science Word List',
  };

  static String formatName(String raw) {
    if (raw == 'all') return 'All Categories';
    if (_displayNames.containsKey(raw)) return _displayNames[raw]!;

    // Replace hyphens with spaces
    String spaced = raw.replaceAll('-', ' ');

    // Capitalize words
    return spaced
        .split(' ')
        .map((str) {
          if (str.isEmpty) return '';
          return str[0].toUpperCase() + str.substring(1);
        })
        .join(' ');
  }

  static int compareCategories(String a, String b) {
    if (a == 'all') return -1;
    if (b == 'all') return 1;

    // Prioritize "grade-X"
    bool aIsGrade = a.startsWith('grade-');
    bool bIsGrade = b.startsWith('grade-');

    if (aIsGrade && bIsGrade) {
      // Extract numbers
      final aNum = _extractNumber(a);
      final bNum = _extractNumber(b);
      if (aNum != bNum) return aNum.compareTo(bNum);
    }

    if (aIsGrade && !bIsGrade) return -1;
    if (!aIsGrade && bIsGrade) return 1;

    return a.compareTo(b);
  }

  static int _extractNumber(String s) {
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(s);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 999;
  }
}
