import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_drawer.dart';
import 'app_shell_actions.dart';
import 'app_top_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  final String title;
  final Widget child;

  const AppShell({
    super.key,
    required this.title,
    required this.child,
  });

  @visibleForTesting
  static bool shouldUseExpandedNavigationForSize(Size size) {
    return size.width >= _AppShellState._expandedNavigationBreakpoint &&
        size.shortestSide >= _AppShellState._expandedNavigationMinShortestSide;
  }

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const double _expandedNavigationBreakpoint = 840;
  static const double _expandedNavigationMinShortestSide = 600;
  static const double _sideNavigationWidth = 232;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isExpandedNavigationOpen = true;

  @override
  Widget build(BuildContext context) {
    final shellActions = ref.watch(appShellActionsProvider);

    return LayoutBuilder(
      builder: (context, _) {
        final useExpandedNavigation =
            AppShell.shouldUseExpandedNavigationForSize(
          MediaQuery.sizeOf(context),
        );

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppTopBar(
            title: widget.title,
            actions: [
              for (final action in shellActions) action.builder(context),
            ],
            isMenuOpen: useExpandedNavigation && _isExpandedNavigationOpen,
            onMenuPressed: useExpandedNavigation
                ? () {
                    setState(() {
                      _isExpandedNavigationOpen = !_isExpandedNavigationOpen;
                    });
                  }
                : null,
          ),
          drawer: useExpandedNavigation
              ? null
              : AppDrawer(onCloseRequested: _closeDrawer),
          body: Row(
            children: [
              if (useExpandedNavigation && _isExpandedNavigationOpen) ...[
                const SizedBox(
                  width: _sideNavigationWidth,
                  child: AppDrawer(closeOnNavigate: false),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }

  void _closeDrawer() {
    _scaffoldKey.currentState?.closeDrawer();
  }
}
