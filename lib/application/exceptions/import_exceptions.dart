/// Base class for all import-related errors.
///
/// Allows UI and higher layers to handle specific failure cases.
abstract class ImportException implements Exception {
  final String message;

  const ImportException(this.message);

  @override
  String toString() => message;
}

/// Thrown when file extension is missing or unsupported.
class InvalidFileExtensionException extends ImportException {
  const InvalidFileExtensionException(super.message);
}

/// Thrown when parser cannot be resolved.
class ParserNotFoundException extends ImportException {
  const ParserNotFoundException(super.message);
}

/// Thrown when parsing fails.
class ParsingException extends ImportException {
  const ParsingException(super.message);
}

/// Thrown when schema inference fails.
class SchemaInferenceException extends ImportException {
  const SchemaInferenceException(super.message);
}