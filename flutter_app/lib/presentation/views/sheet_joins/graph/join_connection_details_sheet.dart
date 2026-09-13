import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';

class JoinConnectionDetailsSheet extends StatelessWidget {
  final String fromTableName;
  final String toTableName;
  final String fromColumnName;
  final String toColumnName;
  final String baseTableName;
  final SheetJoinType joinType;
  final bool isSuggestion;
  final ValueChanged<SheetJoinType>? onJoinTypeChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onConfirmSuggestion;

  const JoinConnectionDetailsSheet({
    super.key,
    required this.fromTableName,
    required this.toTableName,
    required this.fromColumnName,
    required this.toColumnName,
    required this.baseTableName,
    required this.joinType,
    required this.isSuggestion,
    this.onJoinTypeChanged,
    this.onRemove,
    this.onConfirmSuggestion,
  });

  static Future<void> show({
    required BuildContext context,
    required String fromTableName,
    required String toTableName,
    required String fromColumnName,
    required String toColumnName,
    required String baseTableName,
    required SheetJoinType joinType,
    required bool isSuggestion,
    ValueChanged<SheetJoinType>? onJoinTypeChanged,
    VoidCallback? onRemove,
    VoidCallback? onConfirmSuggestion,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => JoinConnectionDetailsSheet(
        fromTableName: fromTableName,
        toTableName: toTableName,
        fromColumnName: fromColumnName,
        toColumnName: toColumnName,
        baseTableName: baseTableName,
        joinType: joinType,
        isSuggestion: isSuggestion,
        onJoinTypeChanged: onJoinTypeChanged,
        onRemove: onRemove,
        onConfirmSuggestion: onConfirmSuggestion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final otherTableName =
        baseTableName == fromTableName ? toTableName : fromTableName;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isSuggestion ? Icons.lightbulb_outline : Icons.link,
                color:
                    isSuggestion ? colorScheme.tertiary : colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSuggestion
                      ? AppStrings.datasetJoinsSuggestions.tr()
                      : AppStrings.datasetJoinsGraphExplanationTitle.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Match explanation card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TableChip(name: fromTableName, colorScheme: colorScheme),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward,
                        size: 16, color: colorScheme.outline),
                    const SizedBox(width: 6),
                    _TableChip(name: toTableName, colorScheme: colorScheme),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.datasetJoinsGraphExplanationMatch.tr(
                    namedArgs: {
                      'fromTable': fromTableName,
                      'toTable': toTableName,
                      'fromCol': fromColumnName,
                      'toCol': toColumnName,
                    },
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Join type options (if confirmed)
          if (!isSuggestion && onJoinTypeChanged != null) ...[
            Text(
              AppStrings.datasetJoinsJoinType.tr(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Left join option
            _JoinTypeOptionTile(
              title: AppStrings.datasetJoinsJoinLeft.tr(),
              subtitle: AppStrings.datasetJoinsGraphRuleLeft.tr(
                namedArgs: {
                  'baseTable': baseTableName,
                  'otherTable': otherTableName,
                },
              ),
              isSelected: joinType == SheetJoinType.left,
              icon: Icons.subdirectory_arrow_right,
              onTap: () {
                onJoinTypeChanged!(SheetJoinType.left);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),

            // Inner join option
            _JoinTypeOptionTile(
              title: AppStrings.datasetJoinsJoinInner.tr(),
              subtitle: AppStrings.datasetJoinsGraphRuleInner.tr(),
              isSelected: joinType == SheetJoinType.inner,
              icon: Icons.compare_arrows,
              onTap: () {
                onJoinTypeChanged!(SheetJoinType.inner);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          if (isSuggestion && onConfirmSuggestion != null) ...[
            FilledButton.icon(
              icon: const Icon(Icons.add_link),
              label: Text(AppStrings.datasetJoinsGraphAddSuggestion.tr()),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirmSuggestion!();
              },
            ),
          ] else if (onRemove != null) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side:
                    BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
              ),
              icon: const Icon(Icons.delete_outline),
              label: Text(AppStrings.datasetJoinsRemove.tr()),
              onPressed: () {
                Navigator.of(context).pop();
                onRemove!();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TableChip extends StatelessWidget {
  final String name;
  final ColorScheme colorScheme;

  const _TableChip({required this.name, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _JoinTypeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _JoinTypeOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
