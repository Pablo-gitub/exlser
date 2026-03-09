/// Base class for technical exceptions.
///
/// Exceptions represent low-level technical errors
/// thrown by infrastructure components such as:
///
/// - database
/// - file system
/// - parsers
abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);
}

/// Exception thrown when a database operation fails.
class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

/// Exception thrown when parsing a file fails.
class ParsingException extends AppException {
  const ParsingException(super.message);
}

/// Exception thrown when exporting data fails.
class ExportException extends AppException {
  const ExportException(super.message);
}