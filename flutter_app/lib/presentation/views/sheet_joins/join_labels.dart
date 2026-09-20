import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';

/// Labels shared by the join workspace: how an endpoint, a relationship or a
/// suggestion reads to the user, and which message an error code maps to.
///
/// They were private functions at the bottom of sheet_joins_view.dart, which is
/// what kept every section of that screen in the same file.
String joinSide(MultiSheetJoinState state, int tableId, String dbName) {
  final sheet = joinSheetFor(state, tableId);
  final column = sheet?.columns
      .where((c) => c.dbName == dbName)
      .map((c) => c.originalName)
      .firstOrNull;
  return '${sheet?.label ?? tableId}.${column ?? dbName}';
}

String joinDescribeRelationship(
  MultiSheetJoinState state,
  SheetJoinRelationship relationship,
) {
  return '${joinSide(state, relationship.leftTableId, relationship.leftColumnDbName)}'
      '  ↔  '
      '${joinSide(state, relationship.rightTableId, relationship.rightColumnDbName)}';
}

String joinDescribeEndpoints(
  MultiSheetJoinState state,
  DatasetRelationship relationship,
) {
  return '${joinSide(state, relationship.endpointATableId, relationship.endpointAColumnDbName)}'
      '  ↔  '
      '${joinSide(state, relationship.endpointBTableId, relationship.endpointBColumnDbName)}';
}

String joinSuggestionEndpointKey(SheetJoinRelationship relationship) {
  final a =
      '${relationship.leftTableId}.${relationship.leftColumnDbName.trim()}';
  final b =
      '${relationship.rightTableId}.${relationship.rightColumnDbName.trim()}';
  final ends = [a, b]..sort();
  return ends.join('=');
}

String joinSheetLabel(MultiSheetJoinState state, int tableId) {
  return joinSheetFor(state, tableId)?.label ?? '$tableId';
}

MultiSheetSheetInfo? joinSheetFor(MultiSheetJoinState state, int tableId) {
  return state.sheets.where((s) => s.tableId == tableId).firstOrNull;
}

String joinConfidenceLabel(SuggestionConfidence confidence) {
  return switch (confidence) {
    SuggestionConfidence.high => AppStrings.datasetJoinsConfidenceHigh.tr(),
    SuggestionConfidence.medium => AppStrings.datasetJoinsConfidenceMedium.tr(),
    SuggestionConfidence.low => AppStrings.datasetJoinsConfidenceLow.tr(),
  };
}

String joinReasonLabel(RelationshipReason reason) {
  return switch (reason) {
    RelationshipReason.nameMatch => AppStrings.datasetJoinsReasonNameMatch.tr(),
    RelationshipReason.commonIdentifier =>
      AppStrings.datasetJoinsReasonCommonIdentifier.tr(),
    RelationshipReason.valueOverlap =>
      AppStrings.datasetJoinsReasonValueOverlap.tr(),
    RelationshipReason.typeMatch => AppStrings.datasetJoinsReasonTypeMatch.tr(),
  };
}

String joinErrorMessage(String code) {
  return switch (code) {
    MultiSheetGraphValidator.notEnoughTablesCode =>
      AppStrings.datasetJoinsErrorNotEnoughTables.tr(),
    MultiSheetGraphValidator.unavailableTableOrColumnCode =>
      AppStrings.datasetJoinsErrorUnavailableTableOrColumn.tr(),
    MultiSheetGraphValidator.incompleteRelationshipCode =>
      AppStrings.datasetJoinsErrorIncompleteRelationship.tr(),
    MultiSheetGraphValidator.duplicateRelationshipCode =>
      AppStrings.datasetJoinsErrorDuplicateRelationship.tr(),
    MultiSheetGraphValidator.disconnectedGraphCode =>
      AppStrings.datasetJoinsErrorDisconnectedGraph.tr(),
    MultiSheetGraphValidator.cycleDetectedCode =>
      AppStrings.datasetJoinsErrorCycleDetected.tr(),
    MultiSheetSqlBuilder.noOutputColumnsCode =>
      AppStrings.datasetJoinsErrorNoOutputColumns.tr(),
    'save_name_required' => AppStrings.datasetJoinsSaveNameRequired.tr(),
    'save_failed' => AppStrings.datasetJoinsSaveFailed.tr(),
    'load_saved_failed' => AppStrings.datasetJoinsLoadSavedFailed.tr(),
    'delete_saved_failed' => AppStrings.datasetJoinsDeleteSavedFailed.tr(),
    _ => AppStrings.datasetJoinsErrorGeneric.tr(),
  };
}

String? joinErrorSolution(String code) {
  return switch (code) {
    MultiSheetGraphValidator.cycleDetectedCode =>
      AppStrings.datasetJoinsErrorSolutionCycleDetected.tr(),
    MultiSheetGraphValidator.disconnectedGraphCode =>
      AppStrings.datasetJoinsErrorSolutionDisconnectedGraph.tr(),
    MultiSheetGraphValidator.notEnoughTablesCode =>
      AppStrings.datasetJoinsErrorSolutionNotEnoughTables.tr(),
    MultiSheetGraphValidator.incompleteRelationshipCode =>
      AppStrings.datasetJoinsErrorSolutionIncompleteRelationship.tr(),
    MultiSheetGraphValidator.duplicateRelationshipCode =>
      AppStrings.datasetJoinsErrorSolutionDuplicateRelationship.tr(),
    'invalid_left_join_direction' =>
      AppStrings.datasetJoinsErrorSolutionInvalidLeftJoinDirection.tr(),
    MultiSheetSqlBuilder.noOutputColumnsCode =>
      AppStrings.datasetJoinsErrorSolutionNoOutputColumns.tr(),
    MultiSheetGraphValidator.unavailableTableOrColumnCode =>
      AppStrings.datasetJoinsErrorSolutionUnavailableTableOrColumn.tr(),
    _ => null,
  };
}
