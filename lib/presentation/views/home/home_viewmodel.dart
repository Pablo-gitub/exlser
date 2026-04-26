import 'dart:typed_data';
import 'package:exel_category/presentation/views/home/widgets/import_dialog/import_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// ViewModel responsible for the Home screen logic.
///
/// Handles file acquisition for:
/// - mobile/desktop (file picker)
/// - web (drag & drop or manual selection)
class HomeViewModel extends ChangeNotifier {
  /// Selected file name (for UI display).
  String? selectedFileName;

  /// Selected file path (mobile/desktop).
  String? selectedFilePath;

  /// Selected file bytes (web).
  Uint8List? selectedFileBytes;

  /// Indicates loading state (future use).
  bool isLoading = false;

  /// True if a file is selected (web or mobile)
  bool get hasFile => selectedFilePath != null || selectedFileBytes != null;

  /// Unified setter for file selection.
  void setSelectedFile({
    required String name,
    String? path,
    Uint8List? bytes,
  }) {
    selectedFileName = name;
    selectedFilePath = path;
    selectedFileBytes = bytes;

    notifyListeners();
  }

  /// Mobile/Desktop file picker.
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;

    setSelectedFile(
      name: file.name,
      path: file.path,
      bytes: file.bytes,
    );
  }

  /// Web file selection (called from Dropzone).
  void selectFileFromWeb({
    required String name,
    required Uint8List bytes,
  }) {
    setSelectedFile(
      name: name,
      bytes: bytes,
    );
  }

  /// Clears current selection.
  void clearSelection() {
    selectedFileName = null;
    selectedFilePath = null;
    selectedFileBytes = null;

    notifyListeners();
  }

  /// Placeholder for future process logic.
  void processFile(BuildContext context) {
  if (!hasFile) return;

  final initialDatasetName =
      selectedFileName?.split('.').first ?? 'dataset';

  showDialog(
    context: context,
    builder: (_) => ImportDialog(
      initialDatasetName: initialDatasetName,
      onImportCompleted: clearSelection,
    ),
  );
}
}
