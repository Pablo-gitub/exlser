import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SheetSelector extends StatelessWidget {
  final List<DatasetTable> tables;
  final DatasetTable activeTable;

  const SheetSelector({
    super.key,
    required this.tables,
    required this.activeTable,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueSheets = <String>[];
    final sheetToTables = <String, List<DatasetTable>>{};
    for (final table in tables) {
      final sheet = table.effectiveSourceSheetName;
      if (!uniqueSheets.contains(sheet)) {
        uniqueSheets.add(sheet);
      }
      sheetToTables.putIfAbsent(sheet, () => []).add(table);
    }

    final hasDistinctSheetsAndTables = tables.any(
          (t) =>
              t.sourceSheetName != null && t.sourceSheetName != t.displayName,
        ) ||
        uniqueSheets.length < tables.length;

    if (!hasDistinctSheetsAndTables) {
      return DropdownButtonFormField<int>(
        key: const ValueKey('sheet_selector_dropdown'),
        initialValue: activeTable.id,
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.table_chart_outlined),
          labelText: AppStrings.datasetWorkspaceSelectSheet.tr(),
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final table in tables)
            DropdownMenuItem(
              value: table.id,
              child: Text(table.displayName),
            ),
        ],
        onChanged: (tableId) {
          if (tableId == null) return;
          context.read<DatasetBloc>().add(ChangeSheetEvent(tableId));
        },
      );
    }

    final currentSheet = activeTable.effectiveSourceSheetName;
    final currentTablesForSheet = sheetToTables[currentSheet] ?? [activeTable];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final sheetDropdown = DropdownButtonFormField<String>(
          key: const ValueKey('sheet_selector_dropdown'),
          initialValue: uniqueSheets.contains(currentSheet)
              ? currentSheet
              : uniqueSheets.first,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.folder_outlined),
            labelText: AppStrings.datasetWorkspaceSheet.tr(),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final sheet in uniqueSheets)
              DropdownMenuItem(
                value: sheet,
                child: Text(
                  sheetToTables[sheet]!.length > 1
                      ? '$sheet (${sheetToTables[sheet]!.length})'
                      : sheet,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (selectedSheet) {
            if (selectedSheet == null || selectedSheet == currentSheet) return;
            final targetTables = sheetToTables[selectedSheet];
            if (targetTables != null && targetTables.isNotEmpty) {
              context
                  .read<DatasetBloc>()
                  .add(ChangeSheetEvent(targetTables.first.id));
            }
          },
        );

        final tableDropdown = DropdownButtonFormField<int>(
          key: const ValueKey('table_selector_dropdown'),
          initialValue: activeTable.id,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.table_chart_outlined),
            labelText: AppStrings.datasetWorkspaceTable.tr(),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final table in currentTablesForSheet)
              DropdownMenuItem(
                value: table.id,
                child: Text(
                  table.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (tableId) {
            if (tableId == null) return;
            context.read<DatasetBloc>().add(ChangeSheetEvent(tableId));
          },
        );

        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              sheetDropdown,
              const SizedBox(height: 12),
              tableDropdown,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: sheetDropdown),
            const SizedBox(width: 12),
            Expanded(child: tableDropdown),
          ],
        );
      },
    );
  }
}
