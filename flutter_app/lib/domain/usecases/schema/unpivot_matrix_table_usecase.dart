import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/usecases/schema/detect_matrix_table_usecase.dart';

/// Unpivots a 2D cross-tab matrix into a normalized relational table (1NF).
///
/// Converts a wide matrix with columns:
/// `[ID1, ID2, ..., ColA, ColB, ColC]`
/// into a long table:
/// `[ID1, ID2, ..., DimensionColumn, ValueColumn]`
class UnpivotMatrixTableUseCase {
  const UnpivotMatrixTableUseCase();

  List<Map<String, dynamic>> call({
    required List<Map<String, dynamic>> rows,
    required List<String> idColumnNames,
    required List<String> valueColumnNames,
    required String dimensionColumnName,
    required String valueColumnName,
    bool skipEmptyValues = true,
  }) {
    if (rows.isEmpty || valueColumnNames.isEmpty) return rows;

    final unpivoted = <Map<String, dynamic>>[];

    for (final row in rows) {
      // Extract fixed ID entries for this row
      final idEntries = <String, dynamic>{};
      for (final idCol in idColumnNames) {
        idEntries[idCol] = row[idCol];
      }

      // Create a normalized row for each value column
      for (final valCol in valueColumnNames) {
        final cellVal = row[valCol];

        if (skipEmptyValues) {
          if (cellVal == null) continue;
          if (cellVal is String && cellVal.trim().isEmpty) continue;
        }

        final newRow = Map<String, dynamic>.from(idEntries);
        newRow[dimensionColumnName] = valCol;
        newRow[valueColumnName] = cellVal;

        unpivoted.add(newRow);
      }
    }

    return unpivoted;
  }

  /// Convenience method to unpivot an entire ParsedSheet given a detected MatrixCandidate.
  ParsedSheet unpivotSheet(
    ParsedSheet sheet, {
    required MatrixCandidate candidate,
    String? customDimensionName,
    String? customValueName,
    bool skipEmptyValues = true,
  }) {
    final dimName =
        (customDimensionName != null && customDimensionName.trim().isNotEmpty)
            ? customDimensionName.trim()
            : candidate.suggestedDimensionName;
    final valName =
        (customValueName != null && customValueName.trim().isNotEmpty)
            ? customValueName.trim()
            : candidate.suggestedValueName;

    final unpivotedRows = call(
      rows: sheet.rows,
      idColumnNames: candidate.idColumnNames,
      valueColumnNames: candidate.valueColumnNames,
      dimensionColumnName: dimName,
      valueColumnName: valName,
      skipEmptyValues: skipEmptyValues,
    );

    return sheet.copyWith(rows: unpivotedRows);
  }
}
