import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/update_service.dart';
import 'package:exlser/core/constants/app_info.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/core/theme/app_spacing.dart';
import 'package:exlser/presentation/providers/immersive_mode_provider.dart';
import 'package:exlser/presentation/router/routes.dart';
import 'package:exlser/presentation/views/settings/settings_update_controller.dart';
import 'package:exlser/presentation/widgets/layout/scroll_bottom_spacer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Application settings view.
///
/// This page allows the user to configure global application behavior.
///
/// Planned settings:
/// - language
/// - default file storage mode
/// - default results view
/// - auto-save workspace state
/// - theme mode

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final immersive = isAndroid ? ref.watch(immersiveModeProvider) : false;
    final updatePlatform = ref.watch(desktopUpdatePlatformProvider);
    final updateState = ref.watch(settingsUpdateControllerProvider);
    final showDesktopUpdates =
        updatePlatform != DesktopUpdatePlatform.unsupported;

    ref.listen<SettingsUpdateState>(
      settingsUpdateControllerProvider,
      (previous, next) {
        if (previous?.status != SettingsUpdateStatus.updateAvailable &&
            next.status == SettingsUpdateStatus.updateAvailable) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              _showUpdateDialog(context, next.result);
            }
          });
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(AppRoutes.homePath);
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.languageLabel.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: AppSpacing.m,
                  ),
                  DropdownButtonFormField<Locale>(
                    initialValue: context.locale,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      _languageItem(
                        locale: const Locale('en'),
                        labelKey: AppStrings.languageEnglish,
                      ),
                      _languageItem(
                        locale: const Locale('it'),
                        labelKey: AppStrings.languageItalian,
                      ),
                      _languageItem(
                        locale: const Locale('es'),
                        labelKey: AppStrings.languageSpanish,
                      ),
                      _languageItem(
                        locale: const Locale('fr'),
                        labelKey: AppStrings.languageFrench,
                      ),
                      _languageItem(
                        locale: const Locale('de'),
                        labelKey: AppStrings.languageGerman,
                      ),
                      _languageItem(
                        locale: const Locale('zh'),
                        labelKey: AppStrings.languageChinese,
                      ),
                      _languageItem(
                        locale: const Locale('ru'),
                        labelKey: AppStrings.languageRussian,
                      ),
                      _languageItem(
                        locale: const Locale('ja'),
                        labelKey: AppStrings.languageJapanese,
                      ),
                      _languageItem(
                        locale: const Locale('pt'),
                        labelKey: AppStrings.languagePortuguese,
                      ),
                    ],
                    onChanged: (locale) {
                      if (locale != null) {
                        context.setLocale(locale);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const Divider(),
                  const SizedBox(height: AppSpacing.m),
                  if (isAndroid) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fullscreen),
                      title: Text(AppStrings.fullImmersion.tr()),
                      value: immersive,
                      onChanged: (_) {
                        ref.read(immersiveModeProvider.notifier).toggle();
                      },
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const Divider(),
                    const SizedBox(height: AppSpacing.m),
                  ],
                  Text(
                    AppStrings.appVersionLabel.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    AppStrings.appVersionValue.tr(
                      namedArgs: {
                        'version': AppInfo.versionName,
                      },
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (showDesktopUpdates) ...[
                    const SizedBox(height: AppSpacing.m),
                    _UpdateControls(
                      state: updateState,
                      onCheck: () {
                        ref
                            .read(settingsUpdateControllerProvider.notifier)
                            .checkForUpdates();
                      },
                      onOpenUpdate: () {
                        _openUpdateLink(context, updateState.result?.updateUri);
                      },
                    ),
                  ],
                  const ScrollBottomSpacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<Locale> _languageItem({
    required Locale locale,
    required String labelKey,
  }) {
    return DropdownMenuItem(
      value: locale,
      child: Text(labelKey.tr()),
    );
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    UpdateCheckResult? result,
  ) async {
    final updateUri = result?.updateUri;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppStrings.updateAvailableTitle.tr()),
          content: Text(
            AppStrings.updateAvailableMessage.tr(
              namedArgs: {
                'version': result?.latestVersion ?? '',
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.close.tr()),
            ),
            FilledButton(
              onPressed: updateUri == null
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      _openUpdateLink(context, updateUri);
                    },
              child: Text(_updateActionLabel(result).tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUpdateLink(BuildContext context, Uri? uri) async {
    if (uri == null) {
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.updateOpenFailed.tr())),
      );
    }
  }

  String _updateActionLabel(UpdateCheckResult? result) {
    if (result?.platformAsset == null) {
      return AppStrings.updateOpenRelease;
    }
    return AppStrings.updateDownload;
  }
}

class _UpdateControls extends StatelessWidget {
  final SettingsUpdateState state;
  final VoidCallback onCheck;
  final VoidCallback onOpenUpdate;

  const _UpdateControls({
    required this.state,
    required this.onCheck,
    required this.onOpenUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = _statusTextKey();
    final latestVersion = state.result?.latestVersion ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            OutlinedButton.icon(
              icon: state.isChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update_alt),
              label: Text(
                state.isChecking
                    ? AppStrings.updateChecking.tr()
                    : AppStrings.updateCheck.tr(),
              ),
              onPressed: state.isChecking ? null : onCheck,
            ),
            if (state.isUpdateAvailable)
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(_updateActionLabel().tr()),
                onPressed: onOpenUpdate,
              ),
          ],
        ),
        if (statusText != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            statusText.tr(
              namedArgs: {
                'version': latestVersion,
              },
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _statusColor(context),
                ),
          ),
        ],
      ],
    );
  }

  String? _statusTextKey() {
    return switch (state.status) {
      SettingsUpdateStatus.upToDate => AppStrings.updateUpToDate,
      SettingsUpdateStatus.updateAvailable => AppStrings.updateAvailableMessage,
      SettingsUpdateStatus.error => AppStrings.updateError,
      SettingsUpdateStatus.unsupportedPlatform => AppStrings.updateUnsupported,
      SettingsUpdateStatus.idle || SettingsUpdateStatus.checking => null,
    };
  }

  Color _statusColor(BuildContext context) {
    if (state.status == SettingsUpdateStatus.error) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  String _updateActionLabel() {
    if (state.result?.platformAsset == null) {
      return AppStrings.updateOpenRelease;
    }
    return AppStrings.updateDownload;
  }
}
