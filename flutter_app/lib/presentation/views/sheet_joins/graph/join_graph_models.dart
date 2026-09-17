import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';

class GraphColumnLayout {
  final int columnId;
  final String columnDbName;
  final String columnName;
  final ColumnType columnType;
  final bool isConnected;
  final Offset leftAnchor;
  final Offset rightAnchor;

  const GraphColumnLayout({
    required this.columnId,
    required this.columnDbName,
    required this.columnName,
    required this.columnType,
    required this.isConnected,
    required this.leftAnchor,
    required this.rightAnchor,
  });
}

class GraphTableLayout {
  final int tableId;
  final String tableName;
  final bool isBase;
  final int rowCount;
  final Offset position;
  final Size size;
  final List<GraphColumnLayout> columns;

  /// Columns the card does not render because of a visible-column cap.
  final int hiddenColumnCount;

  const GraphTableLayout({
    required this.tableId,
    required this.tableName,
    required this.isBase,
    required this.rowCount,
    required this.position,
    required this.size,
    required this.columns,
    this.hiddenColumnCount = 0,
  });

  Rect get rect => position & size;
}

class GraphConnectionLayout {
  final int? relationshipId;
  final int fromTableId;
  final String fromColumnDbName;
  final int toTableId;
  final String toColumnDbName;
  final SheetJoinType joinType;
  final bool isSuggestion;
  final SheetRelationshipSuggestion? suggestion;
  final Offset startPoint;
  final Offset endPoint;
  final Offset midPoint;
  final Offset controlPoint1;
  final Offset controlPoint2;

  const GraphConnectionLayout({
    this.relationshipId,
    required this.fromTableId,
    required this.fromColumnDbName,
    required this.toTableId,
    required this.toColumnDbName,
    required this.joinType,
    required this.isSuggestion,
    this.suggestion,
    required this.startPoint,
    required this.endPoint,
    required this.midPoint,
    required this.controlPoint1,
    required this.controlPoint2,
  });
}

class JoinGraphData {
  final Size canvasSize;
  final List<GraphTableLayout> tables;
  final List<GraphConnectionLayout> connections;

  const JoinGraphData({
    required this.canvasSize,
    required this.tables,
    required this.connections,
  });
}

/// Columns a card renders, plus how many were left out by the cap.
class _VisibleColumns {
  final List<DatasetColumn> columns;
  final int hiddenCount;

  const _VisibleColumns({
    required this.columns,
    required this.hiddenCount,
  });
}

class JoinGraphLayoutBuilder {
  static const double cardWidth = 230.0;
  static const double headerHeight = 56.0;
  static const double columnItemHeight = 34.0;
  static const double cardFooterPadding = 8.0;

  /// Height of the "+N more columns" row shown when a card is capped.
  static const double moreColumnsRowHeight = 26.0;
  static const double columnHorizontalSpacing = 220.0;
  static const double rowVerticalSpacing = 80.0;
  static const double canvasPadding = 60.0;

  static JoinGraphData build({
    required List<MultiSheetSheetInfo> selectedSheets,
    required int? baseTableId,
    required List<MultiSheetJoin> joins,
    required Map<int, DatasetRelationship> relationships,
    required List<SheetRelationshipSuggestion> suggestions,
    Map<int, Offset>? customPositions,
    bool orderBaseTableFirst = true,
    int? maxVisibleColumns,
  }) {
    if (selectedSheets.isEmpty) {
      return const JoinGraphData(
        canvasSize: Size(400, 300),
        tables: [],
        connections: [],
      );
    }

    // Identify all connected column keys (tableId.columnDbName)
    final connectedColKeys = <String>{};
    for (final join in joins) {
      final rel = relationships[join.relationshipId];
      if (rel != null) {
        connectedColKeys
            .add('${rel.endpointATableId}.${rel.endpointAColumnDbName}');
        connectedColKeys
            .add('${rel.endpointBTableId}.${rel.endpointBColumnDbName}');
      }
    }

    // Columns taking part in a connection must stay visible even when a card is
    // capped, otherwise a connector would point at a row that is not rendered.
    final priorityColKeys = <String>{...connectedColKeys};
    for (final suggestion in suggestions) {
      final edge = suggestion.relationship;
      priorityColKeys.add('${edge.leftTableId}.${edge.leftColumnDbName}');
      priorityColKeys.add('${edge.rightTableId}.${edge.rightColumnDbName}');
    }

    // Order sheets: base table first if requested, otherwise keep natural/stable order
    final sortedSheets = List<MultiSheetSheetInfo>.from(selectedSheets);
    if (orderBaseTableFirst && baseTableId != null) {
      sortedSheets.sort((a, b) {
        if (a.tableId == baseTableId) return -1;
        if (b.tableId == baseTableId) return 1;
        return a.label.compareTo(b.label);
      });
    }

    final visibleColumnsBySheet = <int, _VisibleColumns>{
      for (final sheet in sortedSheets)
        sheet.tableId: _selectVisibleColumns(
          tableId: sheet.tableId,
          columns: sheet.columns,
          priorityKeys: priorityColKeys,
          maxVisibleColumns: maxVisibleColumns,
        ),
    };

    final tableLayouts = <int, GraphTableLayout>{};
    double maxCanvasX = 0;
    double maxCanvasY = 0;

    if (sortedSheets.length <= 2) {
      // Side-by-side layout
      for (var i = 0; i < sortedSheets.length; i++) {
        final info = sortedSheets[i];
        final autoPosX =
            canvasPadding + i * (cardWidth + columnHorizontalSpacing);
        final autoPosY = canvasPadding;
        final posX = customPositions?[info.tableId]?.dx ?? autoPosX;
        final posY = customPositions?[info.tableId]?.dy ?? autoPosY;
        final visible = visibleColumnsBySheet[info.tableId]!;
        final cardH = _cardHeight(visible);

        final cols = _buildColumnsLayout(
          tableId: info.tableId,
          columns: visible.columns,
          connectedKeys: connectedColKeys,
          tablePos: Offset(posX, posY),
        );

        final layout = GraphTableLayout(
          tableId: info.tableId,
          tableName: info.label,
          isBase: info.tableId == baseTableId,
          rowCount: info.table.rowCount,
          position: Offset(posX, posY),
          size: Size(cardWidth, cardH),
          columns: cols,
          hiddenColumnCount: visible.hiddenCount,
        );
        tableLayouts[info.tableId] = layout;
        maxCanvasX = math.max(maxCanvasX, posX + cardWidth);
        maxCanvasY = math.max(maxCanvasY, posY + cardH);
      }
    } else {
      // Column layout: Base table on column 0, remaining tables stacked on column 1 (or columns 1 & 2)
      final col0X = canvasPadding;
      final col1X = canvasPadding + cardWidth + columnHorizontalSpacing;
      final col2X = canvasPadding + (cardWidth + columnHorizontalSpacing) * 2;

      // Base sheet on col0
      final baseSheet = sortedSheets.first;
      final baseVisible = visibleColumnsBySheet[baseSheet.tableId]!;
      final baseH = _cardHeight(baseVisible);
      final basePosX = customPositions?[baseSheet.tableId]?.dx ?? col0X;
      final basePosY = customPositions?[baseSheet.tableId]?.dy ?? canvasPadding;
      tableLayouts[baseSheet.tableId] = GraphTableLayout(
        tableId: baseSheet.tableId,
        tableName: baseSheet.label,
        isBase: baseSheet.tableId == baseTableId,
        rowCount: baseSheet.table.rowCount,
        position: Offset(basePosX, basePosY),
        size: Size(cardWidth, baseH),
        columns: _buildColumnsLayout(
          tableId: baseSheet.tableId,
          columns: baseVisible.columns,
          connectedKeys: connectedColKeys,
          tablePos: Offset(basePosX, basePosY),
        ),
        hiddenColumnCount: baseVisible.hiddenCount,
      );
      maxCanvasX = math.max(maxCanvasX, basePosX + cardWidth);
      maxCanvasY = math.max(maxCanvasY, basePosY + baseH);

      // Other sheets stacked across column 1 and column 2 if >= 3 extra sheets
      final otherSheets = sortedSheets.skip(1).toList();
      double currentYCol1 = canvasPadding;
      double currentYCol2 = canvasPadding;

      for (var i = 0; i < otherSheets.length; i++) {
        final sheet = otherSheets[i];
        final sheetVisible = visibleColumnsBySheet[sheet.tableId]!;
        final sheetH = _cardHeight(sheetVisible);

        final useCol2 =
            otherSheets.length >= 3 && i >= (otherSheets.length / 2).ceil();
        final autoPosX = useCol2 ? col2X : col1X;
        final autoPosY = useCol2 ? currentYCol2 : currentYCol1;
        final posX = customPositions?[sheet.tableId]?.dx ?? autoPosX;
        final posY = customPositions?[sheet.tableId]?.dy ?? autoPosY;

        tableLayouts[sheet.tableId] = GraphTableLayout(
          tableId: sheet.tableId,
          tableName: sheet.label,
          isBase: sheet.tableId == baseTableId,
          rowCount: sheet.table.rowCount,
          position: Offset(posX, posY),
          size: Size(cardWidth, sheetH),
          columns: _buildColumnsLayout(
            tableId: sheet.tableId,
            columns: sheetVisible.columns,
            connectedKeys: connectedColKeys,
            tablePos: Offset(posX, posY),
          ),
          hiddenColumnCount: sheetVisible.hiddenCount,
        );

        if (useCol2) {
          currentYCol2 += sheetH + rowVerticalSpacing;
        } else {
          currentYCol1 += sheetH + rowVerticalSpacing;
        }

        maxCanvasX = math.max(maxCanvasX, posX + cardWidth);
        maxCanvasY = math.max(maxCanvasY, posY + sheetH);
      }
    }

    final connections = <GraphConnectionLayout>[];

    // 1. Confirmed joins
    for (final join in joins) {
      final rel = relationships[join.relationshipId];
      if (rel == null) continue;

      final fromTable = tableLayouts[rel.endpointATableId];
      final toTable = tableLayouts[rel.endpointBTableId];
      if (fromTable == null || toTable == null) continue;

      final fromCol = _columnOrNull(fromTable, rel.endpointAColumnDbName);
      final toCol = _columnOrNull(toTable, rel.endpointBColumnDbName);
      // A column the layout does not know about (renamed, hidden or dropped)
      // would otherwise be anchored to the first one, drawing a connector the
      // user never created.
      if (fromCol == null || toCol == null) continue;

      final connection = _calculateConnection(
        relationshipId: join.relationshipId,
        fromTable: fromTable,
        toTable: toTable,
        fromCol: fromCol,
        toCol: toCol,
        joinType: join.joinType,
        isSuggestion: false,
      );
      connections.add(connection);
    }

    // 2. Unconfirmed suggestions
    final existingPairs = <String>{};
    for (final c in connections) {
      existingPairs.add(
          '${c.fromTableId}.${c.fromColumnDbName}=${c.toTableId}.${c.toColumnDbName}');
      existingPairs.add(
          '${c.toTableId}.${c.toColumnDbName}=${c.fromTableId}.${c.fromColumnDbName}');
    }

    for (final suggestion in suggestions) {
      final edge = suggestion.relationship;
      final fromTable = tableLayouts[edge.leftTableId];
      final toTable = tableLayouts[edge.rightTableId];
      if (fromTable == null || toTable == null) continue;

      final pairKey =
          '${edge.leftTableId}.${edge.leftColumnDbName}=${edge.rightTableId}.${edge.rightColumnDbName}';
      if (existingPairs.contains(pairKey)) continue;

      final fromCol = _columnOrNull(fromTable, edge.leftColumnDbName);
      final toCol = _columnOrNull(toTable, edge.rightColumnDbName);
      if (fromCol == null || toCol == null) continue;

      final connection = _calculateConnection(
        relationshipId: null,
        fromTable: fromTable,
        toTable: toTable,
        fromCol: fromCol,
        toCol: toCol,
        joinType: SheetJoinType.inner,
        isSuggestion: true,
        suggestion: suggestion,
      );
      connections.add(connection);
      existingPairs.add(pairKey);
    }

    final totalW = math.max(650.0, maxCanvasX + canvasPadding);
    final totalH = math.max(450.0, maxCanvasY + canvasPadding);

    return JoinGraphData(
      canvasSize: Size(totalW, totalH),
      tables: tableLayouts.values.toList(),
      connections: connections,
    );
  }

  static double _cardHeight(_VisibleColumns visible) {
    return headerHeight +
        (visible.columns.length * columnItemHeight) +
        (visible.hiddenCount > 0 ? moreColumnsRowHeight : 0) +
        cardFooterPadding;
  }

  /// Keeps a card readable inside a small canvas: at most [maxVisibleColumns]
  /// rows, always including the columns involved in a connection, in their
  /// original order. A null cap keeps every column.
  static _VisibleColumns _selectVisibleColumns({
    required int tableId,
    required List<DatasetColumn> columns,
    required Set<String> priorityKeys,
    required int? maxVisibleColumns,
  }) {
    if (maxVisibleColumns == null ||
        maxVisibleColumns <= 0 ||
        columns.length <= maxVisibleColumns) {
      return _VisibleColumns(columns: columns, hiddenCount: 0);
    }

    final kept = <DatasetColumn>[];
    final connected = <DatasetColumn>[];
    for (final column in columns) {
      if (priorityKeys.contains('$tableId.${column.dbName}')) {
        connected.add(column);
      }
    }

    // Connected columns first claim their slots, then the remaining ones fill
    // the cap; the result is re-ordered to match the sheet's column order.
    final keptIds = <int>{for (final column in connected) column.id};
    for (final column in columns) {
      if (keptIds.length >= maxVisibleColumns) break;
      keptIds.add(column.id);
    }
    for (final column in columns) {
      if (keptIds.contains(column.id)) kept.add(column);
    }

    return _VisibleColumns(
      columns: kept,
      hiddenCount: columns.length - kept.length,
    );
  }

  /// Returns the column with [dbName] inside [table], or null when the layout
  /// does not contain it.
  static GraphColumnLayout? _columnOrNull(
    GraphTableLayout table,
    String dbName,
  ) {
    for (final column in table.columns) {
      if (column.columnDbName == dbName) return column;
    }
    return null;
  }

  static List<GraphColumnLayout> _buildColumnsLayout({
    required int tableId,
    required List<DatasetColumn> columns,
    required Set<String> connectedKeys,
    required Offset tablePos,
  }) {
    final list = <GraphColumnLayout>[];
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      final colCenterY = tablePos.dy +
          headerHeight +
          (i * columnItemHeight) +
          (columnItemHeight / 2);
      final leftAnchor = Offset(tablePos.dx, colCenterY);
      final rightAnchor = Offset(tablePos.dx + cardWidth, colCenterY);

      list.add(
        GraphColumnLayout(
          columnId: col.id,
          columnDbName: col.dbName,
          columnName: col.originalName,
          columnType: col.declaredType,
          isConnected: connectedKeys.contains('$tableId.${col.dbName}'),
          leftAnchor: leftAnchor,
          rightAnchor: rightAnchor,
        ),
      );
    }
    return list;
  }

  static GraphConnectionLayout _calculateConnection({
    required int? relationshipId,
    required GraphTableLayout fromTable,
    required GraphTableLayout toTable,
    required GraphColumnLayout fromCol,
    required GraphColumnLayout toCol,
    required SheetJoinType joinType,
    required bool isSuggestion,
    SheetRelationshipSuggestion? suggestion,
  }) {
    final bool isFromOnLeft = fromTable.position.dx < toTable.position.dx;
    final Offset start =
        isFromOnLeft ? fromCol.rightAnchor : fromCol.leftAnchor;
    final Offset end = isFromOnLeft ? toCol.leftAnchor : toCol.rightAnchor;

    final double dx = (end.dx - start.dx).abs() * 0.5;
    final double dir = isFromOnLeft ? 1.0 : -1.0;

    final Offset cp1 = Offset(start.dx + (dx * dir), start.dy);
    final Offset cp2 = Offset(end.dx - (dx * dir), end.dy);

    final double midX = (0.125 * start.dx) +
        (0.375 * cp1.dx) +
        (0.375 * cp2.dx) +
        (0.125 * end.dx);
    final double midY = (0.125 * start.dy) +
        (0.375 * cp1.dy) +
        (0.375 * cp2.dy) +
        (0.125 * end.dy);

    return GraphConnectionLayout(
      relationshipId: relationshipId,
      fromTableId: fromTable.tableId,
      fromColumnDbName: fromCol.columnDbName,
      toTableId: toTable.tableId,
      toColumnDbName: toCol.columnDbName,
      joinType: joinType,
      isSuggestion: isSuggestion,
      suggestion: suggestion,
      startPoint: start,
      endPoint: end,
      controlPoint1: cp1,
      controlPoint2: cp2,
      midPoint: Offset(midX, midY),
    );
  }
}
