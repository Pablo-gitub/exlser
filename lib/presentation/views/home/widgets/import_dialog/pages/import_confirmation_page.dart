import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/application/dto/confirmed_import.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter/material.dart';

import '../import_dialog_viewmodel.dart';

/// Final import confirmation page.
///
/// - summarize import configuration
/// - show selected schema
/// - start dataset creation
class ImportConfirmationPage extends StatelessWidget {
  final ImportDialogViewModel viewModel;

  const ImportConfirmationPage({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final confirmedImport = viewModel.confirmedImport;

    if (confirmedImport == null) {
      return Center(
        child: Text(AppStrings.importColumnTypesEmpty.tr()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.importConfirmationTitle.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _SummaryGrid(
          items: [
            _SummaryItem(
              label: AppStrings.importConfirmationDatasetName.tr(),
              value: confirmedImport.datasetName,
            ),
            _SummaryItem(
              label: AppStrings.importConfirmationSourceFile.tr(),
              value: confirmedImport.sourceFileName,
            ),
            _SummaryItem(
              label: AppStrings.importConfirmationFileStorage.tr(),
              value: _storageModeLabel(viewModel).tr(),
            ),
            _SummaryItem(
              label: AppStrings.importConfirmationSheets.tr(),
              value: '${confirmedImport.tableCount}',
            ),
            _SummaryItem(
              label: AppStrings.importConfirmationColumns.tr(),
              value: '${confirmedImport.columnCount}',
            ),
            _SummaryItem(
              label: AppStrings.importConfirmationRows.tr(),
              value: '${confirmedImport.rowCount}',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.importConfirmationColumnTypes.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        for (var sheetIndex = 0;
            sheetIndex < confirmedImport.sheets.length;
            sheetIndex++) ...[
          _ConfirmedSheetSection(sheet: confirmedImport.sheets[sheetIndex]),
          if (sheetIndex < confirmedImport.sheets.length - 1)
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<_SummaryItem> items;

  const _SummaryGrid({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columnCount = constraints.maxWidth < 520 ? 1 : 2;
        final itemWidth = columnCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _SummaryTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });
}

class _SummaryTile extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmedSheetSection extends StatelessWidget {
  final ConfirmedImportSheet sheet;

  const _ConfirmedSheetSection({
    required this.sheet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sheet.sheet.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final column in sheet.columns)
                  Chip(
                    label: Text(
                      '${column.originalName}: '
                      '${_columnTypeLabel(column.declaredType).tr()}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _storageModeLabel(ImportDialogViewModel viewModel) {
  if (viewModel.file.hasBytes) {
    return AppStrings.importFileStorageWebTemporary;
  }

  return viewModel.saveLocally
      ? AppStrings.importFileStorageAppCopy
      : AppStrings.importFileStorageOriginalPath;
}

String _columnTypeLabel(ColumnType type) {
  switch (type) {
    case ColumnType.text:
      return AppStrings.importColumnTypeText;
    case ColumnType.integer:
      return AppStrings.importColumnTypeInteger;
    case ColumnType.real:
      return AppStrings.importColumnTypeReal;
    case ColumnType.boolean:
      return AppStrings.importColumnTypeBoolean;
    case ColumnType.date:
      return AppStrings.importColumnTypeDate;
  }
}
