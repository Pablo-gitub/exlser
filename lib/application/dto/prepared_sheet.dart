import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/entities/dataset_column.dart';

/// Represents a parsed sheet enriched with inferred schema.
///
/// This model is used in the import preparation phase,
/// before the dataset is persisted.
class PreparedSheet {
  final ParsedSheet sheet;
  final List<DatasetColumn> inferredColumns;

  /// Currency symbols detected per column during schema inference.
  /// Key: column dbName, Value: detected symbol (e.g. "$", "€").
  final Map<String, String> columnCurrencySymbols;

  const PreparedSheet({
    required this.sheet,
    required this.inferredColumns,
    this.columnCurrencySymbols = const {},
  });
}
