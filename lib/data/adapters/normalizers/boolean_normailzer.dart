import 'value_normalizer.dart';

/// Normalizes textual boolean values into `bool`.
///
/// This component supports common boolean representations
/// typically found in spreadsheets and CSV datasets.
///
/// Supported TRUE values:
///
///   true
///   TRUE
///   True
///   1
///   yes
///   YES
///
/// Supported FALSE values:
///
///   false
///   FALSE
///   False
///   0
///   no
///   NO
///
/// If the value cannot be interpreted as a boolean,
/// the method returns `null`.
class BooleanNormalizer implements ValueNormalizer<bool> {

  /// Set of textual representations interpreted as TRUE.
  static const _trueValues = {
    'true',
    '1',
    'yes',
  };

  /// Set of textual representations interpreted as FALSE.
  static const _falseValues = {
    'false',
    '0',
    'no',
  };

  @override
  bool? tryNormalize(String value) {

    /// Remove whitespace and normalize casing.
    final normalized = value.trim().toLowerCase();

    /// Reject empty values.
    if (normalized.isEmpty) {
      return null;
    }

    /// Check TRUE values.
    if (_trueValues.contains(normalized)) {
      return true;
    }

    /// Check FALSE values.
    if (_falseValues.contains(normalized)) {
      return false;
    }

    /// Value cannot be interpreted as boolean.
    return null;
  }
}