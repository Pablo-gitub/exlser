import 'package:exlser/application/dto/prepared_import_result.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/entities/source_file_reference.dart';

/// User-confirmed import configuration.
///
/// This DTO is produced after the import wizard, once the user has confirmed
/// dataset metadata and column types. It is the input for dataset persistence.
class ConfirmedImport {
  final String datasetName;
  final String sourceFileName;
  final SourceFileReference? sourceFileReference;
  final List<ConfirmedImportSheet> sheets;

  const ConfirmedImport({
    required this.datasetName,
    required this.sourceFileName,
    this.sourceFileReference,
    required this.sheets,
  });

  factory ConfirmedImport.fromPreparedResult({
    required String datasetName,
    required PreparedImportResult preparedImport,
    SourceFileReference? sourceFileReference,
  }) {
    return ConfirmedImport(
      datasetName: datasetName,
      sourceFileName: preparedImport.fileName,
      sourceFileReference: sourceFileReference,
      sheets: preparedImport.sheets
          .map(
            (sheet) => ConfirmedImportSheet(
              sheet: sheet.sheet,
              columns: sheet.inferredColumns,
              columnCurrencySymbols: sheet.columnCurrencySymbols,
            ),
          )
          .toList(),
    );
  }

  int get tableCount => sheets.length;

  int get rowCount => sheets.fold(
        0,
        (total, sheet) => total + sheet.sheet.rows.length,
      );

  int get columnCount => sheets.fold(
        0,
        (total, sheet) => total + sheet.columns.length,
      );
}

/// User-confirmed schema for one imported sheet.
class ConfirmedImportSheet {
  final ParsedSheet sheet;
  final List<DatasetColumn> columns;

  /// Currency symbols detected during import preparation.
  /// Key: column dbName, Value: detected symbol (e.g. "$", "€").
  final Map<String, String> columnCurrencySymbols;

  const ConfirmedImportSheet({
    required this.sheet,
    required this.columns,
    this.columnCurrencySymbols = const {},
  });

  ConfirmedImportSheet copyWith({
    ParsedSheet? sheet,
    List<DatasetColumn>? columns,
    Map<String, String>? columnCurrencySymbols,
  }) {
    return ConfirmedImportSheet(
      sheet: sheet ?? this.sheet,
      columns: columns ?? this.columns,
      columnCurrencySymbols:
          columnCurrencySymbols ?? this.columnCurrencySymbols,
    );
  }
}
