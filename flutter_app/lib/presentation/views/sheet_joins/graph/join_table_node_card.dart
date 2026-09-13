import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_models.dart';

class JoinTableNodeCard extends StatelessWidget {
  final GraphTableLayout table;
  final VoidCallback? onHeaderTap;

  const JoinTableNodeCard({
    super.key,
    required this.table,
    this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: table.isBase
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: table.isBase ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: table.size.width,
        height: table.size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            InkWell(
              onTap: onHeaderTap,
              child: Container(
                height: JoinGraphLayoutBuilder.headerHeight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: table.isBase
                      ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      table.isBase
                          ? Icons.stars_rounded
                          : Icons.table_chart_outlined,
                      size: 18,
                      color: table.isBase
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            table.tableName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${table.rowCount} rows',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (table.isBase) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppStrings.datasetJoinsGraphBaseTable.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Columns List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: table.columns.length,
                itemBuilder: (context, index) {
                  final col = table.columns[index];
                  final isConnected = col.isConnected;

                  return Container(
                    height: JoinGraphLayoutBuilder.columnItemHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Left pin dot
                        _PinDot(
                          isConnected: isConnected,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 6),
                        // Column Type Icon
                        _buildTypeIcon(col.columnType, colorScheme),
                        const SizedBox(width: 6),
                        // Column Name
                        Expanded(
                          child: Text(
                            col.columnName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isConnected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isConnected
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Right pin dot
                        _PinDot(
                          isConnected: isConnected,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ColumnType type, ColorScheme scheme) {
    final (icon, color) = switch (type) {
      ColumnType.integer => (Icons.tag, scheme.secondary),
      ColumnType.real => (Icons.percent, scheme.secondary),
      ColumnType.text => (Icons.text_fields, scheme.primary),
      ColumnType.boolean => (Icons.check_circle_outline, scheme.tertiary),
      ColumnType.date => (Icons.calendar_today, scheme.error),
    };

    return Icon(icon, size: 14, color: color);
  }
}

class _PinDot extends StatelessWidget {
  final bool isConnected;
  final ColorScheme colorScheme;

  const _PinDot({
    required this.isConnected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(alpha: 0.4),
        border: isConnected
            ? Border.all(color: colorScheme.surface, width: 1)
            : null,
      ),
    );
  }
}
