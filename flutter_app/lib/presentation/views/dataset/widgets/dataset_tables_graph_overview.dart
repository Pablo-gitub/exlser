import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_event.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/router/routes.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_connectors_painter.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_canvas.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_models.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_table_node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum GraphScope { singleSheet, allSheets }

class DatasetTablesGraphOverview extends ConsumerStatefulWidget {
  final Dataset dataset;
  final List<DatasetTable> tables;
  final DatasetTable activeTable;
  final Map<int, List<DatasetColumn>> columnsByTableId;

  const DatasetTablesGraphOverview({
    super.key,
    required this.dataset,
    required this.tables,
    required this.activeTable,
    required this.columnsByTableId,
  });

  @override
  ConsumerState<DatasetTablesGraphOverview> createState() =>
      _DatasetTablesGraphOverviewState();
}

class _DatasetTablesGraphOverviewState
    extends ConsumerState<DatasetTablesGraphOverview> {
  late final TransformationController _transformationController;
  GraphScope _scope = GraphScope.allSheets;
  bool _isGenerating = false;
  List<SheetRelationshipSuggestion>? _suggestions;
  bool _saved = false;
  bool _isCollapsed = false;

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

  bool get _hasMultipleSheetsWithSubTables {
    final uniqueSheets =
        widget.tables.map((t) => t.effectiveSourceSheetName).toSet();
    return uniqueSheets.length > 1 &&
        uniqueSheets.length < widget.tables.length;
  }

  List<DatasetTable> get _displayedTables {
    if (!_hasMultipleSheetsWithSubTables) {
      return widget.tables;
    }
    if (_scope == GraphScope.singleSheet) {
      final activeSheet = widget.activeTable.effectiveSourceSheetName;
      return widget.tables
          .where((t) => t.effectiveSourceSheetName == activeSheet)
          .toList();
    }
    return widget.tables;
  }

  List<MultiSheetSheetInfo> _buildSheetInfos(List<DatasetTable> tables) {
    return [
      for (final t in tables)
        MultiSheetSheetInfo(
          table: t,
          columns: widget.columnsByTableId[t.id] ?? const [],
        ),
    ];
  }

  Future<void> _generateConnections(
      List<MultiSheetSheetInfo> displayedSheets) async {
    if (displayedSheets.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.datasetJoinsErrorNotEnoughTables.tr()),
          ),
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _saved = false;
    });

    try {
      final service = ref.read(multiSheetAnalysisServiceProvider);
      final suggestions = await service.suggestRelationships(
        sheets: displayedSheets,
        selectedTableIds: displayedSheets.map((s) => s.tableId).toList(),
      );
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _isGenerating = false;
      });
      if (suggestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppStrings.datasetWorkspaceGraphNoConnectionsFound.tr()),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveConnections() async {
    if (_suggestions == null || _suggestions!.isEmpty) return;

    try {
      final service = ref.read(multiSheetAnalysisServiceProvider);
      for (final suggestion in _suggestions!) {
        final r = suggestion.relationship;
        final rel = DatasetRelationship(
          datasetId: widget.dataset.id,
          endpointATableId: r.leftTableId,
          endpointAColumnDbName: r.leftColumnDbName,
          endpointBTableId: r.rightTableId,
          endpointBColumnDbName: r.rightColumnDbName,
          cardinality: suggestion.cardinality,
          relationshipConfidence: suggestion.score,
          cardinalityConfidence: suggestion.cardinalityConfidence,
          sampleSize: suggestion.sampleSize,
          origin: RelationshipOrigin.suggested,
          confirmedAt: DateTime.now(),
        );
        try {
          await service.createRelationship(rel);
        } on DuplicateRelationshipException {
          // Already saved, proceed
        }
      }
      if (mounted) {
        setState(() {
          _saved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.datasetWorkspaceGraphSavedSuccess.tr()),
          ),
        );
      }
    } catch (_) {
      // Ignore save failure
    }
  }

  void _navigateToCombineSheets() {
    context.pushNamed(
      AppRoutes.sheetJoinsName,
      pathParameters: {
        AppRoutes.datasetIdParam: '${widget.dataset.id}',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayed = _displayedTables;
    final displayedSheets = _buildSheetInfos(displayed);

    final graphData = JoinGraphLayoutBuilder.build(
      selectedSheets: displayedSheets,
      baseTableId: widget.activeTable.id,
      joins: const [],
      relationships: const {},
      suggestions: _suggestions ?? const [],
      customPositions: _customPositions,
      orderBaseTableFirst: false,
    );

    return Card(
      key: const ValueKey('dataset_tables_graph_overview_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / Controls Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Title and Scope Toggle
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.datasetWorkspaceGraphTitle.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_hasMultipleSheetsWithSubTables)
                      SegmentedButton<GraphScope>(
                        key: const ValueKey('graph_scope_segmented_button'),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: GraphScope.singleSheet,
                            label: Text(
                              AppStrings.datasetWorkspaceGraphSingleSheet.tr(),
                            ),
                            icon: const Icon(Icons.description_outlined,
                                size: 16),
                          ),
                          ButtonSegment(
                            value: GraphScope.allSheets,
                            label: Text(
                                AppStrings.datasetWorkspaceGraphAllSheets.tr()),
                            icon: const Icon(Icons.folder_outlined, size: 16),
                          ),
                        ],
                        selected: {_scope},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _scope = newSelection.first;
                            _suggestions = null;
                            _saved = false;
                            _customPositions.clear();
                            _draggingTableId = null;
                            _dragStartPosition = null;
                          });
                        },
                      ),
                  ],
                ),

                // Action Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_isGenerating) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.datasetWorkspaceGraphGenerating.tr(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        key: const ValueKey('graph_generate_connections_btn'),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          AppStrings.datasetWorkspaceGraphGenerate.tr(),
                        ),
                        onPressed: displayedSheets.length >= 2
                            ? () => _generateConnections(displayedSheets)
                            : null,
                      ),
                    ],
                    if (_suggestions != null && _suggestions!.isNotEmpty) ...[
                      FilledButton.icon(
                        key: const ValueKey('graph_save_connections_btn'),
                        icon: Icon(
                          _saved ? Icons.check_circle : Icons.save_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _saved
                              ? AppStrings.datasetWorkspaceGraphSavedSuccess
                                  .tr()
                              : AppStrings.datasetWorkspaceGraphSave.tr(),
                        ),
                        onPressed: _saved ? null : _saveConnections,
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('graph_edit_connections_btn'),
                        icon: const Icon(Icons.tune, size: 18),
                        label: Text(AppStrings.datasetWorkspaceGraphEdit.tr()),
                        onPressed: _navigateToCombineSheets,
                      ),
                    ],
                    IconButton(
                      key: const ValueKey('graph_collapse_toggle_btn'),
                      icon: Icon(
                        _isCollapsed ? Icons.expand_more : Icons.expand_less,
                      ),
                      tooltip: _isCollapsed
                          ? AppStrings.datasetWorkspaceGraphExpand.tr()
                          : AppStrings.datasetWorkspaceGraphCollapse.tr(),
                      onPressed: () {
                        setState(() {
                          _isCollapsed = !_isCollapsed;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!_isCollapsed) ...[
            const Divider(height: 1),
            // Canvas View
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  // Dot Grid Background
                  Positioned.fill(
                    child: JoinGridBackground(colorScheme: colorScheme),
                  ),

                  // Interactive Zoom/Pan Canvas
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.3,
                      maxScale: 2.2,
                      boundaryMargin: const EdgeInsets.all(250),
                      constrained: false,
                      child: SizedBox(
                        width: graphData.canvasSize.width,
                        height: graphData.canvasSize.height,
                        child: Stack(
                          children: [
                            // Connectors Painter
                            Positioned.fill(
                              child: CustomPaint(
                                painter: JoinConnectorsPainter(
                                  connections: graphData.connections,
                                  colorScheme: colorScheme,
                                ),
                              ),
                            ),

                            // Table Node Cards
                            for (final table in graphData.tables)
                              Positioned(
                                left: table.position.dx,
                                top: table.position.dy,
                                child: GestureDetector(
                                  onTap: () {
                                    if (table.tableId !=
                                        widget.activeTable.id) {
                                      context.read<DatasetBloc>().add(
                                            ChangeSheetEvent(table.tableId),
                                          );
                                    }
                                  },
                                  onLongPressStart: (details) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _draggingTableId = table.tableId;
                                      _dragStartPosition = table.position;
                                    });
                                  },
                                  onLongPressMoveUpdate: (details) {
                                    if (_dragStartPosition == null) return;
                                    final scale = _transformationController
                                        .value
                                        .getMaxScaleOnAxis();
                                    final safeScale = scale <= 0 ? 1.0 : scale;
                                    final newX = math.max(
                                      10.0,
                                      _dragStartPosition!.dx +
                                          (details.offsetFromOrigin.dx /
                                              safeScale),
                                    );
                                    final newY = math.max(
                                      10.0,
                                      _dragStartPosition!.dy +
                                          (details.offsetFromOrigin.dy /
                                              safeScale),
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
                                    isDragging:
                                        _draggingTableId == table.tableId,
                                    onTap: () {
                                      if (table.tableId !=
                                          widget.activeTable.id) {
                                        context.read<DatasetBloc>().add(
                                              ChangeSheetEvent(table.tableId),
                                            );
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

                  // Zoom Controls (Top Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const ValueKey('graph_overview_zoom_in_btn'),
                            icon: const Icon(Icons.add, size: 18),
                            tooltip: AppStrings.datasetJoinsGraphZoomIn.tr(),
                            onPressed: () => _zoom(1.2),
                          ),
                          IconButton(
                            key: const ValueKey('graph_overview_zoom_out_btn'),
                            icon: const Icon(Icons.remove, size: 18),
                            tooltip: AppStrings.datasetJoinsGraphZoomOut.tr(),
                            onPressed: () => _zoom(0.8),
                          ),
                          IconButton(
                            key:
                                const ValueKey('graph_overview_zoom_reset_btn'),
                            icon: const Icon(Icons.restart_alt, size: 18),
                            tooltip: AppStrings.datasetJoinsGraphReset.tr(),
                            onPressed: _resetZoom,
                          ),
                          if (_customPositions.isNotEmpty) ...[
                            const SizedBox(
                              height: 16,
                              child: VerticalDivider(width: 1),
                            ),
                            IconButton(
                              key: const ValueKey(
                                  'graph_overview_reset_layout_btn'),
                              icon: const Icon(Icons.auto_fix_high_outlined,
                                  size: 18),
                              tooltip: AppStrings
                                  .datasetWorkspaceGraphResetLayout
                                  .tr(),
                              onPressed: _resetPositions,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
