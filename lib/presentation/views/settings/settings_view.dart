import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/core/theme/app_spacing.dart';
import 'package:exlser/presentation/router/routes.dart';
import 'package:exlser/presentation/widgets/layout/scroll_bottom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
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
}
