import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../router/routes.dart';

/// Shared navigation drawer used across the app.
///
/// Provides navigation to:
/// - Home
/// - Works list
/// - Settings
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppStrings.home.tr()),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.homePath);
              },
            ),

            ListTile(
              leading: const Icon(Icons.folder_copy),
              title: Text(AppStrings.works.tr()),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.datasetListPath);
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppStrings.settings.tr()),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.settingsPath);
              },
            ),
          ],
        ),
      ),
    );
  }
}