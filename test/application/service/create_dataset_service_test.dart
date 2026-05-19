import 'package:exel_category/application/dto/confirmed_import.dart';
import 'package:exel_category/application/services/create_dataset_service.dart';
import 'package:exel_category/application/services/transaction_runner.dart';
import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/source_file_reference.dart';
import 'package:exel_category/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exel_category/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exel_category/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

class MockTransactionRunner extends Mock implements TransactionRunner {}

class FakeDatasetTable extends Fake implements DatasetTable {}

class FakeDatasetColumn extends Fake implements DatasetColumn {}

/// Executes the action directly with no real transaction.
/// Used to unit-test service logic independently of the database.
class PassthroughTransactionRunner implements TransactionRunner {
  int runCallCount = 0;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    runCallCount++;
    return action();
  }
}

void main() {
  late CreateDatasetService service;
  late PassthroughTransactionRunner transactionRunner;
  late MockCreateDatasetUseCase createDatasetUseCase;
  late MockRegisterDatasetFileUseCase registerDatasetFileUseCase;
  late MockCreateDatasetTableUseCase createDatasetTableUseCase;
  late MockRegisterColumnsUseCase registerColumnsUseCase;
  late MockBuildDynamicTableUseCase buildDynamicTableUseCase;
  late MockInsertRowsUseCase insertRowsUseCase;

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
    transactionRunner = PassthroughTransactionRunner();
    createDatasetUseCase = MockCreateDatasetUseCase();
    registerDatasetFileUseCase = MockRegisterDatasetFileUseCase();
    createDatasetTableUseCase = MockCreateDatasetTableUseCase();
    registerColumnsUseCase = MockRegisterColumnsUseCase();
    buildDynamicTableUseCase = MockBuildDynamicTableUseCase();
    insertRowsUseCase = MockInsertRowsUseCase();

    service = CreateDatasetService(
      transactionRunner: transactionRunner,
      createDatasetUseCase: createDatasetUseCase,
      registerDatasetFileUseCase: registerDatasetFileUseCase,
      createDatasetTableUseCase: createDatasetTableUseCase,
      registerColumnsUseCase: registerColumnsUseCase,
      buildDynamicTableUseCase: buildDynamicTableUseCase,
      insertRowsUseCase: insertRowsUseCase,
    );
  });

  void mockDatasetCreation(Dataset dataset) {
    when(() => createDatasetUseCase.call(
          datasetName: any(named: 'datasetName'),
          sourceFileName: any(named: 'sourceFileName'),
        )).thenAnswer((_) async => dataset);
  }

  void mockTableCreation(DatasetTable table) {
    when(() => createDatasetTableUseCase.call(
          datasetId: any(named: 'datasetId'),
          sheetName: any(named: 'sheetName'),
          rowCount: any(named: 'rowCount'),
          colCount: any(named: 'colCount'),
        )).thenAnswer((_) async => table);
  }

  void mockColumnRegistration() {
    when(() => registerColumnsUseCase.call(
          datasetTableId: any(named: 'datasetTableId'),
          columns: any(named: 'columns'),
        )).thenAnswer((_) async {});
  }

  void mockDynamicTableCreation() {
    when(() => buildDynamicTableUseCase.call(
          table: any(named: 'table'),
          columns: any(named: 'columns'),
        )).thenAnswer((_) async {});
  }

  void mockRowInsertion() {
    when(() => insertRowsUseCase.call(
          tableName: any(named: 'tableName'),
          rows: any(named: 'rows'),
        )).thenAnswer((_) async {});
  }

  test('should execute full dataset creation flow with confirmed schema',
      () async {
    final confirmedImport = _confirmedImport();
    final dataset = _dataset();
    final table = _table();

    mockDatasetCreation(dataset);
    mockTableCreation(table);
    mockColumnRegistration();
    mockDynamicTableCreation();
    mockRowInsertion();

    final result = await service.createDataset(
      confirmedImport: confirmedImport,
    );

    expect(result.datasetId, dataset.id);
    expect(result.datasetName, dataset.name);
    expect(result.sourceFileName, dataset.sourceFileName);
    expect(result.tableCount, 1);
    expect(result.columnCount, 2);
    expect(result.rowCount, 2);

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

    final registeredColumns = verify(
      () => registerColumnsUseCase.call(
        datasetTableId: table.id,
        columns: captureAny(named: 'columns'),
      ),
    ).captured.single as List<DatasetColumn>;

    expect(
      registeredColumns.map((column) => column.datasetTableId),
      [table.id, table.id],
    );
    expect(
      registeredColumns.map((column) => column.declaredType),
      [ColumnType.text, ColumnType.real],
    );

    verify(() => buildDynamicTableUseCase.call(
          table: table,
          columns: any(named: 'columns'),
        )).called(1);

    verify(() => insertRowsUseCase.call(
          tableName: table.sqlTableName,
          rows: any(named: 'rows'),
        )).called(1);
  });

  test('should process multiple confirmed sheets', () async {
    final confirmedImport = ConfirmedImport(
      datasetName: 'Test',
      sourceFileName: 'file.xlsx',
      sheets: [
        _confirmedSheet(
          sheetName: 'Sheet1',
          rows: [
            {'a': '1'},
          ],
          columns: [
            _column(originalName: 'a', dbName: 'a'),
          ],
        ),
        _confirmedSheet(
          sheetName: 'Sheet2',
          rows: [
            {'b': '2'},
          ],
          columns: [
            _column(originalName: 'b', dbName: 'b'),
          ],
        ),
      ],
    );

    mockDatasetCreation(_dataset());
    when(() => createDatasetTableUseCase.call(
          datasetId: any(named: 'datasetId'),
          sheetName: any(named: 'sheetName'),
          rowCount: any(named: 'rowCount'),
          colCount: any(named: 'colCount'),
        )).thenAnswer(
      (_) async => _table(),
    );
    mockColumnRegistration();
    mockDynamicTableCreation();
    mockRowInsertion();

    final result = await service.createDataset(
      confirmedImport: confirmedImport,
    );

    expect(result.tableCount, 2);
    expect(result.columnCount, 2);
    expect(result.rowCount, 2);
    verify(() => createDatasetTableUseCase.call(
          datasetId: 1,
          sheetName: any(named: 'sheetName'),
          rowCount: 1,
          colCount: 1,
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
    final confirmedImport = _confirmedImport(
      sourceFileReference: sourceFileReference,
    );
    final dataset = _dataset(id: 7);

    mockDatasetCreation(dataset);
    mockTableCreation(_table(datasetId: dataset.id));
    mockColumnRegistration();
    mockDynamicTableCreation();
    mockRowInsertion();
    when(() => registerDatasetFileUseCase.call(
          datasetId: any(named: 'datasetId'),
          sourceFileReference: any(named: 'sourceFileReference'),
        )).thenAnswer(
      (_) async => sourceFileReference.toDatasetFile(
        datasetId: dataset.id,
        id: 1,
      ),
    );

    await service.createDataset(
      confirmedImport: confirmedImport,
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

  test('should insert rows using confirmed database column names', () async {
    final confirmedImport = ConfirmedImport(
      datasetName: 'Test',
      sourceFileName: 'file.xlsx',
      sheets: [
        _confirmedSheet(
          rows: [
            {
              'Product Name': 'book',
              'Unit Price': '10',
            },
          ],
          columns: [
            _column(
              originalName: 'Product Name',
              dbName: 'product_name',
            ),
            _column(
              originalName: 'Unit Price',
              dbName: 'unit_price',
              type: ColumnType.real,
            ),
          ],
        ),
      ],
    );

    mockDatasetCreation(_dataset());
    mockTableCreation(_table());
    mockColumnRegistration();
    mockDynamicTableCreation();
    mockRowInsertion();

    await service.createDataset(
      confirmedImport: confirmedImport,
    );

    final insertedRows = verify(
      () => insertRowsUseCase.call(
        tableName: 'ds_1_sheet1',
        rows: captureAny(named: 'rows'),
      ),
    ).captured.single as List<Map<String, dynamic>>;

    expect(insertedRows, [
      {
        'product_name': 'book',
        'unit_price': '10',
      },
    ]);
  });

  test('should normalize boolean string values to integers on insert',
      () async {
    final confirmedImport = ConfirmedImport(
      datasetName: 'Test',
      sourceFileName: 'file.csv',
      sheets: [
        _confirmedSheet(
          rows: [
            {'active': 'true', 'deleted': 'false'},
            {'active': 'yes', 'deleted': 'no'},
            {'active': '1', 'deleted': '0'},
            {'active': 'TRUE', 'deleted': 'FALSE'},
          ],
          columns: [
            _column(
              originalName: 'active',
              dbName: 'active',
              type: ColumnType.boolean,
            ),
            _column(
              originalName: 'deleted',
              dbName: 'deleted',
              type: ColumnType.boolean,
            ),
          ],
        ),
      ],
    );

    mockDatasetCreation(_dataset());
    mockTableCreation(_table());
    mockColumnRegistration();
    mockDynamicTableCreation();
    mockRowInsertion();

    await service.createDataset(confirmedImport: confirmedImport);

    final insertedRows = verify(
      () => insertRowsUseCase.call(
        tableName: 'ds_1_sheet1',
        rows: captureAny(named: 'rows'),
      ),
    ).captured.single as List<Map<String, dynamic>>;

    expect(insertedRows, [
      {'active': 1, 'deleted': 0},
      {'active': 1, 'deleted': 0},
      {'active': 1, 'deleted': 0},
      {'active': 1, 'deleted': 0},
    ]);
  });

  test('should propagate error if table creation fails', () async {
    mockDatasetCreation(_dataset());
    when(() => createDatasetTableUseCase.call(
          datasetId: any(named: 'datasetId'),
          sheetName: any(named: 'sheetName'),
          rowCount: any(named: 'rowCount'),
          colCount: any(named: 'colCount'),
        )).thenThrow(Exception('DB error'));

    expect(
      () => service.createDataset(
        confirmedImport: _confirmedImport(),
      ),
      throwsException,
    );
  });

  test('should throw if confirmed import has no sheets', () async {
    expect(
      () => service.createDataset(
        confirmedImport: const ConfirmedImport(
          datasetName: 'Test',
          sourceFileName: 'file.xlsx',
          sheets: [],
        ),
      ),
      throwsException,
    );

    verifyNever(() => createDatasetUseCase.call(
          datasetName: any(named: 'datasetName'),
          sourceFileName: any(named: 'sourceFileName'),
        ));
  });

  group('atomicity', () {
    test('wraps all steps inside a transaction on success', () async {
      mockDatasetCreation(_dataset());
      mockTableCreation(_table());
      mockColumnRegistration();
      mockDynamicTableCreation();
      mockRowInsertion();

      await service.createDataset(confirmedImport: _confirmedImport());

      expect(transactionRunner.runCallCount, 1);
    });

    test('propagates exception when buildDynamicTable fails', () async {
      mockDatasetCreation(_dataset());
      mockTableCreation(_table());
      mockColumnRegistration();
      when(() => buildDynamicTableUseCase.call(
            table: any(named: 'table'),
            columns: any(named: 'columns'),
          )).thenThrow(Exception('duplicate column "id"'));
      mockRowInsertion();

      await expectLater(
        () => service.createDataset(confirmedImport: _confirmedImport()),
        throwsException,
      );

      // Transaction runner was still entered — rollback is its responsibility
      expect(transactionRunner.runCallCount, 1);
    });

    test('propagates exception when insertRows fails', () async {
      mockDatasetCreation(_dataset());
      mockTableCreation(_table());
      mockColumnRegistration();
      mockDynamicTableCreation();
      when(() => insertRowsUseCase.call(
            tableName: any(named: 'tableName'),
            rows: any(named: 'rows'),
          )).thenThrow(Exception('insert failed'));

      await expectLater(
        () => service.createDataset(confirmedImport: _confirmedImport()),
        throwsException,
      );

      expect(transactionRunner.runCallCount, 1);
    });

    test('does not enter transaction when sheets list is empty', () async {
      await expectLater(
        () => service.createDataset(
          confirmedImport: const ConfirmedImport(
            datasetName: 'Test',
            sourceFileName: 'file.xlsx',
            sheets: [],
          ),
        ),
        throwsException,
      );

      expect(transactionRunner.runCallCount, 0);
      verifyNever(() => createDatasetUseCase.call(
            datasetName: any(named: 'datasetName'),
            sourceFileName: any(named: 'sourceFileName'),
          ));
    });
  });
}

Dataset _dataset({
  int id = 1,
}) {
  return Dataset(
    id: id,
    name: 'Test',
    sourceFileName: 'file.xlsx',
    createdAt: 0,
    lastOpenedAt: null,
  );
}

DatasetTable _table({
  int id = 10,
  int datasetId = 1,
}) {
  return DatasetTable(
    id: id,
    datasetId: datasetId,
    sheetNameOriginal: 'Sheet1',
    sqlTableName: 'ds_1_sheet1',
    rowCount: 2,
    colCount: 2,
  );
}

ConfirmedImport _confirmedImport({
  SourceFileReference? sourceFileReference,
}) {
  return ConfirmedImport(
    datasetName: 'Test',
    sourceFileName: 'file.xlsx',
    sourceFileReference: sourceFileReference,
    sheets: [
      _confirmedSheet(),
    ],
  );
}

ConfirmedImportSheet _confirmedSheet({
  String sheetName = 'Sheet1',
  List<Map<String, dynamic>>? rows,
  List<DatasetColumn>? columns,
}) {
  return ConfirmedImportSheet(
    sheet: ParsedSheet(
      name: sheetName,
      rows: rows ??
          [
            {'product': 'book', 'price': '10'},
            {'product': 'pen', 'price': '2'},
          ],
    ),
    columns: columns ??
        [
          _column(originalName: 'product', dbName: 'product'),
          _column(
            originalName: 'price',
            dbName: 'price',
            type: ColumnType.real,
          ),
        ],
  );
}

DatasetColumn _column({
  required String originalName,
  required String dbName,
  ColumnType type = ColumnType.text,
}) {
  return DatasetColumn(
    id: 0,
    datasetTableId: 0,
    originalName: originalName,
    dbName: dbName,
    declaredType: type,
    inferredType: type,
    nullable: false,
    statsJson: null,
  );
}
