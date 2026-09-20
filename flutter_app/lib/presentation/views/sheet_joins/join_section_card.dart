import 'package:flutter/material.dart';

class JoinSectionCard extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget child;
  final Widget? trailing;
  final bool isCollapsed;

  const JoinSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.hint,
    this.trailing,
    this.isCollapsed = false,
  });

  Widget _buildHeader(BuildContext context) {
    final titleText = Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
    if (trailing == null) return titleText;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On roomy rows keep the action right-aligned; on narrow widths let it
        // wrap below the title instead of overflowing.
        if (constraints.maxWidth >= 420) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleText),
              const SizedBox(width: 8),
              trailing!,
            ],
          );
        }
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [titleText, trailing!],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (!isCollapsed) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class JoinMessage extends StatelessWidget {
  final String text;
  final IconData? icon;

  const JoinMessage({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
            ],
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
