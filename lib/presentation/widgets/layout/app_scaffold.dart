import 'package:flutter/material.dart';

import 'app_drawer.dart';
import 'app_top_bar.dart';

/// Shared scaffold shell for application pages.
///
/// Includes:
/// - shared top bar
/// - shared drawer
/// - page body
class AppScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: title,
        actions: actions,
      ),
      drawer: const AppDrawer(),
      body: body,
    );
  }
}