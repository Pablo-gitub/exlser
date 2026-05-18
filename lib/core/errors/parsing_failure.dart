import 'package:exel_category/core/errors/failures.dart';

/// Failure related to file parsing.
///
/// Examples:
/// - Excel parsing error
/// - CSV malformed file
/// - unsupported format
class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}
