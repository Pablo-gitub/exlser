/// Utility class for sanitizing SQL table and column names.
///
/// Prevents SQL injection, syntax errors, and handles
/// common issues found in dynamic Excel/CSV headers.
class SqlNameSanitizer {
  /// SQLite restricted keywords that could break dynamic queries
  /// if used as table or column names without quotes.
  static const _reservedKeywords = {
    'select',
    'table',
    'where',
    'order',
    'group',
    'by',
    'insert',
    'update',
    'delete',
    'from',
    'into',
    'values',
    'index',
    'create',
    'drop',
    'alter',
    'limit',
    'offset',
    'and',
    'or',
    'not',
    'null',
    'as',
    'join',
    'inner',
    'left',
    'right',
    'outer',
    'on',
    'having'
  };

  /// Sanitizes a column name dynamically generated from an Excel header.
  ///
  /// [rawName] the original header string
  /// [existingNames] list of already sanitized names to prevent duplicates
  static String sanitizeColumnName(
    String rawName, {
    List<String> existingNames = const [],
  }) {
    return _sanitize(
      rawName,
      prefixFallback: 'col',
      existingNames: existingNames,
    );
  }

  /// Sanitizes a table name dynamically generated from an Excel sheet or filename.
  static String sanitizeTableName(
    String rawName, {
    List<String> existingNames = const [],
  }) {
    return _sanitize(
      rawName,
      prefixFallback: 'tbl',
      existingNames: existingNames,
    );
  }

  static String _sanitize(
    String rawName, {
    required String prefixFallback,
    required List<String> existingNames,
  }) {
    // 1. Lowercase and trim
    String sanitized = rawName.trim().toLowerCase();

    // 2. Replace non-alphanumeric characters with underscores
    sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    // 3. Remove leading and trailing underscores
    sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');

    // 4. Fallback if empty (e.g., header was only emojis or special chars)
    if (sanitized.isEmpty) {
      sanitized = prefixFallback;
    }

    // 5. Must not start with a number
    if (RegExp(r'^[0-9]').hasMatch(sanitized)) {
      sanitized = '${prefixFallback}_$sanitized';
    }

    // 6. Handle SQL reserved keywords
    if (_reservedKeywords.contains(sanitized)) {
      sanitized = '${sanitized}_$prefixFallback'; // e.g., 'select_col'
    }

    // 7. Deduplication (ensure uniqueness)
    String finalName = sanitized;
    int counter = 1;
    while (existingNames.contains(finalName)) {
      finalName = '${sanitized}_$counter';
      counter++;
    }

    return finalName;
  }
}
