import 'package:exel_category/data/schema/dynamic_table_builder.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  group('DynamicTableBuilder', () {

    late DynamicTableBuilder builder;

    setUp(() {

      /// Fresh builder instance before each test.
      builder = const DynamicTableBuilder();
    });

    test(
      'should generate valid CREATE TABLE SQL',
      () {

        /// Arrange
        final columns = [
          DatasetColumn(
            id: 0,
            datasetTableId: 1,
            originalName: 'product',
            dbName: 'product',
            declaredType: ColumnType.text,
            inferredType: ColumnType.text,
            nullable: false,
            statsJson: null,
          ),
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

        /// Act
        final sql = builder.buildCreateTableSql(
          tableName: 'products',
          columns: columns,
        );

        /// Assert
        expect(sql, contains('CREATE TABLE products'));
        expect(sql, contains('product TEXT NOT NULL'));
        expect(sql, contains('price REAL NOT NULL'));
        expect(sql, contains('id INTEGER PRIMARY KEY AUTOINCREMENT'));
      },
    );

    test(
      'should correctly map all ColumnType values',
      () {

        /// Arrange
        final columns = [
          DatasetColumn(
            id: 0,
            datasetTableId: 1,
            originalName: 'text_col',
            dbName: 'text_col',
            declaredType: ColumnType.text,
            inferredType: ColumnType.text,
            nullable: true,
            statsJson: null,
          ),
          DatasetColumn(
            id: 0,
            datasetTableId: 1,
            originalName: 'int_col',
            dbName: 'int_col',
            declaredType: ColumnType.integer,
            inferredType: ColumnType.integer,
            nullable: true,
            statsJson: null,
          ),
          DatasetColumn(
            id: 0,
            datasetTableId: 1,
            originalName: 'real_col',
            dbName: 'real_col',
            declaredType: ColumnType.real,
            inferredType: ColumnType.real,
            nullable: true,
            statsJson: null,
          ),
          DatasetColumn(
            id: 0,
            datasetTableId: 1,
            originalName: 'bool_col',
            dbName: 'bool_col',
            declaredType: ColumnType.boolean,
            inferredType: ColumnType.boolean,
            nullable: true,
            statsJson: null,
          ),
          DatasetColumn(
            id: 0,
            datasetTableId: 1,
            originalName: 'date_col',
            dbName: 'date_col',
            declaredType: ColumnType.date,
            inferredType: ColumnType.date,
            nullable: true,
            statsJson: null,
          ),
        ];

        /// Act
        final sql = builder.buildCreateTableSql(
          tableName: 'test',
          columns: columns,
        );

        /// Assert
        expect(sql, contains('text_col TEXT'));
        expect(sql, contains('int_col INTEGER'));
        expect(sql, contains('real_col REAL'));
        expect(sql, contains('bool_col INTEGER'));
        expect(sql, contains('date_col TEXT'));
      },
    );

    test(
      'should correctly handle nullable columns',
      () {

        /// Arrange
        final columns = [
          DatasetColumn(
            id: 0,
            datasetTableId: 1,
            originalName: 'optional_field',
            dbName: 'optional_field',
            declaredType: ColumnType.text,
            inferredType: ColumnType.text,
            nullable: true,
            statsJson: null,
          ),
        ];

        /// Act
        final sql = builder.buildCreateTableSql(
          tableName: 'nullable_test',
          columns: columns,
        );

        /// Assert
        expect(
          sql.contains('optional_field TEXT NOT NULL'),
          false,
        );

        expect(
          sql.contains('optional_field TEXT'),
          true,
        );
      },
    );

    test(
      'should throw exception when columns list is empty',
      () {

        /// Act & Assert
        expect(
          () => builder.buildCreateTableSql(
            tableName: 'invalid',
            columns: [],
          ),
          throwsException,
        );
      },
    );

    /// TODO:
    /// Add edge case tests:
    /// - invalid table name
    /// - SQL reserved keywords as column names
    /// - duplicated column names
    /// - extremely long column names
    /// - unicode column names
  });
}