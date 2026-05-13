import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exel_category/application/services/create_dataset_service.dart';

import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/source_file_reference.dart';

import 'package:exel_category/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exel_category/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exel_category/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exel_category/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';

/// ---------------- MOCKS ----------------

class MockCreateDatasetUseCase extends Mock implements CreateDatasetUseCase {}

class MockRegisterDatasetFileUseCase extends Mock
    implements RegisterDatasetFileUseCase {}

class MockCreateDatasetTableUseCase extends Mock
    implements CreateDatasetTableUseCase {}

class MockRegisterColumnsUseCase extends Mock
    implements RegisterColumnsUseCase {}

class MockBuildDynamicTableUseCase extends Mock
    implements BuildDynamicTableUseCase {}

class MockInsertRowsUseCase extends Mock implements InsertRowsUseCase {}

class MockInferSchemaUseCase extends Mock implements InferSchemaUseCase {}

class FakeDatasetTable extends Fake implements DatasetTable {}

class FakeDatasetColumn extends Fake implements DatasetColumn {}

void main() {
  late CreateDatasetService service;

  late MockCreateDatasetUseCase createDatasetUseCase;
  late MockRegisterDatasetFileUseCase registerDatasetFileUseCase;
  late MockCreateDatasetTableUseCase createDatasetTableUseCase;
  late MockRegisterColumnsUseCase registerColumnsUseCase;
  late MockBuildDynamicTableUseCase buildDynamicTableUseCase;
  late MockInsertRowsUseCase insertRowsUseCase;
  late MockInferSchemaUseCase inferSchemaUseCase;

  setUpAll(() {
    registerFallbackValue(FakeDatasetTable());
    registerFallbackValue(FakeDatasetColumn());
    registerFallbackValue(<DatasetColumn>[]);
    registerFallbackValue(
      SourceFileReference(
        fileName: 'fallback.xlsx',
        storageMode: DatasetFileStorageMode.path,
        originalPath: '/tmp/fallback.xlsx',
        importedAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    createDatasetUseCase = MockCreateDatasetUseCase();
    registerDatasetFileUseCase = MockRegisterDatasetFileUseCase();
    createDatasetTableUseCase = MockCreateDatasetTableUseCase();
    registerColumnsUseCase = MockRegisterColumnsUseCase();
    buildDynamicTableUseCase = MockBuildDynamicTableUseCase();
    insertRowsUseCase = MockInsertRowsUseCase();
    inferSchemaUseCase = MockInferSchemaUseCase();

    service = CreateDatasetService(
      createDatasetUseCase: createDatasetUseCase,
      registerDatasetFileUseCase: registerDatasetFileUseCase,
      createDatasetTableUseCase: createDatasetTableUseCase,
      registerColumnsUseCase: registerColumnsUseCase,
      buildDynamicTableUseCase: buildDynamicTableUseCase,
      insertRowsUseCase: insertRowsUseCase,
      inferSchemaUseCase: inferSchemaUseCase,
    );
  });

  test('should execute full dataset creation flow', () async {
    /// ---------------- ARRANGE ----------------
    /// This test verifies the COMPLETE pipeline execution.
    ///
    /// Expected flow:
    /// 1. Dataset is created
    /// 2. Table is created
    /// 3. Schema is inferred
    /// 4. Columns are registered
    /// 5. SQL table is created
    /// 6. Rows are inserted

    final parsedSheets = [
      ParsedSheet(
        name: 'Sheet1',
        rows: [
          {'product': 'book', 'price': '10'},
          {'product': 'pen', 'price': '2'},
        ],
      ),
    ];

    /// Fake dataset returned by CreateDatasetUseCase
    final dataset = Dataset(
      id: 1,
      name: 'Test',
      sourceFileName: 'file.xlsx',
      createdAt: 0,
      lastOpenedAt: null,
    );

    /// Fake table returned by CreateDatasetTableUseCase
    final table = DatasetTable(
      id: 10,
      datasetId: 1,
      sheetNameOriginal: 'Sheet1',
      sqlTableName: 'ds_1_sheet1',
      rowCount: 2,
      colCount: 2,
    );

    /// Fake columns returned by InferSchemaUseCase
    final columns = [
      DatasetColumn(
        id: 0,
        datasetTableId: 10,
        originalName: 'product',
        dbName: 'product',
        declaredType: ColumnType.text,
        inferredType: ColumnType.text,
        nullable: false,
        statsJson: null,
      ),
    ];

    /// ---------------- MOCK CONFIGURATION ----------------
    /// Each dependency is mocked to isolate the service logic.

    /// Dataset creation
    when(() => createDatasetUseCase.call(
          datasetName: any(named: 'datasetName'),
          sourceFileName: any(named: 'sourceFileName'),
        )).thenAnswer((_) async => dataset);

    /// Table creation
    when(() => createDatasetTableUseCase.call(
          datasetId: any(named: 'datasetId'),
          sheetName: any(named: 'sheetName'),
          rowCount: any(named: 'rowCount'),
          colCount: any(named: 'colCount'),
        )).thenAnswer((_) async => table);

    /// Schema inference
    when(() => inferSchemaUseCase.call(any(), any())).thenReturn(columns);

    /// Column registration
    when(() => registerColumnsUseCase.call(
          datasetTableId: any(named: 'datasetTableId'),
          columns: any(named: 'columns'),
        )).thenAnswer((_) async {});

    /// Dynamic table creation
    when(() => buildDynamicTableUseCase.call(
          table: any(named: 'table'),
          columns: any(named: 'columns'),
        )).thenAnswer((_) async {});

    /// Row insertion
    when(() => insertRowsUseCase.call(
          tableName: any(named: 'tableName'),
          rows: any(named: 'rows'),
        )).thenAnswer((_) async {});

    /// ---------------- ACT ----------------

    await service.createDataset(
      datasetName: 'Test',
      sourceFileName: 'file.xlsx',
      sheets: parsedSheets,
    );

    /// ---------------- ASSERT ----------------
    /// Verify that every step in the pipeline is executed exactly once

    verify(() => createDatasetUseCase.call(
          datasetName: 'Test',
          sourceFileName: 'file.xlsx',
        )).called(1);

    verify(() => createDatasetTableUseCase.call(
          datasetId: dataset.id,
          sheetName: 'Sheet1',
          rowCount: 2,
          colCount: 2,
        )).called(1);

    verify(() => inferSchemaUseCase.call(any(), table.id)).called(1);

    verify(() => registerColumnsUseCase.call(
          datasetTableId: table.id,
          columns: columns,
        )).called(1);

    verify(() => buildDynamicTableUseCase.call(
          table: table,
          columns: columns,
        )).called(1);

    verify(() => insertRowsUseCase.call(
          tableName: table.sqlTableName,
          rows: parsedSheets.first.rows,
        )).called(1);
  });

  test('should process multiple sheets', () async {
    /// ---------------- ARRANGE ----------------
    /// This test verifies that the service correctly iterates
    /// over multiple sheets and executes the pipeline for each one.

    final sheets = [
      ParsedSheet(
        name: 'Sheet1',
        rows: [
          {'a': '1'}
        ],
      ),
      ParsedSheet(
        name: 'Sheet2',
        rows: [
          {'b': '2'}
        ],
      ),
    ];

    /// Fake dataset returned by CreateDatasetUseCase
    final dataset = Dataset(
      id: 1,
      name: 'Test',
      sourceFileName: 'file.xlsx',
      createdAt: 0,
      lastOpenedAt: null,
    );

    /// Fake table returned for each sheet
    final table = DatasetTable(
      id: 10,
      datasetId: 1,
      sheetNameOriginal: 'Sheet1',
      sqlTableName: 'table',
      rowCount: 1,
      colCount: 1,
    );

    /// Fake inferred columns
    final columns = [
      DatasetColumn(
        id: 0,
        datasetTableId: 10,
        originalName: 'a',
        dbName: 'a',
        declaredType: ColumnType.text,
        inferredType: ColumnType.text,
        nullable: false,
        statsJson: null,
      ),
    ];

    /// ---------------- MOCKS ----------------

    /// Dataset creation
    when(() => createDatasetUseCase.call(
          datasetName: any(named: 'datasetName'),
          sourceFileName: any(named: 'sourceFileName'),
        )).thenAnswer((_) async => dataset);

    /// Table creation (called for each sheet)
    when(() => createDatasetTableUseCase.call(
          datasetId: any(named: 'datasetId'),
          sheetName: any(named: 'sheetName'),
          rowCount: any(named: 'rowCount'),
          colCount: any(named: 'colCount'),
        )).thenAnswer((_) async => table);

    /// Schema inference
    when(() => inferSchemaUseCase.call(any(), any())).thenReturn(columns);

    /// Remaining steps (no-op)
    when(() => registerColumnsUseCase.call(
          datasetTableId: any(named: 'datasetTableId'),
          columns: any(named: 'columns'),
        )).thenAnswer((_) async {});

    when(() => buildDynamicTableUseCase.call(
          table: any(named: 'table'),
          columns: any(named: 'columns'),
        )).thenAnswer((_) async {});

    when(() => insertRowsUseCase.call(
          tableName: any(named: 'tableName'),
          rows: any(named: 'rows'),
        )).thenAnswer((_) async {});

    /// ---------------- ACT ----------------

    await service.createDataset(
      datasetName: 'Test',
      sourceFileName: 'file.xlsx',
      sheets: sheets,
    );

    /// ---------------- ASSERT ----------------
    /// The service must process BOTH sheets → called twice

    verify(() => createDatasetTableUseCase.call(
          datasetId: dataset.id,
          sheetName: any(named: 'sheetName'),
          rowCount: any(named: 'rowCount'),
          colCount: any(named: 'colCount'),
        )).called(2);
  });

  test('should register source file reference after dataset creation',
      () async {
    final sourceFileReference = SourceFileReference(
      fileName: 'file.xlsx',
      storageMode: DatasetFileStorageMode.path,
      originalPath: '/tmp/file.xlsx',
      importedAt: DateTime(2026, 1, 2),
      fileSize: 42,
    );

    final dataset = Dataset(
      id: 7,
      name: 'Test',
      sourceFileName: 'file.xlsx',
      createdAt: 0,
      lastOpenedAt: null,
    );

    when(() => createDatasetUseCase.call(
          datasetName: any(named: 'datasetName'),
          sourceFileName: any(named: 'sourceFileName'),
        )).thenAnswer((_) async => dataset);

    when(() => registerDatasetFileUseCase.call(
          datasetId: any(named: 'datasetId'),
          sourceFileReference: any(named: 'sourceFileReference'),
        )).thenAnswer((_) async => sourceFileReference.toDatasetFile(
          datasetId: dataset.id,
          id: 1,
        ));

    await service.createDataset(
      datasetName: 'Test',
      sourceFileName: 'file.xlsx',
      sourceFileReference: sourceFileReference,
      sheets: const [],
    );

    verifyInOrder([
      () => createDatasetUseCase.call(
            datasetName: 'Test',
            sourceFileName: 'file.xlsx',
          ),
      () => registerDatasetFileUseCase.call(
            datasetId: dataset.id,
            sourceFileReference: sourceFileReference,
          ),
    ]);
  });

  test('should propagate error if table creation fails', () async {
    /// ---------------- ARRANGE ----------------
    /// This test verifies that the service DOES NOT swallow errors.
    /// If a use case fails, the exception must propagate upward.

    final sheets = [
      ParsedSheet(
        name: 'Sheet1',
        rows: [
          {'a': '1'}
        ],
      ),
    ];

    final dataset = Dataset(
      id: 1,
      name: 'Test',
      sourceFileName: 'file.xlsx',
      createdAt: 0,
      lastOpenedAt: null,
    );

    /// ---------------- MOCKS ----------------

    /// Dataset creation works
    when(() => createDatasetUseCase.call(
          datasetName: any(named: 'datasetName'),
          sourceFileName: any(named: 'sourceFileName'),
        )).thenAnswer((_) async => dataset);

    /// Table creation FAILS
    when(() => createDatasetTableUseCase.call(
          datasetId: any(named: 'datasetId'),
          sheetName: any(named: 'sheetName'),
          rowCount: any(named: 'rowCount'),
          colCount: any(named: 'colCount'),
        )).thenThrow(Exception('DB error'));

    /// ---------------- ACT + ASSERT ----------------

    /// The exception must propagate → no silent failure
    expect(
      () => service.createDataset(
        datasetName: 'Test',
        sourceFileName: 'file.xlsx',
        sheets: sheets,
      ),
      throwsException,
    );
  });
}
