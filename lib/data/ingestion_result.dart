class IngestionResult {
  final bool success;
  final int initialCount; // words before
  final int finalCount; // words after
  final int filesFound;
  final List<String> errors;

  const IngestionResult({
    required this.success,
    required this.initialCount,
    required this.finalCount,
    required this.filesFound,
    this.errors = const [],
  });

  @override
  String toString() {
    return 'Success: $success\nInit: $initialCount\nFinal: $finalCount\nFiles: $filesFound\nErrors: ${errors.length}';
  }
}
