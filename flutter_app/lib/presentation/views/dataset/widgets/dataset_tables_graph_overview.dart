import 'dart:math' as math;
import 'package:exlser/core/diagnostics/recovered_error.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
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

  /// Node positions restored from the workspace state, by table id.
  final Map<int, Offset> savedNodePositions;

  /// Rows a card renders before collapsing the rest into a "+N" row. Keeps a
  /// wide sheet from producing a card several times taller than the canvas.
  static const int maxVisibleColumnsPerCard = 8;

  static const double canvasHeight = 320;
  static const double minScale = 0.3;
  static const double maxScale = 2.2;

  const DatasetTablesGraphOverview({
    super.key,
    required this.dataset,
    required this.tables,
    required this.activeTable,
    required this.columnsByTableId,
    this.savedNodePositions = const {},
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
  bool _isSaving = false;
  List<SheetRelationshipSuggestion>? _suggestions;
  List<DatasetRelationship> _relationships = const [];
  bool _isCollapsed = false;

  final GlobalKey _viewportKey = GlobalKey();
  final Map<int, Offset> _customPositions = {};
  int? _draggingTableId;
  int? _hoveredTableId;
  int? _pointerDownTableId;
  Offset _dragOffset = Offset.zero;

  /// Bumped whenever a node position changes, so the memoized layout is
  /// invalidated without comparing the whole map.
  int _positionsRevision = 0;

  JoinGraphData? _cachedGraph;
  int? _cachedGraphKey;

  bool _pendingAutoFit = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _customPositions.addAll(widget.savedNodePositions);
    _normalizePositions();
    _loadRelationships();
  }

  @override
  void didUpdateWidget(DatasetTablesGraphOverview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataset.id != widget.dataset.id) {
      _relationships = const [];
      _suggestions = null;
      _customPositions
        ..clear()
        ..addAll(widget.savedNodePositions);
      _normalizePositions();
      _positionsRevision++;
      _pendingAutoFit = true;
      _loadRelationships();
      return;
    }

    // A layout restored from the workspace state wins only while the user is not
    // dragging, so an incoming state emit cannot yank a node from under the finger.
    if (_draggingTableId == null &&
        !_sameLayout(widget.savedNodePositions, _customPositions)) {
      _customPositions
        ..clear()
        ..addAll(widget.savedNodePositions);
      _normalizePositions();
      _positionsRevision++;
    }

    if (oldWidget.tables.length != widget.tables.length) {
      _pendingAutoFit = true;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  bool _sameLayout(Map<int, Offset> a, Map<int, Offset> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Panning the canvas is disabled only while a gesture owns a node. Hover is
  /// deliberately not part of this: a card removed or rebuilt while hovered
  /// never reports `onExit`, which used to leave the canvas locked for good.
  bool get _isPanEnabled =>
      _draggingTableId == null && _pointerDownTableId == null;

  Future<void> _loadRelationships() async {
    if (widget.tables.length < 2) return;

    try {
      final service = ref.read(multiSheetAnalysisServiceProvider);
      final relationships = await service.loadRelationships(widget.dataset.id);
      if (!mounted) return;
      setState(() {
        _relationships = relationships;
        _pendingAutoFit = true;
      });
    } catch (error, stackTrace) {
      recordRecoveredError(error, stackTrace,
          context: 'DatasetTablesGraphOverview');
      // Connectors are an overlay on a graph that is still usable without them,
      // so a failed read stays quiet instead of interrupting the workspace.
    }
  }

  Offset _toScene(Offset globalPosition) {
    final renderBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final viewportPoint = renderBox.globalToLocal(globalPosition);
      return _transformationController.toScene(viewportPoint);
    }
    return _transformationController.toScene(globalPosition);
  }

  void _zoom(double factor) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(
      DatasetTablesGraphOverview.minScale,
      DatasetTablesGraphOverview.maxScale,
    );
    final effectiveFactor = targetScale / currentScale;
    if ((effectiveFactor - 1.0).abs() < 0.001) return;

    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(
        effectiveFactor, effectiveFactor, effectiveFactor, 1.0);
    _transformationController.value = matrix;
  }

  /// Scales and centres the whole graph inside the viewport. Without it the
  /// canvas opens at scale 1 on content several times taller than its 320px, so
  /// the user sees a slice of one card and has to zoom out by hand.
  void _fitToView() {
    final graph = _cachedGraph;
    final renderBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (graph == null || renderBox == null || !renderBox.hasSize) return;

    final viewport = renderBox.size;
    final canvas = graph.canvasSize;
    if (viewport.isEmpty || canvas.width <= 0 || canvas.height <= 0) return;

    final scale = math
        .min(viewport.width / canvas.width, viewport.height / canvas.height)
        .clamp(DatasetTablesGraphOverview.minScale, 1.0);
    final dx = (viewport.width - canvas.width * scale) / 2;
    final dy = (viewport.height - canvas.height * scale) / 2;

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, scale, 1.0);
  }

  void _resetPositions() {
    setState(() {
      _customPositions.clear();
      _draggingTableId = null;
      _hoveredTableId = null;
      _pointerDownTableId = null;
      _positionsRevision++;
      _pendingAutoFit = true;
    });
    _persistPositions();
  }

  void _normalizePositions() {
    if (_customPositions.isEmpty) return;

    final displayed = _displayedTables;
    final displayedSheets = _buildSheetInfos(displayed);
    final graph = _graphFor(displayedSheets);
    if (graph.tables.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;

    for (final table in graph.tables) {
      final pos = _customPositions[table.tableId] ?? table.position;
      minX = math.min(minX, pos.dx);
      minY = math.min(minY, pos.dy);
    }

    final shiftX = minX < JoinGraphLayoutBuilder.canvasPadding
        ? JoinGraphLayoutBuilder.canvasPadding - minX
        : 0.0;
    final shiftY = minY < JoinGraphLayoutBuilder.canvasPadding
        ? JoinGraphLayoutBuilder.canvasPadding - minY
        : 0.0;

    if (shiftX > 0 || shiftY > 0) {
      for (final table in graph.tables) {
        final currentPos = _customPositions[table.tableId] ?? table.position;
        _customPositions[table.tableId] = Offset(
          currentPos.dx + shiftX,
          currentPos.dy + shiftY,
        );
      }
      _positionsRevision++;

      final matrix = _transformationController.value.clone();
      final scale = matrix.getMaxScaleOnAxis();
      matrix.storage[12] -= shiftX * scale;
      matrix.storage[13] -= shiftY * scale;
      _transformationController.value = matrix;

      setState(() {});
    }
  }

  void _persistPositions() {
    context
        .read<DatasetBloc>()
        .add(UpdateGraphNodePositionsEvent(Map.of(_customPositions)));
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

  /// Saved relationships are rendered through the same path as a join spec: one
  /// synthetic join per stored relationship, so reopening the workspace shows
  /// the connections the user already confirmed.
  (List<MultiSheetJoin>, Map<int, DatasetRelationship>) _savedEdges() {
    final joins = <MultiSheetJoin>[];
    final byId = <int, DatasetRelationship>{};
    for (final relationship in _relationships) {
      final id = relationship.id;
      if (id == null) continue;
      byId[id] = relationship;
      joins.add(MultiSheetJoin(relationshipId: id));
    }
    return (joins, byId);
  }

  /// Rebuilding the layout walks every table, column and connector, so it is
  /// memoized: an unrelated rebuild (a bloc emit, a hover, the collapse toggle)
  /// reuses it, while a real input change invalidates it.
  JoinGraphData _graphFor(List<MultiSheetSheetInfo> displayedSheets) {
    final key = Object.hash(
      identityHashCode(widget.tables),
      identityHashCode(widget.columnsByTableId),
      widget.activeTable.id,
      _scope,
      identityHashCode(_relationships),
      _suggestions == null ? 0 : identityHashCode(_suggestions),
      _positionsRevision,
      displayedSheets.length,
    );

    final cached = _cachedGraph;
    if (cached != null && _cachedGraphKey == key) return cached;

    final (joins, relationshipsById) = _savedEdges();
    final graph = JoinGraphLayoutBuilder.build(
      selectedSheets: displayedSheets,
      baseTableId: widget.activeTable.id,
      joins: joins,
      relationships: relationshipsById,
      suggestions: _suggestions ?? const [],
      customPositions: _customPositions,
      orderBaseTableFirst: false,
      maxVisibleColumns: DatasetTablesGraphOverview.maxVisibleColumnsPerCard,
    );

    _cachedGraph = graph;
    _cachedGraphKey = key;
    return graph;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _generateConnections(
      List<MultiSheetSheetInfo> displayedSheets) async {
    if (displayedSheets.length < 2) {
      _showMessage(AppStrings.datasetJoinsErrorNotEnoughTables.tr());
      return;
    }

    setState(() {
      _isGenerating = true;
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
        _showMessage(AppStrings.datasetWorkspaceGraphNoConnectionsFound.tr());
      }
    } catch (error, stackTrace) {
      recordRecoveredError(error, stackTrace,
          context: 'DatasetTablesGraphOverview');
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      _showMessage(AppStrings.datasetWorkspaceGraphGenerateFailed.tr());
    }
  }

  Future<void> _saveConnections() async {
    final suggestions = _suggestions;
    if (suggestions == null || suggestions.isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final relationships = [
      for (final suggestion in suggestions)
        DatasetRelationship(
          datasetId: widget.dataset.id,
          endpointATableId: suggestion.relationship.leftTableId,
          endpointAColumnDbName: suggestion.relationship.leftColumnDbName,
          endpointBTableId: suggestion.relationship.rightTableId,
          endpointBColumnDbName: suggestion.relationship.rightColumnDbName,
          cardinality: suggestion.cardinality,
          relationshipConfidence: suggestion.score,
          cardinalityConfidence: suggestion.cardinalityConfidence,
          sampleSize: suggestion.sampleSize,
          origin: RelationshipOrigin.suggested,
          confirmedAt: now,
        ),
    ];

    try {
      final service = ref.read(multiSheetAnalysisServiceProvider);
      final result = await service.createRelationships(
        datasetId: widget.dataset.id,
        relationships: relationships,
      );
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        // The suggestions are now part of the graph as confirmed connections.
        if (!result.hasFailures) _suggestions = null;
      });
      await _loadRelationships();
      if (!mounted) return;

      if (result.hasFailures) {
        _showMessage(
          AppStrings.datasetWorkspaceGraphSavePartial.tr(
            namedArgs: {
              'saved': '${result.created.length + result.skipped.length}',
              'total': '${result.requestedCount}',
            },
          ),
        );
      } else {
        _showMessage(AppStrings.datasetWorkspaceGraphSavedSuccess.tr());
      }
    } catch (error, stackTrace) {
      recordRecoveredError(error, stackTrace,
          context: 'DatasetTablesGraphOverview');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showMessage(AppStrings.datasetWorkspaceGraphSaveFailed.tr());
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

    // One node relates to nothing: the canvas only earns its space from two
    // tables up.
    if (widget.tables.length < 2) return const SizedBox.shrink();

    final displayed = _displayedTables;
    final displayedSheets = _buildSheetInfos(displayed);
    final graphData = _graphFor(displayedSheets);
    final canSuggest = displayedSheets.length >= 2;

    if (_pendingAutoFit && !_isCollapsed) {
      _pendingAutoFit = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitToView();
      });
    }

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
                            _customPositions.clear();
                            _draggingTableId = null;
                            _hoveredTableId = null;
                            _pointerDownTableId = null;
                            _positionsRevision++;
                            _pendingAutoFit = true;
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
                        onPressed: canSuggest
                            ? () => _generateConnections(displayedSheets)
                            : null,
                      ),
                    ],
                    if (_suggestions != null && _suggestions!.isNotEmpty)
                      FilledButton.icon(
                        key: const ValueKey('graph_save_connections_btn'),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(AppStrings.datasetWorkspaceGraphSave.tr()),
                        onPressed: _isSaving ? null : _saveConnections,
                      ),
                    // Always reachable: editing the relationships is the point
                    // of the overview, not a follow-up to a generation.
                    if (canSuggest)
                      OutlinedButton.icon(
                        key: const ValueKey('graph_edit_connections_btn'),
                        icon: const Icon(Icons.tune, size: 18),
                        label: Text(AppStrings.datasetWorkspaceGraphEdit.tr()),
                        onPressed: _navigateToCombineSheets,
                      ),
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
                          if (!_isCollapsed) _pendingAutoFit = true;
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
              height: DatasetTablesGraphOverview.canvasHeight,
              child: Stack(
                children: [
                  // Dot Grid Background
                  Positioned.fill(
                    child: JoinGridBackground(colorScheme: colorScheme),
                  ),

                  // Interactive Zoom/Pan Canvas. Scroll-to-zoom and the wheel
                  // isolation from the surrounding page are handled by
                  // InteractiveViewer itself: its own pointer-signal handler
                  // sits deeper in the tree and always wins the resolver.
                  Positioned.fill(
                    child: InteractiveViewer(
                      key: _viewportKey,
                      transformationController: _transformationController,
                      panEnabled: _isPanEnabled,
                      trackpadScrollCausesScale: true,
                      minScale: DatasetTablesGraphOverview.minScale,
                      maxScale: DatasetTablesGraphOverview.maxScale,
                      boundaryMargin: const EdgeInsets.all(2000),
                      constrained: false,
                      child: SizedBox(
                        width: graphData.canvasSize.width,
                        height: graphData.canvasSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
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
                                child: _buildNode(table),
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
                            icon:
                                const Icon(Icons.fit_screen_outlined, size: 18),
                            tooltip:
                                AppStrings.datasetWorkspaceGraphFitToView.tr(),
                            onPressed: _fitToView,
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

  Widget _buildNode(GraphTableLayout table) {
    final isDragging = _draggingTableId == table.tableId;

    return MouseRegion(
      cursor:
          isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      onEnter: (_) {
        if (_hoveredTableId != table.tableId) {
          setState(() => _hoveredTableId = table.tableId);
        }
      },
      onExit: (_) {
        if (_hoveredTableId == table.tableId) {
          setState(() => _hoveredTableId = null);
        }
      },
      child: Listener(
        onPointerDown: (_) {
          if (_pointerDownTableId != table.tableId) {
            setState(() => _pointerDownTableId = table.tableId);
          }
        },
        onPointerUp: (_) {
          if (_pointerDownTableId == table.tableId) {
            setState(() => _pointerDownTableId = null);
          }
        },
        onPointerCancel: (_) {
          if (_pointerDownTableId == table.tableId) {
            setState(() => _pointerDownTableId = null);
          }
        },
        child: GestureDetector(
          onPanStart: (details) {
            HapticFeedback.selectionClick();
            final scenePoint = _toScene(details.globalPosition);
            final currentPos =
                _customPositions[table.tableId] ?? table.position;
            _dragOffset = scenePoint - currentPos;
            setState(() {
              _draggingTableId = table.tableId;
            });
          },
          onPanUpdate: (details) {
            if (_draggingTableId != table.tableId) return;
            final scenePoint = _toScene(details.globalPosition);
            final newPos = scenePoint - _dragOffset;
            if (!newPos.dx.isFinite || !newPos.dy.isFinite) return;
            setState(() {
              _customPositions[table.tableId] = newPos;
              _positionsRevision++;
            });
          },
          onPanEnd: (_) {
            setState(() {
              _draggingTableId = null;
              _pointerDownTableId = null;
            });
            _normalizePositions();
            _persistPositions();
          },
          onPanCancel: () {
            setState(() {
              _draggingTableId = null;
              _pointerDownTableId = null;
            });
          },
          child: JoinTableNodeCard(
            table: table,
            isDragging: isDragging,
            mouseCursor: isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
            onTap: () {
              if (table.tableId != widget.activeTable.id) {
                context
                    .read<DatasetBloc>()
                    .add(ChangeSheetEvent(table.tableId));
              }
            },
          ),
        ),
      ),
    );
  }
}
