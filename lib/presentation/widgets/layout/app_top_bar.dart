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
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final bool isMenuOpen;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.onMenuPressed,
    this.isMenuOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: Icon(isMenuOpen ? Icons.menu_open : Icons.menu),
            onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: _AppBarTitle(title: title),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarTitle extends StatelessWidget {
  final String title;

  const _AppBarTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (title.trim().toLowerCase() != 'exlser') {
      return Text(title);
    }

    return Semantics(
      label: title,
      image: true,
      child: ExcludeSemantics(
        child: Image.asset(
          'assets/images/Exlser_wordmark.png',
          height: 36,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
