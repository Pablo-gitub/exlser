import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_connection_details_sheet.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_connectors_painter.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_models.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_table_node_card.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';

class JoinGraphCanvas extends StatefulWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const JoinGraphCanvas({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  State<JoinGraphCanvas> createState() => _JoinGraphCanvasState();
}

class _JoinGraphCanvasState extends State<JoinGraphCanvas> {
  late final TransformationController _transformationController;
  int? _selectedRelationshipId;
  final Map<int, Offset> _customPositions = {};
  int? _draggingTableId;
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(factor, factor, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _resetPositions() {
    setState(() {
      _customPositions.clear();
      _draggingTableId = null;
      _dragStartPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedSheets = widget.state.sheets
        .where((s) => widget.state.spec.selectedTableIds.contains(s.tableId))
        .toList();

    if (selectedSheets.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            AppStrings.datasetJoinsErrorNotEnoughTables.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
      );
    }

    final graphData = JoinGraphLayoutBuilder.build(
      selectedSheets: selectedSheets,
      baseTableId: widget.state.spec.baseTableId,
      joins: widget.state.spec.joins,
      relationships: widget.state.relationshipsById,
      suggestions: widget.state.suggestions,
      customPositions: _customPositions,
    );

    final baseTable = selectedSheets.firstWhere(
      (s) => s.tableId == widget.state.spec.baseTableId,
      orElse: () => selectedSheets.first,
    );

    return Container(
      height: 480,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // Background grid pattern / dots
          Positioned.fill(
            child: JoinGridBackground(colorScheme: colorScheme),
          ),

          // Interactive Zoom / Pan Canvas
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.4,
              maxScale: 2.2,
              boundaryMargin: const EdgeInsets.all(300),
              constrained: false,
              child: SizedBox(
                width: graphData.canvasSize.width,
                height: graphData.canvasSize.height,
                child: Stack(
                  children: [
                    // Connectors Layer
                    Positioned.fill(
                      child: CustomPaint(
                        painter: JoinConnectorsPainter(
                          connections: graphData.connections,
                          colorScheme: colorScheme,
                          selectedRelationshipId: _selectedRelationshipId,
                        ),
                      ),
                    ),

                    // Midpoint Badges Layer
                    for (final conn in graphData.connections)
                      _buildConnectionBadge(
                        context: context,
                        conn: conn,
                        baseTableName: baseTable.label,
                        graphData: graphData,
                      ),

                    // Table Node Cards Layer
                    for (final table in graphData.tables)
                      Positioned(
                        left: table.position.dx,
                        top: table.position.dy,
                        child: GestureDetector(
                          onLongPressStart: (details) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _draggingTableId = table.tableId;
                              _dragStartPosition = table.position;
                            });
                          },
                          onLongPressMoveUpdate: (details) {
                            if (_dragStartPosition == null) return;
                            final scale = _transformationController.value
                                .getMaxScaleOnAxis();
                            final safeScale = scale <= 0 ? 1.0 : scale;
                            final newX = math.max(
                              10.0,
                              _dragStartPosition!.dx +
                                  (details.offsetFromOrigin.dx / safeScale),
                            );
                            final newY = math.max(
                              10.0,
                              _dragStartPosition!.dy +
                                  (details.offsetFromOrigin.dy / safeScale),
                            );
                            setState(() {
                              _customPositions[table.tableId] =
                                  Offset(newX, newY);
                            });
                          },
                          onLongPressEnd: (_) {
                            setState(() {
                              _draggingTableId = null;
                              _dragStartPosition = null;
                            });
                          },
                          child: JoinTableNodeCard(
                            table: table,
                            isDragging: _draggingTableId == table.tableId,
                            onHeaderTap: () {
                              if (!table.isBase) {
                                widget.controller.setBaseTable(table.tableId);
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Zoom Controls Overlay (Top Right)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: colorScheme.surface.withValues(alpha: 0.9),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('graph_zoom_in_btn'),
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: AppStrings.datasetJoinsGraphZoomIn.tr(),
                    onPressed: () => _zoom(1.2),
                  ),
                  const Divider(height: 1),
                  IconButton(
                    key: const ValueKey('graph_zoom_out_btn'),
                    icon: const Icon(Icons.remove, size: 20),
                    tooltip: AppStrings.datasetJoinsGraphZoomOut.tr(),
                    onPressed: () => _zoom(0.8),
                  ),
                  const Divider(height: 1),
                  IconButton(
                    key: const ValueKey('graph_zoom_reset_btn'),
                    icon: const Icon(Icons.center_focus_strong_outlined,
                        size: 18),
                    tooltip: AppStrings.datasetJoinsGraphReset.tr(),
                    onPressed: _resetZoom,
                  ),
                  if (_customPositions.isNotEmpty) ...[
                    const Divider(height: 1),
                    IconButton(
                      key: const ValueKey('graph_reset_layout_btn'),
                      icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                      tooltip: AppStrings.datasetWorkspaceGraphResetLayout.tr(),
                      onPressed: _resetPositions,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Hint chip at bottom left
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 14, color: colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.datasetJoinsGraphTapToEdit.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge({
    required BuildContext context,
    required GraphConnectionLayout conn,
    required String baseTableName,
    required JoinGraphData graphData,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = conn.relationshipId != null &&
        conn.relationshipId == _selectedRelationshipId;

    final fromTable = graphData.tables.firstWhere(
      (t) => t.tableId == conn.fromTableId,
    );
    final toTable = graphData.tables.firstWhere(
      (t) => t.tableId == conn.toTableId,
    );
    final fromCol = fromTable.columns.firstWhere(
      (c) => c.columnDbName == conn.fromColumnDbName,
      orElse: () => fromTable.columns.first,
    );
    final toCol = toTable.columns.firstWhere(
      (c) => c.columnDbName == conn.toColumnDbName,
      orElse: () => toTable.columns.first,
    );

    final String label = conn.isSuggestion
        ? '?'
        : (conn.joinType == SheetJoinType.left ? 'LEFT' : 'INNER');

    return Positioned(
      left: conn.midPoint.dx - 30,
      top: conn.midPoint.dy - 14,
      child: Material(
        color: conn.isSuggestion
            ? colorScheme.tertiaryContainer
            : (isSelected ? colorScheme.primary : colorScheme.primaryContainer),
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                conn.isSuggestion ? colorScheme.tertiary : colorScheme.primary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('join_badge_${conn.relationshipId ?? "suggestion"}'),
          onTap: () {
            setState(() {
              _selectedRelationshipId = conn.relationshipId;
            });

            JoinConnectionDetailsSheet.show(
              context: context,
              fromTableName: fromTable.tableName,
              toTableName: toTable.tableName,
              fromColumnName: fromCol.columnName,
              toColumnName: toCol.columnName,
              baseTableName: baseTableName,
              joinType: conn.joinType,
              isSuggestion: conn.isSuggestion,
              onJoinTypeChanged: (newType) {
                if (conn.relationshipId != null) {
                  widget.controller.setJoinType(conn.relationshipId!, newType);
                }
              },
              onRemove: () {
                if (conn.relationshipId != null) {
                  widget.controller.removeJoin(conn.relationshipId!);
                }
              },
              onConfirmSuggestion: conn.suggestion != null
                  ? () {
                      widget.controller.confirmSuggestion(conn.suggestion!);
                    }
                  : null,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  conn.isSuggestion
                      ? Icons.auto_awesome
                      : (conn.joinType == SheetJoinType.left
                          ? Icons.subdirectory_arrow_right
                          : Icons.compare_arrows),
                  size: 13,
                  color: conn.isSuggestion
                      ? colorScheme.onTertiaryContainer
                      : (isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: conn.isSuggestion
                        ? colorScheme.onTertiaryContainer
                        : (isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onPrimaryContainer),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JoinGridBackground extends StatelessWidget {
  final ColorScheme colorScheme;

  const JoinGridBackground({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: JoinDotGridPainter(
        color: colorScheme.outlineVariant.withValues(alpha: 0.25),
      ),
    );
  }
}

class JoinDotGridPainter extends CustomPainter {
  final Color color;

  const JoinDotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double spacing = 24.0;
    const double radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant JoinDotGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
