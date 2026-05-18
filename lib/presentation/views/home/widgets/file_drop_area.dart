import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/core/theme/app_colors.dart';
import 'package:exel_category/presentation/views/home/home_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileDropArea extends StatelessWidget {
  final Widget child;

  const FileDropArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const _WebFileDropArea();
    }

    return const _MobileFileDropArea();
  }
}

class _MobileFileDropArea extends ConsumerWidget {
  const _MobileFileDropArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(homeViewModelProvider);

    return GestureDetector(
      onTap: () async {
        await ref.read(homeViewModelProvider).pickFile();
      },
      child: _buildUploadBox(
        context,
        ref,
        placeholderText: vm.selectedFileName ?? AppStrings.homeSelectFile.tr(),
      ),
    );
  }
}

class _WebFileDropArea extends ConsumerStatefulWidget {
  const _WebFileDropArea();

  @override
  ConsumerState<_WebFileDropArea> createState() => _WebFileDropAreaState();
}

class _WebFileDropAreaState extends ConsumerState<_WebFileDropArea> {
  DropzoneViewController? controller;
  bool isHovering = false;

  Future<void> _browseFile() async {
    if (controller == null) return;

    final files = await controller!.pickFiles();
    if (files.isEmpty) return;

    final file = files.first;
    final name = await controller!.getFilename(file);
    final bytes = await controller!.getFileData(file);

    ref.read(homeViewModelProvider).selectFileFromWeb(
          name: name,
          bytes: bytes,
        );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);

    return Column(
      children: [
        Stack(
          children: [
            _buildUploadBox(
              context,
              ref,
              placeholderText:
                  vm.selectedFileName ?? AppStrings.homeDropFile.tr(),
              isHovering: isHovering,
            ),

            /// ✅ Dropzone SOLO quando NON hai file
            if (!vm.hasFile)
              Positioned.fill(
                child: DropzoneView(
                  onCreated: (ctrl) => controller = ctrl,
                  onHover: () => setState(() => isHovering = true),
                  onLeave: () => setState(() => isHovering = false),
                  onDropFile: (file) async {
                    if (controller == null) return;

                    final name = await controller!.getFilename(file);
                    final bytes = await controller!.getFileData(file);

                    ref.read(homeViewModelProvider).selectFileFromWeb(
                          name: name,
                          bytes: bytes,
                        );

                    setState(() => isHovering = false);
                  },
                ),
              ),
          ],
        ),

        /// Bottone browse (solo quando non hai file)
        if (!vm.hasFile) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: _browseFile,
            child: Text(AppStrings.browseFile.tr()),
          ),
        ],
      ],
    );
  }
}

Widget _buildUploadBox(
  BuildContext context,
  WidgetRef ref, {
  required String placeholderText,
  bool isHovering = false,
}) {
  final vm = ref.watch(homeViewModelProvider);

  return Stack(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 48,
          horizontal: 24,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isHovering ? Colors.blue : Colors.grey.shade400,
            width: isHovering ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.upload_file, size: 48),
            const SizedBox(height: 16),
            Text(
              placeholderText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      if (vm.hasFile)
        Positioned(
          top: 8,
          right: 8,
          child: _buildClearButton(() {
            ref.read(homeViewModelProvider).clearSelection();
          }),
        ),
    ],
  );
}

Widget _buildClearButton(VoidCallback onPressed) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close, // oppure Icons.delete
          size: 16,
          color: Colors.white,
        ),
      ),
    ),
  );
}
