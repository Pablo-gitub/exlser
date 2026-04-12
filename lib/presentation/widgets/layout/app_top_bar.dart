import 'package:flutter/material.dart';

/// Shared top app bar used across the application.
///
/// Responsibilities:
/// - display screen title
/// - provide menu access
/// - support optional actions
///
/// Future:
/// - support drawer opening
/// - support responsive layouts
class AppTopBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          // TODO: open navigation drawer
        },
      ),
      title: Text(title),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}