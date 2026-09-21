//lib/data/adapters/table_normalizers/table_boundary_detector.dart

/// Represents a detected rectangular table block extracted from a spreadsheet sheet.
class DetectedTableBlock {
  /// Extracted title, either from an isolated cell directly above the table
  /// or from a merged banner in the table's first row.
  final String? detectedTitle;

  /// 0-indexed top-left row coordinate in the sheet.
  final int startRow;

  /// 0-indexed top-left column coordinate in the sheet.
  final int startCol;

  /// 0-indexed bottom-right row coordinate in the sheet.
  final int endRow;

  /// 0-indexed bottom-right column coordinate in the sheet.
  final int endCol;

  /// The normalized 2D sub-matrix of rows (headers + data).
  /// Every row is guaranteed to have exactly `endCol - startCol + 1` elements.
  final List<List<dynamic>> rows;

  const DetectedTableBlock({
    this.detectedTitle,
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
    required this.rows,
  });

  /// Human-readable Excel cell range (e.g. `A1:D20`).
  String get cellRange =>
      '${TableBoundaryDetector.columnToLetter(startCol)}${startRow + 1}:'
      '${TableBoundaryDetector.columnToLetter(endCol)}${endRow + 1}';

  int get rowCount => rows.length;
  int get colCount => rows.isEmpty ? 0 : rows.first.length;

  /// Generates a suggested name for this table.
  ///
  /// If a [detectedTitle] is available, it is prioritized.
  /// Otherwise, falls back to [fallbackBaseName] with an optional [_indexSuffix].
  String suggestedTableName({String? fallbackBaseName, int? tableIndex}) {
    final title = detectedTitle?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    final base =
        (fallbackBaseName != null && fallbackBaseName.trim().isNotEmpty)
            ? fallbackBaseName.trim()
            : 'Table';
    if (tableIndex != null && tableIndex > 1) {
      return '${base}_$tableIndex';
    }
    return base;
  }
}

/// Helper representing an internal 2D bounding box during recursive segmentation.
class _BoundingBox {
  final int minRow;
  final int maxRow;
  final int minCol;
  final int maxCol;

  const _BoundingBox({
    required this.minRow,
    required this.maxRow,
    required this.minCol,
    required this.maxCol,
  });

  int get height => maxRow - minRow + 1;
  int get width => maxCol - minCol + 1;
}

/// 2D spatial table segmentation engine.
///
/// Analyzes a raw 2D grid of spreadsheet cells and segments it into distinct
/// table blocks. Handles:
/// - Vertically stacked tables separated by empty rows.
/// - Horizontally side-by-side tables separated by empty columns.
/// - Sparse / missing cells inside tables without premature splitting.
/// - Title extraction from isolated cells directly preceding a table.
/// - Banner titles in the first row of a block (single cell followed by blanks).
/// - Filtering of isolated metadata cells and noise.
/// An empty gutter splitting a box, expressed in row or column indexes.
class _Gutter {
  final bool isHorizontal;
  final int start;
  final int end;

  const _Gutter({
    required this.isHorizontal,
    required this.start,
    required this.end,
  });
}

class _Gap {
  final int start;
  final int end;

  const _Gap({required this.start, required this.end});

  int get size => end - start + 1;
}

class TableBoundaryDetector {
  /// Upper bound on the blocks one sheet can be segmented into. Guards against a
  /// grid engineered (or exported) to split on every other line.
  static const int maxDetectedBlocks = 200;

  /// Converts a 0-indexed column integer (0 -> A, 25 -> Z, 26 -> AA) to its Excel letter.
  static String columnToLetter(int colIndex) {
    if (colIndex < 0) return 'A';
    var result = '';
    var n = colIndex;
    while (n >= 0) {
      result = String.fromCharCode((n % 26) + 65) + result;
      n = (n ~/ 26) - 1;
    }
    return result;
  }

  /// Detects table blocks within [rawGrid].
  ///
  /// Returns a list of [DetectedTableBlock], ordered primarily by row then column.
  /// If the grid is empty or contains no valid data, returns an empty list.
  static List<DetectedTableBlock> detect(
    List<List<dynamic>> rawGrid, {
    String? defaultSheetName,
  }) {
    if (rawGrid.isEmpty) return const [];

    final height = rawGrid.length;
    var width = 0;
    for (final row in rawGrid) {
      if (row.length > width) {
        width = row.length;
      }
    }
    if (width == 0) return const [];

    bool hasContent(int r, int c) {
      if (r < 0 || r >= rawGrid.length) return false;
      final row = rawGrid[r];
      if (c < 0 || c >= row.length) return false;
      final val = row[c];
      if (val == null) return false;
      return val.toString().trim().isNotEmpty;
    }

    // 1. Find overall non-empty envelope
    var globalMinR = -1;
    var globalMaxR = -1;
    var globalMinC = width;
    var globalMaxC = -1;

    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        if (hasContent(r, c)) {
          if (globalMinR == -1) globalMinR = r;
          globalMaxR = r;
          if (c < globalMinC) globalMinC = c;
          if (c > globalMaxC) globalMaxC = c;
        }
      }
    }

    if (globalMinR == -1) return const [];

    final initialBox = _BoundingBox(
      minRow: globalMinR,
      maxRow: globalMaxR,
      minCol: globalMinC,
      maxCol: globalMaxC,
    );

    // 2. Iterative XY-Cut segmentation
    final rawBoxes = _cutIntoBlocks(initialBox, hasContent);

    // 3. Classify boxes into valid tables and small/title blocks
    final tableBoxes = <_BoundingBox>[];
    final smallBoxes = <_BoundingBox>[];

    for (final box in rawBoxes) {
      var contentCount = 0;
      for (var r = box.minRow; r <= box.maxRow; r++) {
        for (var c = box.minCol; c <= box.maxCol; c++) {
          if (hasContent(r, c)) contentCount++;
        }
      }

      final isTable =
          (box.height >= 2 && box.width >= 2 && contentCount >= 2) ||
              (box.height >= 3 && box.width >= 1 && contentCount >= 3);

      if (isTable) {
        tableBoxes.add(box);
      } else if (contentCount > 0) {
        smallBoxes.add(box);
      }
    }

    // If no box satisfied the strict table criteria, but small content exists,
    // fallback to treating the largest small box as a single table.
    if (tableBoxes.isEmpty && smallBoxes.isNotEmpty) {
      smallBoxes
          .sort((a, b) => (b.height * b.width).compareTo(a.height * a.width));
      tableBoxes.add(smallBoxes.removeAt(0));
    }

    // Sort tables in reading order (top-to-bottom, left-to-right)
    tableBoxes.sort((a, b) {
      final rowCmp = a.minRow.compareTo(b.minRow);
      if (rowCmp != 0) return rowCmp;
      return a.minCol.compareTo(b.minCol);
    });

    // 4. Associate isolated title blocks with tables
    final titleByTable = <_BoundingBox, String>{};
    final consumedSmallBoxes = <_BoundingBox>{};

    for (final table in tableBoxes) {
      // Look for a small box directly above this table (within 2 rows above table.minRow)
      _BoundingBox? bestTitleBox;
      var bestDistance = 999;

      for (final small in smallBoxes) {
        if (consumedSmallBoxes.contains(small)) continue;

        final verticalGap = table.minRow - small.maxRow;
        final isAbove = verticalGap >= 1 && verticalGap <= 2;
        final horizontallyAligned =
            small.minCol <= table.maxCol && small.maxCol >= table.minCol - 1;

        if (isAbove && horizontallyAligned) {
          if (verticalGap < bestDistance) {
            bestDistance = verticalGap;
            bestTitleBox = small;
          }
        }
      }

      if (bestTitleBox != null) {
        consumedSmallBoxes.add(bestTitleBox);
        final titleParts = <String>[];
        for (var r = bestTitleBox.minRow; r <= bestTitleBox.maxRow; r++) {
          for (var c = bestTitleBox.minCol; c <= bestTitleBox.maxCol; c++) {
            if (hasContent(r, c)) {
              titleParts.add(rawGrid[r][c].toString().trim());
            }
          }
        }
        if (titleParts.isNotEmpty) {
          titleByTable[table] = titleParts.join(' ');
        }
      }
    }

    // 5. Build final DetectedTableBlock list
    final results = <DetectedTableBlock>[];

    for (final box in tableBoxes) {
      var startR = box.minRow;
      final endR = box.maxRow;
      final startC = box.minCol;
      final endC = box.maxCol;
      String? detectedTitle = titleByTable[box];

      // Extract raw sub-matrix
      final subMatrix = <List<dynamic>>[];
      for (var r = startR; r <= endR; r++) {
        final row = <dynamic>[];
        final sourceRow = r < rawGrid.length ? rawGrid[r] : const <dynamic>[];
        for (var c = startC; c <= endC; c++) {
          if (c < sourceRow.length && sourceRow[c] != null) {
            row.add(sourceRow[c]);
          } else {
            row.add('');
          }
        }
        subMatrix.add(row);
      }

      // Check for merged banner title on the first row if no separate title was detected:
      // If row 0 has exactly 1 non-empty cell and row 1 has >= 2 non-empty cells,
      // the first row is a banner title across the table.
      if (detectedTitle == null &&
          subMatrix.length >= 3 &&
          (endC - startC + 1) >= 2) {
        final firstRowNonEmpty =
            subMatrix[0].where((c) => c.toString().trim().isNotEmpty).toList();
        final secondRowNonEmpty =
            subMatrix[1].where((c) => c.toString().trim().isNotEmpty).toList();

        if (firstRowNonEmpty.length == 1 && secondRowNonEmpty.length >= 2) {
          detectedTitle = firstRowNonEmpty.first.toString().trim();
          subMatrix.removeAt(0);
          startR += 1;
        }
      }

      if (subMatrix.isEmpty) continue;

      results.add(DetectedTableBlock(
        detectedTitle: detectedTitle,
        startRow: startR,
        startCol: startC,
        endRow: endR,
        endCol: endC,
        rows: subMatrix,
      ));
    }

    return results;
  }

  /// Recursively cuts a region along empty rows or columns.
  /// Splits [root] into contiguous blocks along empty row/column gutters.
  ///
  /// Uses an explicit worklist rather than recursion: a sheet whose rows
  /// alternate content and blanks — a common export shape — produces one split
  /// per blank row, which as a recursion was one stack frame per blank row and
  /// overflowed the stack on a large sheet. [maxBlocks] additionally bounds the
  /// work on a pathological grid: once the budget is spent the boxes still
  /// pending are emitted whole instead of being split further.
  static List<_BoundingBox> _cutIntoBlocks(
    _BoundingBox root,
    bool Function(int, int) hasContent, {
    int maxBlocks = maxDetectedBlocks,
  }) {
    final blocks = <_BoundingBox>[];
    final pending = <_BoundingBox>[root];

    while (pending.isNotEmpty) {
      // Budget spent: flush what is left as coarse blocks, never drop content.
      if (blocks.length + pending.length >= maxBlocks) {
        for (final box in pending.reversed) {
          final trimmed = _trim(box, hasContent);
          if (trimmed != null) blocks.add(trimmed);
        }
        break;
      }

      final trimmed = _trim(pending.removeLast(), hasContent);
      if (trimmed == null) continue;

      final cut = _findWidestGutter(trimmed, hasContent);
      if (cut == null) {
        blocks.add(trimmed);
        continue;
      }

      // Pushed second half first, so the first half is processed first and the
      // block order stays the sheet's reading order.
      if (cut.isHorizontal) {
        pending.add(_BoundingBox(
          minRow: cut.end + 1,
          maxRow: trimmed.maxRow,
          minCol: trimmed.minCol,
          maxCol: trimmed.maxCol,
        ));
        pending.add(_BoundingBox(
          minRow: trimmed.minRow,
          maxRow: cut.start - 1,
          minCol: trimmed.minCol,
          maxCol: trimmed.maxCol,
        ));
      } else {
        pending.add(_BoundingBox(
          minRow: trimmed.minRow,
          maxRow: trimmed.maxRow,
          minCol: cut.end + 1,
          maxCol: trimmed.maxCol,
        ));
        pending.add(_BoundingBox(
          minRow: trimmed.minRow,
          maxRow: trimmed.maxRow,
          minCol: trimmed.minCol,
          maxCol: cut.start - 1,
        ));
      }
    }

    return blocks;
  }

  /// Shrinks [box] to its non-empty envelope, or null when it holds no content.
  static _BoundingBox? _trim(
    _BoundingBox box,
    bool Function(int, int) hasContent,
  ) {
    var minR = box.minRow;
    var maxR = box.maxRow;
    var minC = box.minCol;
    var maxC = box.maxCol;

    if (minR > maxR || minC > maxC) return null;

    bool rowHasContent(int r, int fromC, int toC) {
      for (var c = fromC; c <= toC; c++) {
        if (hasContent(r, c)) return true;
      }
      return false;
    }

    bool colHasContent(int c, int fromR, int toR) {
      for (var r = fromR; r <= toR; r++) {
        if (hasContent(r, c)) return true;
      }
      return false;
    }

    while (minR <= maxR && !rowHasContent(minR, minC, maxC)) {
      minR++;
    }
    while (maxR >= minR && !rowHasContent(maxR, minC, maxC)) {
      maxR--;
    }
    while (minC <= maxC && !colHasContent(minC, minR, maxR)) {
      minC++;
    }
    while (maxC >= minC && !colHasContent(maxC, minR, maxR)) {
      maxC--;
    }

    if (minR > maxR || minC > maxC) return null;

    return _BoundingBox(
      minRow: minR,
      maxRow: maxR,
      minCol: minC,
      maxCol: maxC,
    );
  }

  /// Finds the widest empty gutter inside [box], preferring a horizontal one on
  /// a tie, or null when the box is a single contiguous block.
  static _Gutter? _findWidestGutter(
    _BoundingBox box,
    bool Function(int, int) hasContent,
  ) {
    bool rowHasContent(int r) {
      for (var c = box.minCol; c <= box.maxCol; c++) {
        if (hasContent(r, c)) return true;
      }
      return false;
    }

    bool colHasContent(int c) {
      for (var r = box.minRow; r <= box.maxRow; r++) {
        if (hasContent(r, c)) return true;
      }
      return false;
    }

    final horizontal = _widestGap(
      from: box.minRow + 1,
      to: box.maxRow,
      hasContentAt: rowHasContent,
    );
    final vertical = _widestGap(
      from: box.minCol + 1,
      to: box.maxCol,
      hasContentAt: colHasContent,
    );

    if (horizontal != null &&
        (vertical == null || horizontal.size >= vertical.size)) {
      return _Gutter(
        isHorizontal: true,
        start: horizontal.start,
        end: horizontal.end,
      );
    }
    if (vertical != null) {
      return _Gutter(
        isHorizontal: false,
        start: vertical.start,
        end: vertical.end,
      );
    }
    return null;
  }

  /// Widest run of empty lines in `[from, to)`, exclusive of the box edges.
  static _Gap? _widestGap({
    required int from,
    required int to,
    required bool Function(int) hasContentAt,
  }) {
    _Gap? best;
    var runStart = -1;

    for (var i = from; i < to; i++) {
      if (!hasContentAt(i)) {
        if (runStart == -1) runStart = i;
        continue;
      }
      if (runStart != -1) {
        final gap = _Gap(start: runStart, end: i - 1);
        if (best == null || gap.size > best.size) best = gap;
        runStart = -1;
      }
    }
    if (runStart != -1) {
      final gap = _Gap(start: runStart, end: to - 1);
      if (best == null || gap.size > best.size) best = gap;
    }

    return best;
  }
}
