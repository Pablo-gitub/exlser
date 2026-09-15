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

  const GraphTableLayout({
    required this.tableId,
    required this.tableName,
    required this.isBase,
    required this.rowCount,
    required this.position,
    required this.size,
    required this.columns,
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

class JoinGraphLayoutBuilder {
  static const double cardWidth = 230.0;
  static const double headerHeight = 56.0;
  static const double columnItemHeight = 34.0;
  static const double cardFooterPadding = 8.0;
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

    // Order sheets: base table first if requested, otherwise keep natural/stable order
    final sortedSheets = List<MultiSheetSheetInfo>.from(selectedSheets);
    if (orderBaseTableFirst && baseTableId != null) {
      sortedSheets.sort((a, b) {
        if (a.tableId == baseTableId) return -1;
        if (b.tableId == baseTableId) return 1;
        return a.label.compareTo(b.label);
      });
    }

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
        final cardH = headerHeight +
            (info.columns.length * columnItemHeight) +
            cardFooterPadding;

        final cols = _buildColumnsLayout(
          tableId: info.tableId,
          columns: info.columns,
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
      final baseH = headerHeight +
          (baseSheet.columns.length * columnItemHeight) +
          cardFooterPadding;
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
          columns: baseSheet.columns,
          connectedKeys: connectedColKeys,
          tablePos: Offset(basePosX, basePosY),
        ),
      );
      maxCanvasX = math.max(maxCanvasX, basePosX + cardWidth);
      maxCanvasY = math.max(maxCanvasY, basePosY + baseH);

      // Other sheets stacked across column 1 and column 2 if >= 3 extra sheets
      final otherSheets = sortedSheets.skip(1).toList();
      double currentYCol1 = canvasPadding;
      double currentYCol2 = canvasPadding;

      for (var i = 0; i < otherSheets.length; i++) {
        final sheet = otherSheets[i];
        final sheetH = headerHeight +
            (sheet.columns.length * columnItemHeight) +
            cardFooterPadding;

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
            columns: sheet.columns,
            connectedKeys: connectedColKeys,
            tablePos: Offset(posX, posY),
          ),
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

      final fromCol = fromTable.columns.firstWhere(
        (c) => c.columnDbName == rel.endpointAColumnDbName,
        orElse: () => fromTable.columns.first,
      );
      final toCol = toTable.columns.firstWhere(
        (c) => c.columnDbName == rel.endpointBColumnDbName,
        orElse: () => toTable.columns.first,
      );

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

      final fromCol = fromTable.columns.firstWhere(
        (c) => c.columnDbName == edge.leftColumnDbName,
        orElse: () => fromTable.columns.first,
      );
      final toCol = toTable.columns.firstWhere(
        (c) => c.columnDbName == edge.rightColumnDbName,
        orElse: () => toTable.columns.first,
      );

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
