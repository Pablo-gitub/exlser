import 'package:exlser/core/constants/app_strings.dart';

class ImportErrorMessages {
  const ImportErrorMessages._();

  static String translationKeyForCode(String code) {
    switch (code) {
      case 'empty_file_name':
        return AppStrings.importEmptyFileName;
      case 'empty_file_path':
        return AppStrings.importEmptyFilePath;
      case 'empty_file_bytes':
        return AppStrings.importEmptyFileBytes;
      case 'no_extension':
        return AppStrings.importNoExtension;
      case 'unsupported_format':
        return AppStrings.importUnsupportedFormat;
      case 'parser_not_found':
        return AppStrings.importParserNotFound;
      case 'parsing_failed':
        return AppStrings.importParsingFailed;
      case 'no_sheets':
        return AppStrings.importEmptySheets;
      case 'no_valid_sheets':
        return AppStrings.importNoValidSheets;
      case 'schema_failed':
        return AppStrings.importSchemaFailed;
      case 'creation_failed':
        return AppStrings.importCreationFailed;
      case 'file_access_error':
        return AppStrings.importFileAccessError;
      case 'unexpected_error':
      default:
        return AppStrings.importUnexpectedError;
    }
  }
}
