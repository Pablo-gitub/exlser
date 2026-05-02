/// Base class for all import-related errors.
///
/// Contains:
/// - a machine-readable [code]
/// - a developer-friendly [message]
///
/// The UI layer should use [code] for localization.
abstract class ImportException implements Exception {
  /// Machine-readable error identifier (used for i18n)
  final String code;

  /// Debug / developer message (NOT for UI)
  final String message;

  const ImportException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => '[$code] $message';
}

/// Thrown when file extension is missing or unsupported.
class InvalidFileExtensionException extends ImportException {
  const InvalidFileExtensionException()
      : super(
          code: 'no_extension',
          message: 'File has no extension',
        );
}

/// Thrown when file format is not supported.
class UnsupportedFormatException extends ImportException {
  final String extension;

  const UnsupportedFormatException({
    required this.extension,
  }) : super(
    code: 'unsupported_format',
    message: 'Unsupported file format: $extension',
  );
}

/// Thrown when parser cannot be resolved.
class ParserNotFoundException extends ImportException {
  const ParserNotFoundException(String extension)
      : super(
          code: 'parser_not_found',
          message: 'No parser available for .$extension',
        );
}

/// Thrown when parsing fails.
class ParsingException extends ImportException {
  const ParsingException({
    required super.code,
    required super.message,
  });
}

/// Thrown when schema inference fails.
class SchemaInferenceException extends ImportException {
  const SchemaInferenceException({
    required String sheetName,
    required String details,
  }) : super(
          code: 'schema_failed',
          message: 'Failed schema inference for "$sheetName": $details',
        );
}