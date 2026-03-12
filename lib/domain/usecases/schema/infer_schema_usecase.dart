import 'package:exel_category/data/adapters/normalizers/boolean_normalizer.dart';
import 'package:exel_category/data/adapters/normalizers/date_normalizer.dart';
import 'package:exel_category/data/adapters/normalizers/number_normalizer.dart';
import 'package:exel_category/data/adapters/sanitizers/sql_name_sanitizer.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';

/// Infers the schema of a dataset from parsed tabular data.
///
/// This use case analyzes a sample of rows and determines
/// the most appropriate type for each column.
///
/// The inferred schema will later be confirmed or modified by the user.
///
/// Responsibilities:
/// - analyze headers and rows
/// - detect column types (text, integer, real, boolean, date)
/// - determine if columns are nullable
/// - produce DatasetColumn entities
///
/// This use case is pure domain logic and does not access repositories.
class InferSchemaUseCase {
  final NumberNormalizer numberNormalizer;
  final DateNormalizer dateNormalizer;
  final BooleanNormalizer booleanNormalizer;

  InferSchemaUseCase({
    required this.numberNormalizer,
    required this.dateNormalizer,
    required this.booleanNormalizer,
  });

  List<DatasetColumn> call(
    List<List<String>> rows,
    int datasetTableId,
  ) {
    if (rows.isEmpty) {
      throw Exception("Cannot infer schema from empty dataset");
    }

    final headers = rows.first;
    final dataRows = rows.skip(1).toList();

    final columns = <DatasetColumn>[];

    for (int colIndex = 0; colIndex < headers.length; colIndex++) {
      final header = headers[colIndex];

      final columnValues = dataRows
          .where((row) => colIndex < row.length)
          .map((row) => row[colIndex])
          .toList();

      final inferredType = _inferColumnType(columnValues);
      final nullable = columnValues.any((v) => v.trim().isEmpty);
      final dbName = SqlNameSanitizer.sanitize(header);

      columns.add(
        DatasetColumn(
          id: 0,
          datasetTableId: datasetTableId,
          originalName: header,
          dbName: dbName,
          declaredType: inferredType,
          inferredType: inferredType,
          nullable: nullable,
          statsJson: null,
        ),
      );
    }

    return columns;
  }

  ColumnType _inferColumnType(List<String> values) {
    bool couldBeBoolean = true;
    bool couldBeInteger = true;
    bool couldBeReal = true;
    bool couldBeDate = true;

    for (final value in values) {
      final trimmed = value.trim();

      if (trimmed.isEmpty) {
        continue;
      }

      if (booleanNormalizer.tryNormalize(trimmed) == null) {
        couldBeBoolean = false;
      }

      final normalizedNumber = numberNormalizer.tryNormalize(trimmed);
      if (normalizedNumber == null) {
        couldBeInteger = false;
        couldBeReal = false;
      } else {
        if (normalizedNumber % 1 != 0) {
          couldBeInteger = false;
        }
      }

      if (dateNormalizer.tryNormalize(trimmed) == null) {
        couldBeDate = false;
      }
    }

    if (couldBeBoolean) return ColumnType.boolean;
    if (couldBeInteger) return ColumnType.integer;
    if (couldBeReal) return ColumnType.real;
    if (couldBeDate) return ColumnType.date;

    return ColumnType.text;
  }
}