import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/get_datasets_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exel_category/presentation/views/dataset_list/datasets_list_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDatasetsUseCase extends Mock implements GetDatasetsUseCase {}

class MockOpenDatasetUseCase extends Mock implements OpenDatasetUseCase {}

class MockDeleteDatasetUseCase extends Mock implements DeleteDatasetUseCase {}

void main() {
  group('DatasetsListViewModel', () {
    late MockGetDatasetsUseCase getDatasets;
    late MockOpenDatasetUseCase openDataset;
    late MockDeleteDatasetUseCase deleteDataset;
    late DatasetsListViewModel viewModel;

    setUp(() {
      getDatasets = MockGetDatasetsUseCase();
      openDataset = MockOpenDatasetUseCase();
      deleteDataset = MockDeleteDatasetUseCase();
      viewModel = DatasetsListViewModel(
        getDatasets: getDatasets,
        openDataset: openDataset,
        deleteDataset: deleteDataset,
      );
    });

    test('should load datasets', () async {
      final datasets = [
        _dataset(id: 1, name: 'Sales'),
        _dataset(id: 2, name: 'Inventory'),
      ];
      when(() => getDatasets.call()).thenAnswer((_) async => datasets);

      await viewModel.loadDatasets();

      expect(viewModel.datasets, datasets);
      expect(viewModel.hasDatasets, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorCode, isNull);
    });

    test('should expose load error', () async {
      when(() => getDatasets.call()).thenThrow(Exception('load failed'));

      await viewModel.loadDatasets();

      expect(viewModel.datasets, isEmpty);
      expect(viewModel.errorCode, 'load_failed');
      expect(viewModel.isLoading, isFalse);
    });

    test('should open dataset and update cached item', () async {
      final dataset = _dataset(id: 1, lastOpenedAt: null);
      final openedDataset = dataset.copyWith(lastOpenedAt: 2000);
      when(() => getDatasets.call()).thenAnswer((_) async => [dataset]);
      when(() => openDataset.call(1)).thenAnswer((_) async => openedDataset);

      await viewModel.loadDatasets();
      final openedDatasetId = await viewModel.openDataset(1);

      expect(openedDatasetId, 1);
      expect(viewModel.datasets.single.lastOpenedAt, 2000);
      expect(viewModel.openingDatasetId, isNull);
      expect(viewModel.isOpening, isFalse);
      expect(viewModel.errorCode, isNull);
    });

    test('should expose open error', () async {
      when(() => openDataset.call(1)).thenThrow(Exception('open failed'));

      final openedDatasetId = await viewModel.openDataset(1);

      expect(openedDatasetId, isNull);
      expect(viewModel.errorCode, 'open_failed');
      expect(viewModel.isOpening, isFalse);
    });

    test('should delete dataset and remove it from cache', () async {
      final datasets = [
        _dataset(id: 1, name: 'Sales'),
        _dataset(id: 2, name: 'Inventory'),
      ];
      when(() => getDatasets.call()).thenAnswer((_) async => datasets);
      when(() => deleteDataset.call(1)).thenAnswer((_) async {});

      await viewModel.loadDatasets();
      await viewModel.deleteDataset(1);

      expect(viewModel.datasets.map((dataset) => dataset.id), [2]);
      expect(viewModel.deletingDatasetId, isNull);
      expect(viewModel.errorCode, isNull);
    });

    test('should expose delete error', () async {
      when(() => deleteDataset.call(1)).thenThrow(Exception('delete failed'));

      await viewModel.deleteDataset(1);

      expect(viewModel.errorCode, 'delete_failed');
      expect(viewModel.deletingDatasetId, isNull);
    });
  });
}

Dataset _dataset({
  required int id,
  String name = 'Dataset',
  int? lastOpenedAt,
}) {
  return Dataset(
    id: id,
    name: name,
    sourceFileName: '$name.csv',
    createdAt: 1000,
    lastOpenedAt: lastOpenedAt,
  );
}
