//lib/domain/entities/dataset_column.dart

import 'package:exlser/domain/value_objects/column_type.dart';

/// Domain entity representing metadata of a column inside a dataset table.
class DatasetColumn {
  final int id;
  final int datasetTableId;
  final String originalName;
  final String dbName;
  final ColumnType declaredType;
  final ColumnType inferredType;
  final bool nullable;
  final String? statsJson;

  const DatasetColumn({
    required this.id,
    required this.datasetTableId,
    required this.originalName,
    required this.dbName,
    required this.declaredType,
    required this.inferredType,
    required this.nullable,
    this.statsJson,
  });

  DatasetColumn copyWith({
    int? id,
    int? datasetTableId,
    String? originalName,
    String? dbName,
    ColumnType? declaredType,
    ColumnType? inferredType,
    bool? nullable,
    String? statsJson,
  }) {
    return DatasetColumn(
      id: id ?? this.id,
      datasetTableId: datasetTableId ?? this.datasetTableId,
      originalName: originalName ?? this.originalName,
      dbName: dbName ?? this.dbName,
      declaredType: declaredType ?? this.declaredType,
      inferredType: inferredType ?? this.inferredType,
      nullable: nullable ?? this.nullable,
      statsJson: statsJson ?? this.statsJson,
    );
  }

  bool get isText => declaredType == ColumnType.text;

  bool get isInteger => declaredType == ColumnType.integer;

  bool get isReal => declaredType == ColumnType.real;

  bool get isBoolean => declaredType == ColumnType.boolean;

  bool get isDate => declaredType == ColumnType.date;

  bool get isNumeric =>
      declaredType == ColumnType.integer || declaredType == ColumnType.real;

  bool get supportsRangeQuery => isNumeric || isDate;
}
