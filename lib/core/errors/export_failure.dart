import 'package:exel_category/core/errors/failures.dart';

/// Failure related to export operations.
///
/// Examples:
/// - PDF export error
/// - Excel export failure
/// - file write failure
class ExportFailure extends Failure {
  const ExportFailure(super.message);
}
