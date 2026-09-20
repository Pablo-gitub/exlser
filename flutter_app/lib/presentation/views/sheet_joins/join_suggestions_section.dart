import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_canvas.dart';
import 'package:exlser/presentation/views/sheet_joins/manual_relationship_dialog.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:exlser/presentation/views/sheet_joins/join_labels.dart';
import 'package:exlser/presentation/views/sheet_joins/join_section_card.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';
import 'package:exlser/presentation/views/sheet_joins/sheet_joins_view.dart'
    show JoinViewMode;
import 'package:flutter/material.dart';

class JoinSuggestionsSection extends StatefulWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const JoinSuggestionsSection(
      {super.key, required this.state, required this.controller});

  @override
  State<JoinSuggestionsSection> createState() => _JoinSuggestionsSectionState();
}

class _JoinSuggestionsSectionState extends State<JoinSuggestionsSection> {
  bool _isCollapsed = true;

  @override
  void initState() {
    super.initState();
    if (widget.state.suggestions.isNotEmpty) {
      _isCollapsed = false;
    }
  }

  @override
  void didUpdateWidget(covariant JoinSuggestionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.status == MultiSheetJoinStatus.generatingSuggestions ||
        (widget.state.suggestions.isNotEmpty &&
            oldWidget.state.suggestions.isEmpty)) {
      _isCollapsed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;
    final busy = state.status == MultiSheetJoinStatus.generatingSuggestions;

    return JoinSectionCard(
      title: AppStrings.datasetJoinsSuggestions.tr(),
      isCollapsed: _isCollapsed && !busy,
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          TextButton.icon(
            key: const ValueKey('join_suggest_button'),
            onPressed: busy
                ? null
                : () {
                    setState(() => _isCollapsed = false);
                    controller.generateSuggestions();
                  },
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(AppStrings.datasetJoinsSuggest.tr()),
          ),
          if (!_isCollapsed || busy)
            IconButton(
              key: const ValueKey('join_suggestions_close_button'),
              icon: const Icon(Icons.close, size: 20),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () {
                setState(() => _isCollapsed = true);
              },
            ),
        ],
      ),
      child: busy
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          : state.suggestions.isEmpty
              ? Text(AppStrings.datasetJoinsNoSuggestions.tr())
              : Column(
                  children: [
                    for (final suggestion in state.suggestions)
                      _SuggestionTile(
                        suggestion: suggestion,
                        state: state,
                        controller: controller,
                      ),
                  ],
                ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final SheetRelationshipSuggestion suggestion;
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _SuggestionTile({
    required this.suggestion,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final key = joinSuggestionEndpointKey(suggestion.relationship);
    final already = state.spec.joins.any(
      (join) => state.relationshipFor(join)?.endpointKey == key,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(joinDescribeRelationship(state, suggestion.relationship)),
      subtitle: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _ConfidenceChip(confidence: suggestion.confidence),
          for (final reason in suggestion.reasons)
            Chip(
              label: Text(joinReasonLabel(reason)),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
      trailing: already
          // The tooltip is the single semantic source; the icon itself is
          // decorative and stays out of the semantics tree.
          ? Tooltip(
              message: AppStrings.datasetJoinsRelationshipAlreadyAdded.tr(),
              child: const ExcludeSemantics(
                child: Icon(Icons.check_circle_outline),
              ),
            )
          : FilledButton.tonal(
              onPressed: () => controller.confirmSuggestion(suggestion),
              child: Text(AppStrings.datasetJoinsConfirm.tr()),
            ),
    );
  }
}

/// Confidence indicator that does not rely on color alone: each level carries a
/// distinct icon shape and a text label, with color as reinforcement only.
class _ConfidenceChip extends StatelessWidget {
  final SuggestionConfidence confidence;

  const _ConfidenceChip({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (confidence) {
      SuggestionConfidence.high => (Icons.signal_cellular_alt, scheme.primary),
      SuggestionConfidence.medium => (
          Icons.signal_cellular_alt_2_bar,
          scheme.tertiary,
        ),
      SuggestionConfidence.low => (
          Icons.signal_cellular_alt_1_bar,
          scheme.outline,
        ),
    };
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(joinConfidenceLabel(confidence)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class JoinRelationshipsSection extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;
  final JoinViewMode viewMode;
  final ValueChanged<JoinViewMode> onViewModeChanged;

  const JoinRelationshipsSection({
    super.key,
    required this.state,
    required this.controller,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final joins = state.spec.joins;
    return JoinSectionCard(
      title: AppStrings.datasetJoinsRelationships.tr(),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          SegmentedButton<JoinViewMode>(
            key: const ValueKey('join_view_mode_segmented_button'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: JoinViewMode.list,
                icon: const Icon(Icons.view_list_outlined, size: 16),
                label: Text(
                  AppStrings.datasetJoinsViewModeList.tr(),
                  key: const ValueKey('join_view_mode_list'),
                ),
              ),
              ButtonSegment(
                value: JoinViewMode.graph,
                icon: const Icon(Icons.account_tree_outlined, size: 16),
                label: Text(
                  AppStrings.datasetJoinsViewModeGraph.tr(),
                  key: const ValueKey('join_view_mode_graph'),
                ),
              ),
            ],
            selected: {viewMode},
            onSelectionChanged: (set) => onViewModeChanged(set.first),
          ),
          TextButton.icon(
            key: const ValueKey('manual_relationship_open'),
            onPressed: () => showManualRelationshipDialog(
              context: context,
              state: state,
              controller: controller,
            ),
            icon: const Icon(Icons.add_link),
            label: Text(AppStrings.datasetJoinsAddRelationship.tr()),
          ),
        ],
      ),
      child: viewMode == JoinViewMode.graph
          ? JoinGraphCanvas(state: state, controller: controller)
          : (joins.isEmpty
              ? Text(AppStrings.datasetJoinsNoRelationships.tr())
              : Column(
                  children: [
                    for (final join in joins)
                      if (state.relationshipFor(join) case final relationship?)
                        _RelationshipTile(
                          join: join,
                          relationship: relationship,
                          state: state,
                          controller: controller,
                        ),
                  ],
                )),
    );
  }
}

class _RelationshipTile extends StatelessWidget {
  final MultiSheetJoin join;
  final DatasetRelationship relationship;
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _RelationshipTile({
    required this.join,
    required this.relationship,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(joinDescribeEndpoints(state, relationship))),
              IconButton(
                tooltip: AppStrings.datasetJoinsRemove.tr(),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => controller.removeJoin(join.relationshipId),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<SheetJoinType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: SheetJoinType.inner,
                  label: Text(AppStrings.datasetJoinsJoinInner.tr()),
                ),
                ButtonSegment(
                  value: SheetJoinType.left,
                  label: Text(AppStrings.datasetJoinsJoinLeft.tr()),
                ),
              ],
              selected: {join.joinType},
              onSelectionChanged: (values) => controller.setJoinType(
                join.relationshipId,
                values.first,
              ),
            ),
          ),
          // The preserved side of a LEFT join is derived (SQL accumulates from
          // the base), so it is shown read-only. To preserve the other side the
          // user changes the base table rather than picking an invalid side.
          if (join.isLeft) ...[
            const SizedBox(height: 6),
            if (controller.preservedSideFor(join.relationshipId)
                case final preservedTableId?)
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.datasetJoinsLeftKeeps.tr(
                        namedArgs: {
                          'sheet': joinSheetLabel(state, preservedTableId),
                        },
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
