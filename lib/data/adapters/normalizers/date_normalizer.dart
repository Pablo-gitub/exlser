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
/// European format
///   14/01/2024
///
/// Alternative European examples
///   01/12/2024
///
/// If the value cannot be interpreted as a valid date,
/// the method returns `null`.
///
/// The normalizer does not attempt to guess complex locale-specific
/// formats beyond the most common ones used in spreadsheets.
///
/// More complex parsing rules can be added in the future if needed.
class DateNormalizer {
  /// Attempts to normalize a textual date representation into `DateTime`.
  ///
  /// Returns:
  /// - `DateTime` if parsing succeeds
  /// - `null` if the value cannot be interpreted as a valid date
  DateTime? tryNormalize(String value) {
    /// Remove surrounding whitespace
    final trimmed = value.trim();

    /// Reject empty values
    if (trimmed.isEmpty) {
      return null;
    }

    /// First attempt: try ISO parsing directly.
    ///
    /// This covers:
    ///   2024-01-14
    ///   2024-01-14T10:30:00
    ///   2024-01-14 10:30:00
    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      // Ignore and attempt other formats
    }

    /// Second attempt: European format (dd/MM/yyyy)
    ///
    /// Example:
    /// 14/01/2024
    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');

      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          try {
            return DateTime(year, month, day);
          } catch (_) {
            return null;
          }
        }
      }
    }

    /// If all parsing attempts fail,
    /// return null indicating the value is not a valid date.
    return null;
  }
}
