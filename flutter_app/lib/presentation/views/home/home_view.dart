import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/presentation/views/home/widgets/file_drop_area.dart';
import 'package:exlser/presentation/views/home/widgets/import_dialog/import_dialog.dart';
import 'package:exlser/presentation/widgets/layout/scroll_bottom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_provider.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo_full.png',
                        width: 220,
                      ),
                      const SizedBox(height: 32),
                      FileDropArea(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 48,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.upload_file, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                viewModel.selectedFileName ??
                                    AppStrings.homeSelectFile.tr(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: viewModel.hasFile
                              ? () {
                                  _openImportDialog(context, ref);
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(AppStrings.processFile.tr()),
                          ),
                        ),
                      ),
                      const ScrollBottomSpacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openImportDialog(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(homeViewModelProvider);
    final file = viewModel.selectedImportFile;

    if (file == null) return;

    showDialog(
      context: context,
      builder: (_) => ImportDialog(
        file: file,
        initialDatasetName: viewModel.suggestedDatasetName,
        onImportCompleted: () {
          ref.read(homeViewModelProvider).clearSelection();
        },
      ),
    );
  }
}
