import 'package:exel_category/core/errors/failures.dart';

/// Failure related to database operations.
///
/// Examples:
/// - insert failure
/// - query failure
/// - transaction failure
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}
