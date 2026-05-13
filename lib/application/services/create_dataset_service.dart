import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/source_file_reference.dart';
import 'package:exel_category/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exel_category/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exel_category/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exel_category/domain/usecases/schema/infer_schema_usecase.dart';

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
  final CreateDatasetUseCase createDatasetUseCase;
  final RegisterDatasetFileUseCase registerDatasetFileUseCase;
  final CreateDatasetTableUseCase createDatasetTableUseCase;
  final RegisterColumnsUseCase registerColumnsUseCase;
  final BuildDynamicTableUseCase buildDynamicTableUseCase;
  final InsertRowsUseCase insertRowsUseCase;
  final InferSchemaUseCase inferSchemaUseCase;

  const CreateDatasetService({
    required this.createDatasetUseCase,
    required this.registerDatasetFileUseCase,
    required this.createDatasetTableUseCase,
    required this.registerColumnsUseCase,
    required this.buildDynamicTableUseCase,
    required this.insertRowsUseCase,
    required this.inferSchemaUseCase,
  });

  Future<void> createDataset({
    required String datasetName,
    required String sourceFileName,
    SourceFileReference? sourceFileReference,
    required List<ParsedSheet> sheets,
  }) async {
    /// 1. Create dataset
    final dataset = await createDatasetUseCase.call(
      datasetName: datasetName,
      sourceFileName: sourceFileName,
    );

    if (sourceFileReference != null) {
      await registerDatasetFileUseCase.call(
        datasetId: dataset.id,
        sourceFileReference: sourceFileReference,
      );
    }

    /// 2. Process each sheet
    for (final sheet in sheets) {
      /// 2.1 Create table metadata
      final table = await createDatasetTableUseCase.call(
        datasetId: dataset.id,
        sheetName: sheet.name,
        rowCount: sheet.rows.length,
        colCount: sheet.rows.isNotEmpty ? sheet.rows.first.keys.length : 0,
      );

      /// 2.2 Convert to matrix for schema inference
      final rawRows = _convertToMatrix(sheet.rows);

      /// 2.3 Infer schema
      final columns = inferSchemaUseCase.call(
        rawRows,
        table.id,
      );

      /// 2.4 Register columns (FIX IMPORTANTE)
      await registerColumnsUseCase.call(
        datasetTableId: table.id,
        columns: columns,
      );

      /// 2.5 Create physical SQL table
      await buildDynamicTableUseCase.call(
        table: table,
        columns: columns,
      );

      /// 2.6 Insert rows
      await insertRowsUseCase.call(
        tableName: table.sqlTableName,
        rows: sheet.rows,
      );
    }
  }

  List<List<String>> _convertToMatrix(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return [];

    final headers = rows.first.keys.toList();

    final matrix = <List<String>>[];

    matrix.add(headers);

    for (final row in rows) {
      matrix.add(
        headers.map((h) => row[h]?.toString() ?? '').toList(),
      );
    }

    return matrix;
  }
}
