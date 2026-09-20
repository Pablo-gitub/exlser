import 'package:exlser/core/normalizers/boolean_normalizer.dart';
import 'package:exlser/core/normalizers/date_normalizer.dart';
import 'package:exlser/core/normalizers/number_normalizer.dart';
import 'package:exlser/domain/value_objects/column_type.dart';

/// Represents a detected cross-tab matrix candidate.
class MatrixCandidate {
  final List<String> idColumnNames;
  final List<String> valueColumnNames;
  final String suggestedDimensionName;
  final String suggestedValueName;
  final ColumnType inferredValueType;

  const MatrixCandidate({
    required this.idColumnNames,
    required this.valueColumnNames,
    required this.suggestedDimensionName,
    required this.suggestedValueName,
    required this.inferredValueType,
  });
}

/// Detects whether tabular data represents a 2D cross-tab matrix.
///
/// In spreadsheet files, users frequently build cross-tab reports
/// where row headers are entities (e.g. Products) and column headers
/// represent dimension intervals (e.g. Months, Years, Quarters),
/// with homogeneous values in the cells (e.g. quantities, amounts).
class DetectMatrixTableUseCase {
  final NumberNormalizer numberNormalizer;
  final DateNormalizer dateNormalizer;
  final BooleanNormalizer booleanNormalizer;

  DetectMatrixTableUseCase({
    NumberNormalizer? numberNormalizer,
    DateNormalizer? dateNormalizer,
    BooleanNormalizer? booleanNormalizer,
  })  : numberNormalizer = numberNormalizer ?? NumberNormalizer(),
        dateNormalizer = dateNormalizer ?? DateNormalizer(),
        booleanNormalizer = booleanNormalizer ?? BooleanNormalizer();

  MatrixCandidate? call(List<Map<String, dynamic>> rows) {
    if (rows.length < 2) return null;

    final columnNames = rows.first.keys.toList();
    if (columnNames.length < 3) return null;

    // Strategy 1: Check for a contiguous suffix of headers forming a recognized series.
    final headerSeriesCandidate = _findHeaderSeriesSuffix(rows, columnNames);
    if (headerSeriesCandidate != null) {
      return headerSeriesCandidate;
    }

    // Strategy 2: Check for a contiguous suffix of columns sharing the same non-text body type.
    final bodyTypeCandidate = _findHomogeneousBodySuffix(rows, columnNames);
    if (bodyTypeCandidate != null) {
      return bodyTypeCandidate;
    }

    return null;
  }

  MatrixCandidate? _findHeaderSeriesSuffix(
    List<Map<String, dynamic>> rows,
    List<String> columnNames,
  ) {
    // Map each column header to its series type (if any)
    final seriesTypes = columnNames.map(_detectSeriesType).toList();

    // Find the longest suffix starting at k >= 1 where all headers share the same series type.
    for (var k = 1; k <= columnNames.length - 2; k++) {
      final candidateType = seriesTypes[k];
      if (candidateType == null) continue;

      // Ensure all columns from k to end share the candidate series type
      bool allMatch = true;
      for (var i = k; i < columnNames.length; i++) {
        if (seriesTypes[i] != candidateType) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) {
        final idColumns = columnNames.sublist(0, k);
        final valueColumns = columnNames.sublist(k);
        final bodyType = _analyzeBodyValues(rows, valueColumns);

        if (bodyType != null) {
          return MatrixCandidate(
            idColumnNames: idColumns,
            valueColumnNames: valueColumns,
            suggestedDimensionName: _suggestDimensionName(candidateType),
            suggestedValueName: 'Value',
            inferredValueType: bodyType,
          );
        }
      }
    }

    return null;
  }

  MatrixCandidate? _findHomogeneousBodySuffix(
    List<Map<String, dynamic>> rows,
    List<String> columnNames,
  ) {
    final colTypes = <ColumnType>[];
    for (final col in columnNames) {
      colTypes.add(_inferSingleColumnType(rows, col));
    }

    // Find suffix starting at k >= 1 where all columns share a non-text type (numeric, bool, date)
    for (var k = 1; k <= columnNames.length - 2; k++) {
      final suffixType = colTypes[k];
      if (suffixType == ColumnType.text) continue;

      bool allMatch = true;
      for (var i = k; i < columnNames.length; i++) {
        final t = colTypes[i];
        final compatible =
            (suffixType == ColumnType.integer || suffixType == ColumnType.real)
                ? (t == ColumnType.integer || t == ColumnType.real)
                : t == suffixType;
        if (!compatible) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) {
        final idColumns = columnNames.sublist(0, k);
        // Ensure id columns are predominantly text
        if (_isIdColumnText(rows, idColumns)) {
          final valueColumns = columnNames.sublist(k);
          final finalType = colTypes.sublist(k).contains(ColumnType.real)
              ? ColumnType.real
              : suffixType;

          return MatrixCandidate(
            idColumnNames: idColumns,
            valueColumnNames: valueColumns,
            suggestedDimensionName: 'Period',
            suggestedValueName: 'Value',
            inferredValueType: finalType,
          );
        }
      }
    }

    return null;
  }

  ColumnType _inferSingleColumnType(
    List<Map<String, dynamic>> rows,
    String columnName,
  ) {
    int intCount = 0;
    int realCount = 0;
    int dateCount = 0;
    int boolCount = 0;
    int totalNonEmpty = 0;

    for (final row in rows) {
      final val = row[columnName]?.toString().trim();
      if (val == null || val.isEmpty) continue;
      totalNonEmpty++;

      final numVal = numberNormalizer.tryNormalize(val);
      if (numVal != null) {
        if (numVal % 1 == 0) {
          intCount++;
        } else {
          realCount++;
        }
        continue;
      }

      if (booleanNormalizer.tryNormalize(val) != null) {
        boolCount++;
        continue;
      }

      if (dateNormalizer.tryNormalize(val) != null) {
        dateCount++;
        continue;
      }
    }

    if (totalNonEmpty == 0) return ColumnType.text;

    final numTotal = intCount + realCount;
    if (numTotal / totalNonEmpty >= 0.75) {
      return realCount > 0 ? ColumnType.real : ColumnType.integer;
    }
    if (dateCount / totalNonEmpty >= 0.75) return ColumnType.date;
    if (boolCount / totalNonEmpty >= 0.75) return ColumnType.boolean;

    return ColumnType.text;
  }

  _HeaderSeriesType? _detectSeriesType(String header) {
    final clean = header.trim().toLowerCase();
    if (_isMonth(clean)) return _HeaderSeriesType.months;
    if (_isQuarter(clean)) return _HeaderSeriesType.quarters;
    if (_isYear(clean)) return _HeaderSeriesType.years;
    if (dateNormalizer.tryNormalize(header.trim()) != null) {
      return _HeaderSeriesType.dates;
    }
    if (numberNormalizer.tryNormalize(clean) != null) {
      return _HeaderSeriesType.numbers;
    }
    return null;
  }

  bool _isIdColumnText(
    List<Map<String, dynamic>> rows,
    List<String> idColumns,
  ) {
    for (final col in idColumns) {
      int nonNumberCount = 0;
      int totalCount = 0;
      for (final row in rows) {
        final val = row[col]?.toString().trim();
        if (val == null || val.isEmpty) continue;
        totalCount++;
        if (numberNormalizer.tryNormalize(val) == null) {
          nonNumberCount++;
        }
      }
      if (totalCount > 0 && (nonNumberCount / totalCount) >= 0.5) {
        return true;
      }
    }
    return false;
  }

  String _suggestDimensionName(_HeaderSeriesType type) {
    switch (type) {
      case _HeaderSeriesType.months:
        return 'Month';
      case _HeaderSeriesType.years:
        return 'Year';
      case _HeaderSeriesType.quarters:
        return 'Quarter';
      case _HeaderSeriesType.dates:
        return 'Date';
      case _HeaderSeriesType.numbers:
        return 'Period';
    }
  }

  ColumnType? _analyzeBodyValues(
    List<Map<String, dynamic>> rows,
    List<String> valueColumns,
  ) {
    int intCount = 0;
    int realCount = 0;
    int dateCount = 0;
    int boolCount = 0;
    int totalNonEmpty = 0;

    for (final row in rows) {
      for (final col in valueColumns) {
        final val = row[col]?.toString().trim();
        if (val == null || val.isEmpty) continue;
        totalNonEmpty++;

        final numVal = numberNormalizer.tryNormalize(val);
        if (numVal != null) {
          if (numVal % 1 == 0) {
            intCount++;
          } else {
            realCount++;
          }
          continue;
        }

        if (booleanNormalizer.tryNormalize(val) != null) {
          boolCount++;
          continue;
        }

        if (dateNormalizer.tryNormalize(val) != null) {
          dateCount++;
          continue;
        }
      }
    }

    if (totalNonEmpty == 0) return null;

    final numTotal = intCount + realCount;
    if (numTotal / totalNonEmpty >= 0.75) {
      return realCount > 0 ? ColumnType.real : ColumnType.integer;
    }
    if (dateCount / totalNonEmpty >= 0.75) {
      return ColumnType.date;
    }
    if (boolCount / totalNonEmpty >= 0.75) {
      return ColumnType.boolean;
    }

    return ColumnType.text;
  }

  static bool _isMonth(String s) {
    const months = {
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
      'january',
      'february',
      'march',
      'april',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
      'gen',
      'mag',
      'giu',
      'lug',
      'ago',
      'sett',
      'ott',
      'dic',
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
      'ene',
      'abr',
      'enero',
      'febrero',
      'abril',
      'junio',
      'julio',
      'septiembre',
      'janv',
      'fevr',
      'mars',
      'avr',
      'juin',
      'juil',
      'aout',
      'janvier',
      'fevrier',
      'juillet',
      'okt',
      'dez',
      'januar',
      'marz',
    };
    return months.contains(s);
  }

  static bool _isYear(String s) {
    if (s.length == 4 && (s.startsWith('19') || s.startsWith('20'))) {
      return int.tryParse(s) != null;
    }
    if (s.startsWith("'") && s.length == 3) {
      return int.tryParse(s.substring(1)) != null;
    }
    return false;
  }

  static bool _isQuarter(String s) {
    final regex =
        RegExp(r'^(q[1-4]|[1-4]q|quarter\s*[1-4])$', caseSensitive: false);
    return regex.hasMatch(s);
  }
}

enum _HeaderSeriesType {
  months,
  years,
  quarters,
  dates,
  numbers,
}
