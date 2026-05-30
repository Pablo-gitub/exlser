import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/immersive_mode_provider.dart';
import '../../router/routes.dart';

class AppDrawer extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final immersive = ref.watch(immersiveModeProvider);
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    // SafeArea: left/right false — the drawer is always on the left side of the
    // screen. Applying right insets would subtract the lateral nav-bar width in
    // landscape mode, reducing available width to ~127px and breaking layout.
    //
    // Layout strategy: Expanded > SingleChildScrollView for nav items (nav
    // scrolls internally if ever too tall), footer always pinned at the bottom
    // outside the scroll. No Spacer/IntrinsicHeight/SliverFillRemaining needed.
    // This is the only pattern guaranteed to never overflow on any screen size.
    final content = SafeArea(
      left: false,
      right: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          if (isAndroid) ...[
            _ImmersiveToggle(
              immersive: immersive,
              onToggle: () =>
                  ref.read(immersiveModeProvider.notifier).toggle(),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                // Wrap: if screen is very narrow the icons wrap to next line
                // instead of overflowing (e.g. in landscape with lateral nav bar).
                Wrap(
                  alignment: WrapAlignment.center,
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
    final location = GoRouterState.of(context).matchedLocation;
    return location == AppRoutes.datasetListPath ||
        location.startsWith('/datasets/');
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

class _ImmersiveToggle extends StatelessWidget {
  final bool immersive;
  final VoidCallback onToggle;

  const _ImmersiveToggle({
    required this.immersive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.fullImmersion.tr(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.fullscreen, size: 22),
              const Spacer(),
              Switch(
                value: immersive,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
