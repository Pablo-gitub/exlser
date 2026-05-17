import 'package:exel_category/application/dto/import_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

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
  bool get hasFile {
    final hasName = selectedFileName?.trim().isNotEmpty ?? false;
    final hasPath = selectedFilePath?.trim().isNotEmpty ?? false;
    final hasBytes = selectedFileBytes?.isNotEmpty ?? false;

    return hasName && (hasPath || hasBytes);
  }

  /// Dataset name suggested from the selected file name.
  String get suggestedDatasetName {
    final fileName = selectedFileName?.trim();

    if (fileName == null || fileName.isEmpty) {
      return 'dataset';
    }

    final extensionIndex = fileName.lastIndexOf('.');
    final baseName =
        extensionIndex > 0 ? fileName.substring(0, extensionIndex) : fileName;
    final normalizedBaseName = baseName.trim();

    return normalizedBaseName.isEmpty ? 'dataset' : normalizedBaseName;
  }

  /// Converts the current UI selection into the application import DTO.
  ImportFile? get selectedImportFile {
    final fileName = selectedFileName?.trim();

    if (fileName == null || fileName.isEmpty) {
      return null;
    }

    final path = selectedFilePath?.trim();
    if (path != null && path.isNotEmpty) {
      return ImportFile.fromPath(
        fileName: fileName,
        path: path,
      );
    }

    final bytes = selectedFileBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ImportFile.fromBytes(
        fileName: fileName,
        bytes: bytes,
      );
    }

    return null;
  }

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
      withData: kIsWeb,
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
}
