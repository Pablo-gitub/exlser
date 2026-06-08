import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/presentation/views/home/widgets/import_dialog/import_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportErrorMessages', () {
    test('should map known import error codes to translation keys', () {
      expect(
        ImportErrorMessages.translationKeyForCode('empty_file_name'),
        AppStrings.importEmptyFileName,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('empty_file_path'),
        AppStrings.importEmptyFilePath,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('empty_file_bytes'),
        AppStrings.importEmptyFileBytes,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('no_extension'),
        AppStrings.importNoExtension,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('unsupported_format'),
        AppStrings.importUnsupportedFormat,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('parser_not_found'),
        AppStrings.importParserNotFound,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('parsing_failed'),
        AppStrings.importParsingFailed,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('no_sheets'),
        AppStrings.importEmptySheets,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('no_valid_sheets'),
        AppStrings.importNoValidSheets,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('schema_failed'),
        AppStrings.importSchemaFailed,
      );
      expect(
        ImportErrorMessages.translationKeyForCode('creation_failed'),
        AppStrings.importCreationFailed,
      );
    });

    test('should fallback to unexpected import error for unknown codes', () {
      expect(
        ImportErrorMessages.translationKeyForCode('unknown_code'),
        AppStrings.importUnexpectedError,
      );
    });
  });
}
