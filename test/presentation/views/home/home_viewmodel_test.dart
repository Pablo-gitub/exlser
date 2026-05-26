import 'dart:typed_data';

import 'package:exlser/presentation/views/home/home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeViewModel', () {
    test('should create path import file from selected path file', () {
      final viewModel = HomeViewModel()
        ..setSelectedFile(
          name: 'sales.xlsx',
          path: '/tmp/sales.xlsx',
        );

      final file = viewModel.selectedImportFile;

      expect(viewModel.hasFile, isTrue);
      expect(viewModel.suggestedDatasetName, 'sales');
      expect(file?.fileName, 'sales.xlsx');
      expect(file?.path, '/tmp/sales.xlsx');
      expect(file?.bytes, isNull);
    });

    test('should create bytes import file from selected bytes file', () {
      final viewModel = HomeViewModel()
        ..setSelectedFile(
          name: 'sales.csv',
          bytes: Uint8List.fromList([1, 2, 3]),
        );

      final file = viewModel.selectedImportFile;

      expect(viewModel.hasFile, isTrue);
      expect(viewModel.suggestedDatasetName, 'sales');
      expect(file?.fileName, 'sales.csv');
      expect(file?.path, isNull);
      expect(file?.bytes, [1, 2, 3]);
    });

    test('should prefer path import file when path and bytes are present', () {
      final viewModel = HomeViewModel()
        ..setSelectedFile(
          name: 'sales.csv',
          path: '/tmp/sales.csv',
          bytes: Uint8List.fromList([1, 2, 3]),
        );

      final file = viewModel.selectedImportFile;

      expect(file?.path, '/tmp/sales.csv');
      expect(file?.bytes, isNull);
    });

    test('should return null import file when selection is incomplete', () {
      final viewModel = HomeViewModel()
        ..setSelectedFile(
          name: 'sales.csv',
        );

      expect(viewModel.hasFile, isFalse);
      expect(viewModel.selectedImportFile, isNull);
    });

    test('should clear selected file', () {
      final viewModel = HomeViewModel()
        ..setSelectedFile(
          name: 'sales.csv',
          bytes: Uint8List.fromList([1, 2, 3]),
        );

      viewModel.clearSelection();

      expect(viewModel.hasFile, isFalse);
      expect(viewModel.selectedFileName, isNull);
      expect(viewModel.selectedFilePath, isNull);
      expect(viewModel.selectedFileBytes, isNull);
      expect(viewModel.selectedImportFile, isNull);
    });
  });
}
