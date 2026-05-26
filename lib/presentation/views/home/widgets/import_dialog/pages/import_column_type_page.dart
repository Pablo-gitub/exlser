import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/dto/prepared_sheet.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:flutter/material.dart';

import '../import_dialog_viewmodel.dart';

/// Column type configuration page.
///
/// - display detected columns
/// - show inferred types
/// - allow manual type correction
class ImportColumnTypePage extends StatelessWidget {
  final ImportDialogViewModel viewModel;

  const ImportColumnTypePage({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final preparedImportResult = viewModel.preparedImportResult;

    if (preparedImportResult == null || !preparedImportResult.hasSheets) {
      return Center(
        child: Text(AppStrings.importColumnTypesEmpty.tr()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.importColumnTypesTitle.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        for (var sheetIndex = 0;
            sheetIndex < preparedImportResult.sheets.length;
            sheetIndex++) ...[
          _SheetColumnTypeSection(
            sheetIndex: sheetIndex,
            sheet: preparedImportResult.sheets[sheetIndex],
            viewModel: viewModel,
          ),
          if (sheetIndex < preparedImportResult.sheets.length - 1)
            const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SheetColumnTypeSection extends StatelessWidget {
  final int sheetIndex;
  final PreparedSheet sheet;
  final ImportDialogViewModel viewModel;

  const _SheetColumnTypeSection({
    required this.sheetIndex,
    required this.sheet,
    required this.viewModel,
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
              '${sheet.sheet.name} · ${sheet.sheet.rows.length} '
              '${AppStrings.importColumnTypesRows.tr()}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            for (var columnIndex = 0;
                columnIndex < sheet.inferredColumns.length;
                columnIndex++) ...[
              _ColumnTypeRow(
                column: sheet.inferredColumns[columnIndex],
                selectedType: viewModel.selectedColumnTypeFor(
                  sheetIndex: sheetIndex,
                  columnIndex: columnIndex,
                ),
                onChanged: (type) {
                  if (type == null) return;

                  viewModel.updateColumnType(
                    sheetIndex: sheetIndex,
                    columnIndex: columnIndex,
                    type: type,
                  );
                },
              ),
              if (columnIndex < sheet.inferredColumns.length - 1)
                const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColumnTypeRow extends StatelessWidget {
  final DatasetColumn column;
  final ColumnType? selectedType;
  final ValueChanged<ColumnType?> onChanged;

  const _ColumnTypeRow({
    required this.column,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final details = _ColumnDetails(column: column);
        final selector = DropdownButtonFormField<ColumnType>(
          initialValue: selectedType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: AppStrings.importColumnSelectedType.tr(),
            isDense: true,
          ),
          items: [
            for (final type in ColumnType.values)
              DropdownMenuItem(
                value: type,
                child: Text(_columnTypeLabel(type).tr()),
              ),
          ],
          onChanged: onChanged,
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              const SizedBox(height: 8),
              selector,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: details),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: selector,
            ),
          ],
        );
      },
    );
  }
}

class _ColumnDetails extends StatelessWidget {
  final DatasetColumn column;

  const _ColumnDetails({
    required this.column,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.importColumnOriginalName.tr()}: '
          '${column.originalName}',
        ),
        const SizedBox(height: 4),
        Text(
          '${AppStrings.importColumnDatabaseName.tr()}: ${column.dbName}',
          style: labelStyle,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${AppStrings.importColumnInferredType.tr()}: '
                '${_columnTypeLabel(column.inferredType).tr()}',
                style: labelStyle,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: AppStrings.importColumnTypeInfoTooltip.tr(),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.info_outline, size: 18),
                onPressed: () => _showColumnTypeInfoDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

void _showColumnTypeInfoDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(AppStrings.importColumnTypeInfoTitle.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.importColumnTypeInfoIntro.tr()),
              const SizedBox(height: 16),
              _InfoLine(text: AppStrings.importColumnTypeInfoText.tr()),
              _InfoLine(text: AppStrings.importColumnTypeInfoInteger.tr()),
              _InfoLine(text: AppStrings.importColumnTypeInfoReal.tr()),
              _InfoLine(text: AppStrings.importColumnTypeInfoBoolean.tr()),
              _InfoLine(text: AppStrings.importColumnTypeInfoDate.tr()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      );
    },
  );
}

class _InfoLine extends StatelessWidget {
  final String text;

  const _InfoLine({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text),
    );
  }
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
