import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../router/routes.dart';

/// Shared navigation drawer used across the app.
///
/// Provides navigation to:
/// - Home
/// - Works list
/// - Settings
class AppDrawer extends StatelessWidget {
  static final Uri _developerWebsiteUri =
      Uri.parse('https://paolopietrelli.com');
  static final Uri _githubUri =
      Uri.parse('https://github.com/Pablo-gitub/exlser');
  static final Uri _linkedinUri =
      Uri.parse('https://www.linkedin.com/in/paolo-pietrelli');
  static final Uri _instagramUri =
      Uri.parse('https://www.instagram.com/ing_paolo_pietrelli/');

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
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Column(
                children: [
                  Tooltip(
                    message: AppStrings.openWebsite.tr(),
                    child: ListTile(
                      leading: const Icon(Icons.account_circle_outlined),
                      title: Text(AppStrings.developer.tr()),
                      subtitle: Text(AppStrings.developerWebsite.tr()),
                      onTap: () => _openExternalLink(
                        context,
                        _developerWebsiteUri,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: AppStrings.openGithub.tr(),
                        icon: const Icon(Icons.code),
                        onPressed: () => _openExternalLink(
                          context,
                          _githubUri,
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.openLinkedin.tr(),
                        icon: const Icon(Icons.business_center_outlined),
                        onPressed: () => _openExternalLink(
                          context,
                          _linkedinUri,
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.openInstagram.tr(),
                        icon: const Icon(Icons.photo_camera_outlined),
                        onPressed: () => _openExternalLink(
                          context,
                          _instagramUri,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalLink(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uri.toString())),
      );
    }
  }
}
