import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/core/theme/app_spacing.dart';
import 'package:exel_category/presentation/widgets/layout/app_scaffold.dart';
import 'package:flutter/material.dart';

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
    return AppScaffold(
      title: AppStrings.settings.tr(),
      body: SingleChildScrollView(
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
                      DropdownMenuItem(
                        value: const Locale('en'),
                        child: Text(
                          AppStrings.languageEnglish.tr(),
                        ),
                      ),
                      DropdownMenuItem(
                        value: const Locale('it'),
                        child: Text(
                          AppStrings.languageItalian.tr(),
                        ),
                      ),
                    ],
                    onChanged: (locale) {
                      if (locale != null) {
                        context.setLocale(locale);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
