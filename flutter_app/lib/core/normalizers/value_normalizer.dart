/// Base contract for value normalizers.
///
/// A value normalizer attempts to convert a raw textual value
/// (usually coming from CSV or Excel files) into a typed value.
///
/// Implementations may normalize values such as:
///
/// - numbers
/// - dates
/// - booleans
///
/// The normalizer returns:
///
/// - a normalized value of type `T` if parsing succeeds
/// - `null` if the value cannot be interpreted
///
/// Example:
///
/// "10,5" → 10.5
/// "true" → true
/// "2024-01-14" → DateTime
abstract class ValueNormalizer<T> {
  /// Attempts to normalize a raw textual value.
  ///
  /// Returns:
  /// - normalized value of type `T`
  /// - null if normalization fails
  T? tryNormalize(String value);
}
