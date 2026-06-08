/// Normalizes numeric values coming from external data sources
/// such as CSV or Excel files.
///
/// The goal of this component is to convert textual numeric
/// representations into a normalized `double` value.
///
/// It supports several international formats commonly found
/// in real-world datasets.
///
/// Supported formats include:
///
/// Integers
///   "10"
///   "-5"
///
/// Decimal numbers
///   "10.5"
///   "10,5"
///
/// Thousands separators
///   "1,000"
///   "1.000"
///   "1'000"
///
/// Thousands + decimal separators
///   "1,000.50"
///   "1.000,50"
///
/// Currency symbols (prefix or suffix, with optional space)
///   "$3.50"   "3.50$"
///   "€1.000,50"   "1.000,50 €"
///   "£12"     "¥500"
///
/// If the value cannot be interpreted as a number,
/// the method returns `null`.
///
/// This component intentionally **does not decide**
/// whether the value represents an INTEGER or REAL.
/// That responsibility belongs to `InferSchemaUseCase`.
///
/// Note: currency symbols are stripped silently. The information about
/// which currency was present is not preserved here. Future work could
/// store the detected symbol in column metadata for display purposes.
class NumberNormalizer {
  static final _currencySymbols = RegExp(r'[$€£¥₹₽¢₩₪₫]');

  /// Returns the first currency symbol found in [value], or null if none.
  static String? detectCurrencySymbol(String value) {
    final match = _currencySymbols.firstMatch(value.trim());
    return match?[0];
  }

  /// Attempts to normalize a numeric string into a `double`.
  ///
  /// Returns:
  /// - `double` if parsing succeeds
  /// - `null` if the value is not a valid number
  double? tryNormalize(String value) {
    /// Trim whitespace to avoid parsing issues.
    final trimmed = value.trim();

    /// Reject empty strings.
    if (trimmed.isEmpty) {
      return null;
    }

    /// Strip currency symbols (prefix or suffix) so that values like
    /// "$3.50", "3.50€", "£1,000" are treated as plain numbers.
    String normalized = trimmed.replaceAll(_currencySymbols, '').trim();

    if (normalized.isEmpty) {
      return null;
    }

    /// Remove apostrophe thousand separators
    /// Example:
    ///   1'000 → 1000
    normalized = normalized.replaceAll("'", "");

    /// Detect format containing both '.' and ','
    /// This is usually a locale-specific format.
    ///
    /// Examples:
    ///   1,000.50  (US format)
    ///   1.000,50  (EU format)
    if (normalized.contains('.') && normalized.contains(',')) {
      final lastDot = normalized.lastIndexOf('.');
      final lastComma = normalized.lastIndexOf(',');

      if (lastDot > lastComma) {
        /// US format
        /// thousands: ,
        /// decimal: .
        ///
        /// Example:
        /// 1,000.50 → remove commas
        normalized = normalized.replaceAll(',', '');
      } else {
        /// EU format
        /// thousands: .
        /// decimal: ,
        ///
        /// Example:
        /// 1.000,50 → remove dots and convert comma
        normalized = normalized.replaceAll('.', '');
        normalized = normalized.replaceAll(',', '.');
      }
    } else if (normalized.contains(',')) {
      /// Only comma present.
      ///
      /// Two possibilities:
      /// decimal comma or thousand comma.
      ///
      /// Strategy:
      /// convert comma to decimal point.
      final parts = normalized.split(',');

      /// Example: 1,000 → thousand separator
      if (parts.length == 2 && parts[1].length == 3) {
        normalized = normalized.replaceAll(',', '');
      } else {
        /// Example: 10,5 → decimal separator
        normalized = normalized.replaceAll(',', '.');
      }
    } else if (normalized.contains('.')) {
      /// Dot present.
      ///
      /// Could be decimal or thousand separator.
      ///
      /// If there are multiple dots, assume
      /// they are thousand separators.

      final parts = normalized.split('.');

      /// Example: 1.000 → thousand separator
      if (parts.length == 2 && parts[1].length == 3) {
        normalized = normalized.replaceAll('.', '');
      } else {
        /// Example: 10.5 → decimal separator
        /// leave as is
      }
    }

    /// Attempt to parse the normalized string.
    final parsed = double.tryParse(normalized);

    return parsed;
  }
}
