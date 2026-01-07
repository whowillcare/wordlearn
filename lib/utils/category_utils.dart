class CategoryUtils {
  static String formatName(String raw) {
    if (raw == 'all') return 'Everything';

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
