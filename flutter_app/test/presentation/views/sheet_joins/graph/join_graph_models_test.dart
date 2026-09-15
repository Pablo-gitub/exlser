import 'package:flutter_test/flutter_test.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_models.dart';

DatasetColumn _col(int id, int tableId, String name, ColumnType type) {
  return DatasetColumn(
    id: id,
    datasetTableId: tableId,
    originalName: name,
    dbName: name.toLowerCase(),
    declaredType: type,
    inferredType: type,
    nullable: true,
  );
}

MultiSheetSheetInfo _sheet(int id, String name, List<String> colNames) {
  return MultiSheetSheetInfo(
    table: DatasetTable(
      id: id,
      datasetId: 1,
      sheetNameOriginal: name,
      sqlTableName: 'tbl_$id',
      rowCount: 10,
      colCount: colNames.length,
    ),
    columns: [
      for (var i = 0; i < colNames.length; i++)
        _col(id * 100 + i, id, colNames[i], ColumnType.text),
    ],
  );
}

void main() {
  group('JoinGraphLayoutBuilder', () {
    test('returns fallback empty canvas when selectedSheets is empty', () {
      final graph = JoinGraphLayoutBuilder.build(
        selectedSheets: [],
        baseTableId: null,
        joins: [],
        relationships: {},
        suggestions: [],
      );

      expect(graph.tables, isEmpty);
      expect(graph.connections, isEmpty);
      expect(graph.canvasSize.width, 400.0);
      expect(graph.canvasSize.height, 300.0);
    });

    test('builds side-by-side layout for 2 sheets', () {
      final sheetA = _sheet(1, 'Customers', ['id', 'name']);
      final sheetB = _sheet(2, 'Orders', ['id', 'customer_id', 'amount']);

      final graph = JoinGraphLayoutBuilder.build(
        selectedSheets: [sheetA, sheetB],
        baseTableId: 1,
        joins: [],
        relationships: {},
        suggestions: [],
      );

      expect(graph.tables.length, 2);
      final t1 = graph.tables.firstWhere((t) => t.tableId == 1);
      final t2 = graph.tables.firstWhere((t) => t.tableId == 2);

      expect(t1.isBase, isTrue);
      expect(t2.isBase, isFalse);

      // t1 should be at canvasPadding (50, 50)
      expect(t1.position.dx, JoinGraphLayoutBuilder.canvasPadding);
      expect(t1.position.dy, JoinGraphLayoutBuilder.canvasPadding);

      // t2 should be to the right of t1
      expect(
        t2.position.dx,
        JoinGraphLayoutBuilder.canvasPadding +
            JoinGraphLayoutBuilder.cardWidth +
            JoinGraphLayoutBuilder.columnHorizontalSpacing,
      );

      // Verify columns have left and right anchors
      expect(t1.columns.length, 2);
      final col0 = t1.columns.first;
      expect(col0.leftAnchor.dx, t1.position.dx);
      expect(col0.rightAnchor.dx,
          t1.position.dx + JoinGraphLayoutBuilder.cardWidth);
      expect(col0.leftAnchor.dy, col0.rightAnchor.dy);
    });

    test('builds stacked column layout for 3+ sheets with base on column 0',
        () {
      final s1 = _sheet(1, 'Base', ['id']);
      final s2 = _sheet(2, 'Details', ['id', 'base_id']);
      final s3 = _sheet(3, 'Logs', ['id', 'base_id']);

      final graph = JoinGraphLayoutBuilder.build(
        selectedSheets: [s1, s2, s3],
        baseTableId: 1,
        joins: [],
        relationships: {},
        suggestions: [],
      );

      expect(graph.tables.length, 3);
      final base = graph.tables.firstWhere((t) => t.tableId == 1);
      final t2 = graph.tables.firstWhere((t) => t.tableId == 2);
      final t3 = graph.tables.firstWhere((t) => t.tableId == 3);

      expect(base.position.dx, JoinGraphLayoutBuilder.canvasPadding);
      // t2 and t3 should be at column 1 X position
      final col1X = JoinGraphLayoutBuilder.canvasPadding +
          JoinGraphLayoutBuilder.cardWidth +
          JoinGraphLayoutBuilder.columnHorizontalSpacing;
      expect(t2.position.dx, col1X);
      expect(t3.position.dx, col1X);
      // t3 should be placed vertically below t2
      expect(t3.position.dy, greaterThan(t2.position.dy));
    });

    test(
        'calculates connection endpoints and bezier midpoints for confirmed joins',
        () {
      final sheetA = _sheet(1, 'Customers', ['id', 'name']);
      final sheetB = _sheet(2, 'Orders', ['id', 'cust_id', 'total']);

      const rel = DatasetRelationship(
        id: 10,
        datasetId: 1,
        endpointATableId: 1,
        endpointAColumnDbName: 'id',
        endpointBTableId: 2,
        endpointBColumnDbName: 'cust_id',
        relationshipConfidence: 0.95,
      );

      final graph = JoinGraphLayoutBuilder.build(
        selectedSheets: [sheetA, sheetB],
        baseTableId: 1,
        joins: [
          MultiSheetJoin(
            relationshipId: 10,
            joinType: SheetJoinType.left,
          ),
        ],
        relationships: {10: rel},
        suggestions: [],
      );

      expect(graph.connections.length, 1);
      final conn = graph.connections.first;
      expect(conn.relationshipId, 10);
      expect(conn.joinType, SheetJoinType.left);
      expect(conn.isSuggestion, isFalse);
      expect(conn.fromTableId, 1);
      expect(conn.fromColumnDbName, 'id');
      expect(conn.toTableId, 2);
      expect(conn.toColumnDbName, 'cust_id');

      // Left to right: start should be on right anchor of table 1, end on left anchor of table 2
      expect(conn.startPoint.dx, lessThan(conn.endPoint.dx));
      expect(conn.midPoint.dx, greaterThan(conn.startPoint.dx));
      expect(conn.midPoint.dx, lessThan(conn.endPoint.dx));

      // Connected column flag
      final custIdCol = graph.tables
          .firstWhere((t) => t.tableId == 1)
          .columns
          .firstWhere((c) => c.columnDbName == 'id');
      expect(custIdCol.isConnected, isTrue);
    });

    test('includes unconfirmed suggestions as suggestion connections', () {
      final sheetA = _sheet(1, 'Customers', ['id']);
      final sheetB = _sheet(2, 'Orders', ['cust_id']);

      const suggestion = SheetRelationshipSuggestion(
        relationship: SheetJoinRelationship(
          leftTableId: 1,
          leftColumnDbName: 'id',
          rightTableId: 2,
          rightColumnDbName: 'cust_id',
        ),
        score: 0.9,
        confidence: SuggestionConfidence.high,
        reasons: [RelationshipReason.nameMatch],
      );

      final graph = JoinGraphLayoutBuilder.build(
        selectedSheets: [sheetA, sheetB],
        baseTableId: 1,
        joins: [],
        relationships: {},
        suggestions: [suggestion],
      );

      expect(graph.connections.length, 1);
      final conn = graph.connections.first;
      expect(conn.isSuggestion, isTrue);
      expect(conn.suggestion, suggestion);
      expect(conn.relationshipId, isNull);
    });

    test('maintains stable table positions when orderBaseTableFirst is false',
        () {
      final s1 = _sheet(1, 'Customers', ['id']);
      final s2 = _sheet(2, 'Orders', ['id', 'cust_id']);
      final s3 = _sheet(3, 'Products', ['id']);

      final graph1 = JoinGraphLayoutBuilder.build(
        selectedSheets: [s1, s2, s3],
        baseTableId: 1,
        joins: [],
        relationships: {},
        suggestions: [],
        orderBaseTableFirst: false,
      );

      final graph2 = JoinGraphLayoutBuilder.build(
        selectedSheets: [s1, s2, s3],
        baseTableId: 2,
        joins: [],
        relationships: {},
        suggestions: [],
        orderBaseTableFirst: false,
      );

      // Positions of s1, s2, s3 must be identical between graph1 and graph2
      for (final id in [1, 2, 3]) {
        final pos1 = graph1.tables.firstWhere((t) => t.tableId == id).position;
        final pos2 = graph2.tables.firstWhere((t) => t.tableId == id).position;
        expect(pos1, equals(pos2));
      }

      // But isBase changes appropriately
      expect(graph1.tables.firstWhere((t) => t.tableId == 1).isBase, isTrue);
      expect(graph1.tables.firstWhere((t) => t.tableId == 2).isBase, isFalse);

      expect(graph2.tables.firstWhere((t) => t.tableId == 1).isBase, isFalse);
      expect(graph2.tables.firstWhere((t) => t.tableId == 2).isBase, isTrue);
    });
  });
}
