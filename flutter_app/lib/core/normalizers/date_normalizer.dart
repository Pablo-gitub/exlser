/// Normalizes textual date representations into `DateTime` objects.
///
/// This component is responsible for interpreting common date formats
/// typically found in CSV and Excel datasets.
///
/// Supported formats include:
///
/// ISO date
///   2024-01-14
///
/// ISO datetime
///   2024-01-14 10:30:00
///
/// Slash-separated (DD/MM/YYYY or YYYY/MM/DD)
///   14/01/2024
///   2024/01/14
///
/// Dot-separated European (DD.MM.YYYY or YYYY.MM.DD)
///   14.01.2024
///   2024.01.14
///
/// Hyphen-separated non-ISO (DD-MM-YYYY)
///   14-01-2024
///
/// If the value cannot be interpreted as a valid date,
/// the method returns `null`.
///
/// Ambiguous cases (e.g. 01/06/2024 could be Jan 6 or Jun 1) are resolved
/// by always treating the first numeric part as the day when the separator
/// is not year-first.
class DateNormalizer {
  /// Attempts to normalize a textual date representation into `DateTime`.
  ///
  /// Returns:
  /// - `DateTime` if parsing succeeds
  /// - `null` if the value cannot be interpreted as a valid date
  DateTime? tryNormalize(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return null;

    /// ISO 8601: 2024-01-14, 2024-01-14T10:30:00, 2024-01-14 10:30:00
    try {
      return DateTime.parse(trimmed);
    } catch (_) {}

    /// Slash-separated: DD/MM/YYYY or YYYY/MM/DD
    if (trimmed.contains('/')) {
      final result = _parseParts(trimmed.split('/'));
      if (result != null) return result;
    }

    /// Dot-separated: DD.MM.YYYY or YYYY.MM.DD
    /// Guard: must have exactly 3 parts (avoids confusing floats like "3.14")
    if (trimmed.contains('.')) {
      final result = _parseParts(trimmed.split('.'));
      if (result != null) return result;
    }

    /// Hyphen-separated non-ISO: DD-MM-YYYY
    /// (ISO YYYY-MM-DD already handled above by DateTime.parse)
    if (trimmed.contains('-')) {
      final result = _parseParts(trimmed.split('-'));
      if (result != null) return result;
    }

    return null;
  }

  /// Tries to build a DateTime from exactly 3 string parts.
  ///
  /// Year-first detection: if the first part is > 31 it is treated as the year
  /// (YYYY/MM/DD), otherwise the last part is the year (DD/MM/YYYY).
  ///
  /// Basic range validation prevents Dart's DateTime from silently normalising
  /// invalid values (e.g. month=99) into unexpected dates.
  DateTime? _parseParts(List<String> parts) {
    if (parts.length != 3) return null;

    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);

    if (a == null || b == null || c == null) return null;

    int year, month, day;
    if (a > 31) {
      // YYYY / MM / DD
      year = a;
      month = b;
      day = c;
    } else {
      // DD / MM / YYYY
      day = a;
      month = b;
      year = c;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1) {
      return null;
    }

    try {
      final dt = DateTime(year, month, day);
      // Dart normalises out-of-range days by rolling over; reject if day changed
      if (dt.day != day || dt.month != month || dt.year != year) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }
}
