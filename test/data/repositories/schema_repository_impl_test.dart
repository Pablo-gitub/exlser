import 'package:drift/native.dart';
import 'package:exel_category/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable;
import 'package:exel_category/core/database/daos/datasets_dao.dart';
import 'package:exel_category/data/datasources/drift_datasource.dart';
import 'package:exel_category/data/repositories/schema_repository_impl.dart';
import 'package:exel_category/data/schema/dynamic_table_builder.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart' as domain;
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatasource extends Mock implements DriftDatasource {}

class MockBuilder extends Mock implements DynamicTableBuilder {}

void main() {
  setUpAll(() {
    registerFallbackValue(() async {});
  });

  group('SchemaRepositoryImpl', () {
    late MockDatasource datasource;
    late MockBuilder builder;
    late SchemaRepositoryImpl repository;

    setUp(() {
      datasource = MockDatasource();
      builder = MockBuilder();

      repository = SchemaRepositoryImpl(
        datasource,
        builder,
      );
    });

    test(
      'createDynamicTable should call builder and datasource',
      () async {
        /// Arrange
        final columns = [
          DatasetColumn(
            id: 0,
            datasetTableId: 1,
            originalName: 'price',
            dbName: 'price',
            declaredType: ColumnType.real,
            inferredType: ColumnType.real,
            nullable: false,
            statsJson: null,
          ),
        ];

        when(() => builder.buildCreateTableSql(
              tableName: any(named: 'tableName'),
              columns: any(named: 'columns'),
            )).thenReturn('CREATE TABLE test');

        when(() => datasource.execute(any())).thenAnswer((_) async {});

        /// Act
        await repository.createDynamicTable(
          'test_table',
          columns,
        );

        /// Assert
        verify(() => builder.buildCreateTableSql(
              tableName: 'test_table',
              columns: columns,
            )).called(1);

        verify(() => datasource.execute(any())).called(1);
      },
    );

    test(
      'createDynamicTable should throw if columns are empty',
      () async {
        /// Act & Assert
        expect(
          () => repository.createDynamicTable(
            'test_table',
            [],
          ),
          throwsException,
        );
      },
    );

    test(
      'dropDynamicTable should execute correct SQL',
      () async {
        /// Arrange
        when(() => datasource.execute(any())).thenAnswer((_) async {});

        /// Act
        await repository.dropDynamicTable(
          'my_table',
        );

        /// Assert
        verify(() => datasource.execute(
              'DROP TABLE IF EXISTS my_table',
            )).called(1);
      },
    );

    test(
      'deleteSchemaForDataset should drop dynamic tables and delete metadata',
      () async {
        /// Arrange
        const datasetId = 7;

        when(() => datasource.query(
              any(),
              arguments: any(named: 'arguments'),
            )).thenAnswer(
          (_) async => [
            {'id': 10, 'sql_table_name': 'ds_7_sheet1'},
            {'id': 11, 'sql_table_name': 'ds_7_sheet2'},
          ],
        );

        when(() => datasource.runInTransaction(any())).thenAnswer(
          (invocation) async {
            final action =
                invocation.positionalArguments.first as Future<void> Function();
            await action();
          },
        );

        when(() => datasource.execute(any())).thenAnswer((_) async {});
        when(() => datasource.executeWithArgs(any(), any()))
            .thenAnswer((_) async {});

        /// Act
        await repository.deleteSchemaForDataset(datasetId);

        /// Assert
        verify(() => datasource.query(
              'SELECT id, sql_table_name FROM dataset_tables WHERE dataset_id = ?',
              arguments: [datasetId],
            )).called(1);

        verify(() => datasource.runInTransaction(any())).called(1);
        verify(() => datasource.execute('DROP TABLE IF EXISTS ds_7_sheet1'))
            .called(1);
        verify(() => datasource.execute('DROP TABLE IF EXISTS ds_7_sheet2'))
            .called(1);
        verify(() => datasource.executeWithArgs(
              'DELETE FROM dataset_columns WHERE dataset_table_id = ?',
              [10],
            )).called(1);
        verify(() => datasource.executeWithArgs(
              'DELETE FROM dataset_columns WHERE dataset_table_id = ?',
              [11],
            )).called(1);
        verify(() => datasource.executeWithArgs(
              'DELETE FROM dataset_tables WHERE dataset_id = ?',
              [datasetId],
            )).called(1);
      },
    );

    test(
      'deleteSchemaForDataset should throw when dataset id is invalid',
      () async {
        expect(
          () => repository.deleteSchemaForDataset(0),
          throwsException,
        );

        verifyNever(() => datasource.query(
              any(),
              arguments: any(named: 'arguments'),
            ));
        verifyNever(() => datasource.runInTransaction(any()));
      },
    );

    /// TODO:
    /// Add edge case tests:
    /// - invalid table name
    /// - SQL injection protection (tableName sanitization)
    /// - very long table names
  });

  group('SchemaRepositoryImpl metadata', () {
    late AppDatabase database;
    late DatasetsDao datasetsDao;
    late SchemaRepositoryImpl repository;
    late int datasetId;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      datasetsDao = DatasetsDao(database);
      repository = SchemaRepositoryImpl(
        DriftDatasource(database),
        DynamicTableBuilder(),
      );

      datasetId = await datasetsDao.createDataset(
        name: 'Dataset',
        sourceFileName: 'dataset.xlsx',
        createdAt: 1000,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('createDatasetTable should persist and return generated id', () async {
      final created = await repository.createDatasetTable(
        domain.DatasetTable(
          id: 0,
          datasetId: datasetId,
          sheetNameOriginal: '  Sales  ',
          sqlTableName: '  ds_sales  ',
          rowCount: 10,
          colCount: 2,
        ),
      );

      expect(created.id, greaterThan(0));
      expect(created.sheetNameOriginal, 'Sales');
      expect(created.sqlTableName, 'ds_sales');

      final persisted = await repository.getTableById(created.id);

      expect(persisted?.datasetId, datasetId);
      expect(persisted?.sheetNameOriginal, 'Sales');
      expect(persisted?.sqlTableName, 'ds_sales');
      expect(persisted?.rowCount, 10);
      expect(persisted?.colCount, 2);
    });

    test('getTablesForDataset should return only dataset tables', () async {
      final otherDatasetId = await datasetsDao.createDataset(
        name: 'Other',
        sourceFileName: 'other.xlsx',
        createdAt: 1001,
      );

      await repository.createDatasetTable(
        domain.DatasetTable(
          id: 0,
          datasetId: datasetId,
          sheetNameOriginal: 'Sales',
          sqlTableName: 'ds_sales',
          rowCount: 10,
          colCount: 2,
        ),
      );
      await repository.createDatasetTable(
        domain.DatasetTable(
          id: 0,
          datasetId: otherDatasetId,
          sheetNameOriginal: 'Other',
          sqlTableName: 'ds_other',
          rowCount: 1,
          colCount: 1,
        ),
      );

      final tables = await repository.getTablesForDataset(datasetId);

      expect(tables, hasLength(1));
      expect(tables.first.sheetNameOriginal, 'Sales');
    });

    test('updateDatasetTable should update table metadata', () async {
      final created = await repository.createDatasetTable(
        domain.DatasetTable(
          id: 0,
          datasetId: datasetId,
          sheetNameOriginal: 'Sales',
          sqlTableName: 'ds_sales',
          rowCount: 10,
          colCount: 2,
        ),
      );

      await repository.updateDatasetTable(
        created.copyWith(
          sheetNameOriginal: 'Updated Sales',
          sqlTableName: 'ds_updated_sales',
          rowCount: 20,
          colCount: 4,
        ),
      );

      final updated = await repository.getTableById(created.id);

      expect(updated?.sheetNameOriginal, 'Updated Sales');
      expect(updated?.sqlTableName, 'ds_updated_sales');
      expect(updated?.rowCount, 20);
      expect(updated?.colCount, 4);
    });

    test('createColumns should persist columns for a table', () async {
      final table = await _createTable(repository, datasetId);

      await repository.createColumns([
        DatasetColumn(
          id: 0,
          datasetTableId: table.id,
          originalName: 'Price',
          dbName: 'price',
          declaredType: ColumnType.real,
          inferredType: ColumnType.real,
          nullable: false,
          statsJson: '{"min":1}',
        ),
        DatasetColumn(
          id: 0,
          datasetTableId: table.id,
          originalName: 'Created At',
          dbName: 'created_at',
          declaredType: ColumnType.date,
          inferredType: ColumnType.text,
          nullable: true,
        ),
      ]);

      final columns = await repository.getColumnsForTable(table.id);

      expect(columns, hasLength(2));
      expect(columns.first.originalName, 'Price');
      expect(columns.first.declaredType, ColumnType.real);
      expect(columns.first.nullable, false);
      expect(columns.first.statsJson, '{"min":1}');
      expect(columns.last.declaredType, ColumnType.date);
      expect(columns.last.inferredType, ColumnType.text);
      expect(columns.last.nullable, true);
    });

    test('updateColumn should update column metadata', () async {
      final table = await _createTable(repository, datasetId);
      await repository.createColumns([
        DatasetColumn(
          id: 0,
          datasetTableId: table.id,
          originalName: 'Amount',
          dbName: 'amount',
          declaredType: ColumnType.integer,
          inferredType: ColumnType.integer,
          nullable: false,
        ),
      ]);
      final column = (await repository.getColumnsForTable(table.id)).single;

      await repository.updateColumn(
        column.copyWith(
          originalName: 'Amount EUR',
          dbName: 'amount_eur',
          declaredType: ColumnType.real,
          nullable: true,
          statsJson: '{"max":100}',
        ),
      );

      final updated = (await repository.getColumnsForTable(table.id)).single;

      expect(updated.originalName, 'Amount EUR');
      expect(updated.dbName, 'amount_eur');
      expect(updated.declaredType, ColumnType.real);
      expect(updated.nullable, true);
      expect(updated.statsJson, '{"max":100}');
    });

    test('deleteColumnsForTable should remove table columns', () async {
      final table = await _createTable(repository, datasetId);
      await repository.createColumns([
        DatasetColumn(
          id: 0,
          datasetTableId: table.id,
          originalName: 'Amount',
          dbName: 'amount',
          declaredType: ColumnType.integer,
          inferredType: ColumnType.integer,
          nullable: false,
        ),
      ]);

      await repository.deleteColumnsForTable(table.id);

      final columns = await repository.getColumnsForTable(table.id);

      expect(columns, isEmpty);
    });

    test('deleteDatasetTable should drop physical table and delete metadata',
        () async {
      final table = await _createTable(repository, datasetId);
      await repository.createColumns([
        DatasetColumn(
          id: 0,
          datasetTableId: table.id,
          originalName: 'Amount',
          dbName: 'amount',
          declaredType: ColumnType.integer,
          inferredType: ColumnType.integer,
          nullable: false,
        ),
      ]);
      await repository.createDynamicTable(table.sqlTableName, [
        DatasetColumn(
          id: 0,
          datasetTableId: table.id,
          originalName: 'Amount',
          dbName: 'amount',
          declaredType: ColumnType.integer,
          inferredType: ColumnType.integer,
          nullable: false,
        ),
      ]);

      await repository.deleteDatasetTable(table.id);

      expect(await repository.getTableById(table.id), isNull);
      expect(await repository.getColumnsForTable(table.id), isEmpty);
      expect(
        () => DriftDatasource(database).query(
          'SELECT * FROM ${table.sqlTableName}',
        ),
        throwsA(anything),
      );
    });

    test('metadata methods should reject invalid ids', () {
      expect(
        () => repository.getTablesForDataset(0),
        throwsException,
      );
      expect(
        () => repository.getTableById(0),
        throwsException,
      );
      expect(
        () => repository.getColumnsForTable(0),
        throwsException,
      );
      expect(
        () => repository.deleteColumnsForTable(0),
        throwsException,
      );
    });
  });
}

Future<domain.DatasetTable> _createTable(
  SchemaRepositoryImpl repository,
  int datasetId,
) {
  return repository.createDatasetTable(
    domain.DatasetTable(
      id: 0,
      datasetId: datasetId,
      sheetNameOriginal: 'Sales',
      sqlTableName: 'ds_sales',
      rowCount: 10,
      colCount: 2,
    ),
  );
}
