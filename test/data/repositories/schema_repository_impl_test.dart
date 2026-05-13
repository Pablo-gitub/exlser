import 'package:exel_category/data/datasources/drift_datasource.dart';
import 'package:exel_category/data/repositories/schema_repository_impl.dart';
import 'package:exel_category/data/schema/dynamic_table_builder.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
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
}
