import 'package:exel_category/application/dto/confirmed_import.dart';
import 'package:exel_category/application/dto/created_dataset_result.dart';
import 'package:exel_category/application/services/transaction_runner.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exel_category/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exel_category/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';

/// Application service responsible for orchestrating
/// the dataset creation flow after user confirmation.
///
/// This service coordinates multiple use cases and ensures
/// that the dataset is fully persisted:
/// - dataset metadata
/// - tables
/// - columns
/// - physical SQL tables
/// - data rows
class CreateDatasetService {
  final TransactionRunner transactionRunner;
  final CreateDatasetUseCase createDatasetUseCase;
  final RegisterDatasetFileUseCase registerDatasetFileUseCase;
  final CreateDatasetTableUseCase createDatasetTableUseCase;
  final RegisterColumnsUseCase registerColumnsUseCase;
  final BuildDynamicTableUseCase buildDynamicTableUseCase;
  final InsertRowsUseCase insertRowsUseCase;

  const CreateDatasetService({
    required this.transactionRunner,
    required this.createDatasetUseCase,
    required this.registerDatasetFileUseCase,
    required this.createDatasetTableUseCase,
    required this.registerColumnsUseCase,
    required this.buildDynamicTableUseCase,
    required this.insertRowsUseCase,
  });

  Future<CreatedDatasetResult> createDataset({
    required ConfirmedImport confirmedImport,
  }) async {
    if (confirmedImport.sheets.isEmpty) {
      throw Exception('Cannot create dataset without sheets');
    }

    return transactionRunner.run(() => _createDatasetInTransaction(confirmedImport));
  }

  Future<CreatedDatasetResult> _createDatasetInTransaction(
    ConfirmedImport confirmedImport,
  ) async {
    /// 1. Create dataset
    final dataset = await createDatasetUseCase.call(
      datasetName: confirmedImport.datasetName,
      sourceFileName: confirmedImport.sourceFileName,
    );

    if (confirmedImport.sourceFileReference != null) {
      await registerDatasetFileUseCase.call(
        datasetId: dataset.id,
        sourceFileReference: confirmedImport.sourceFileReference!,
      );
    }

    /// 2. Process each sheet
    for (final confirmedSheet in confirmedImport.sheets) {
      final sheet = confirmedSheet.sheet;

      if (confirmedSheet.columns.isEmpty) {
        throw Exception('Cannot create dataset table without columns');
      }

      /// 2.1 Create table metadata
      final table = await createDatasetTableUseCase.call(
        datasetId: dataset.id,
        sheetName: sheet.name,
        rowCount: sheet.rows.length,
        colCount: confirmedSheet.columns.length,
      );

      final columns = _attachTableId(
        confirmedSheet.columns,
        table.id,
      );

      /// 2.2 Register confirmed columns.
      await registerColumnsUseCase.call(
        datasetTableId: table.id,
        columns: columns,
      );

      /// 2.3 Create physical SQL table.
      await buildDynamicTableUseCase.call(
        table: table,
        columns: columns,
      );

      /// 2.4 Insert rows using confirmed database column names.
      await insertRowsUseCase.call(
        tableName: table.sqlTableName,
        rows: _mapRowsToDatabaseColumns(
          rows: sheet.rows,
          columns: columns,
        ),
      );
    }

    return CreatedDatasetResult(
      datasetId: dataset.id,
      datasetName: dataset.name,
      sourceFileName: dataset.sourceFileName,
      tableCount: confirmedImport.tableCount,
      columnCount: confirmedImport.columnCount,
      rowCount: confirmedImport.rowCount,
    );
  }

  List<DatasetColumn> _attachTableId(
    List<DatasetColumn> columns,
    int datasetTableId,
  ) {
    return columns
        .map(
          (column) => column.copyWith(
            datasetTableId: datasetTableId,
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>> _mapRowsToDatabaseColumns({
    required List<Map<String, dynamic>> rows,
    required List<DatasetColumn> columns,
  }) {
    if (rows.isEmpty) return [];

    return rows.map((row) {
      final mapped = <String, dynamic>{};

      for (final column in columns) {
        mapped[column.dbName] = _normalizeColumnValue(
          column.declaredType,
          row[column.originalName],
        );
      }

      return mapped;
    }).toList();
  }

  Object? _normalizeColumnValue(ColumnType type, Object? rawValue) {
    if (rawValue == null) return null;
    final str = rawValue.toString().trim();
    if (str.isEmpty) return null;

    if (type != ColumnType.boolean) return rawValue;

    final lower = str.toLowerCase();
    if (lower == 'true' || lower == 'yes' || lower == '1') return 1;
    if (lower == 'false' || lower == 'no' || lower == '0') return 0;
    return null;
  }
}
