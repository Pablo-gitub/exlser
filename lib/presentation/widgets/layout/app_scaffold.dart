import 'package:flutter/material.dart';

import 'app_drawer.dart';
import 'app_top_bar.dart';

/// Shared scaffold shell for application pages.
///
/// Includes:
/// - shared top bar
/// - shared drawer
/// - page body
class AppScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  static const double _expandedNavigationBreakpoint = 840;
  static const double _drawerWidth = 304;

  bool _isExpandedNavigationOpen = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useExpandedNavigation =
            constraints.maxWidth >= _expandedNavigationBreakpoint;

        return Scaffold(
          appBar: AppTopBar(
            title: widget.title,
            actions: widget.actions,
            isMenuOpen: useExpandedNavigation && _isExpandedNavigationOpen,
            onMenuPressed: useExpandedNavigation
                ? () {
                    setState(() {
                      _isExpandedNavigationOpen = !_isExpandedNavigationOpen;
                    });
                  }
                : null,
          ),
          drawer: useExpandedNavigation ? null : const AppDrawer(),
          body: Row(
            children: [
              if (useExpandedNavigation && _isExpandedNavigationOpen) ...[
                const SizedBox(
                  width: _drawerWidth,
                  child: AppDrawer(closeOnNavigate: false),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: widget.body),
            ],
          ),
        );
      },
    );
  }
}
