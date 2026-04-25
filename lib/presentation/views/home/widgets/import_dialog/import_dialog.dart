import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Initial dialog used to configure dataset import.
///
/// Responsibilities:
/// - collect dataset metadata
/// - configure import behavior
/// - start import workflow
///
/// Current step:
/// 1. Dataset name
/// 2. Save file locally option
///
/// Future steps:
/// - schema confirmation
/// - type inference review
/// - relationship detection
class ImportDialog extends StatelessWidget {
  const ImportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Dialog title
              Text(
                AppStrings.importTitle.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 24),

              /// Dataset name input
              TextField(
                decoration: InputDecoration(
                  labelText:
                      AppStrings.importDatasetName.tr(),
                ),
              ),

              const SizedBox(height: 16),

              /// Save imported file locally
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title:
                    Text(AppStrings.importSaveLocally.tr()),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              /// Continue import workflow
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO:
                    // Open schema analysis step
                  },
                  child: Text(AppStrings.importNext.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}