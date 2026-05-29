import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  final bool closeOnNavigate;
  final VoidCallback? onCloseRequested;

  const AppDrawer({
    super.key,
    this.closeOnNavigate = true,
    this.onCloseRequested,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 24),
          ListTile(
            selected: _isHomeSelected(context),
            leading: const Icon(Icons.home),
            title: Text(AppStrings.home.tr()),
            onTap: () => _go(context, AppRoutes.homePath),
          ),
          ListTile(
            selected: _isWorksSelected(context),
            leading: const Icon(Icons.folder_copy),
            title: Text(AppStrings.works.tr()),
            onTap: () => _go(context, AppRoutes.datasetListPath),
          ),
          ListTile(
            selected: _isSettingsSelected(context),
            leading: const Icon(Icons.settings),
            title: Text(AppStrings.settings.tr()),
            onTap: () => _go(context, AppRoutes.settingsPath),
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
                      icon: const FaIcon(FontAwesomeIcons.github),
                      onPressed: () => _openExternalLink(
                        context,
                        _githubUri,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.openLinkedin.tr(),
                      icon: const FaIcon(FontAwesomeIcons.linkedin),
                      onPressed: () => _openExternalLink(
                        context,
                        _linkedinUri,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.openInstagram.tr(),
                      icon: const FaIcon(FontAwesomeIcons.instagram),
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
    );

    if (closeOnNavigate) {
      return Drawer(child: content);
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: content,
    );
  }

  void _go(BuildContext context, String path) {
    final currentPath = GoRouterState.of(context).uri.path;
    final router = GoRouter.of(context);
    final scaffold = Scaffold.maybeOf(context);
    final shouldNavigate = currentPath != path;

    if (!closeOnNavigate) {
      if (shouldNavigate) {
        router.go(path);
      }
      return;
    }

    onCloseRequested?.call();
    if (onCloseRequested == null) {
      scaffold?.closeDrawer();
    }

    if (shouldNavigate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(path);
      });
    }
  }

  bool _isHomeSelected(BuildContext context) {
    return GoRouterState.of(context).matchedLocation == AppRoutes.homePath;
  }

  bool _isWorksSelected(BuildContext context) {
    return switch (GoRouterState.of(context).matchedLocation) {
      AppRoutes.datasetListPath ||
      AppRoutes.datasetPath ||
      AppRoutes.multiDatasetAnalyticsPath =>
        true,
      _ => false,
    };
  }

  bool _isSettingsSelected(BuildContext context) {
    return GoRouterState.of(context).matchedLocation == AppRoutes.settingsPath;
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
