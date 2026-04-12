import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/presentation/router/routes.dart';
import 'package:exel_category/presentation/widgets/layout/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// View displaying all saved datasets (workspaces).
///
/// This page is accessible from the main navigation menu
/// and allows the user to:
/// - browse saved datasets
/// - open a selected dataset
/// - delete a dataset
///
/// The HomeView remains dedicated to importing a new file,
/// while this page is used only for reopening existing workspaces.

class DatasetsListView extends StatelessWidget {
  const DatasetsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppStrings.works.tr(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.noWorksYet.tr(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.homePath);
              },
              child: Text(
                AppStrings.goHome.tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}