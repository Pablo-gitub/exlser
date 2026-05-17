import 'dart:async';

import 'package:exel_category/presentation/providers/usecase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'datasets_list_viewmodel.dart';

final datasetsListViewModelProvider =
    ChangeNotifierProvider.autoDispose<DatasetsListViewModel>((ref) {
  final viewModel = DatasetsListViewModel(
    getDatasets: ref.watch(getDatasetsUseCaseProvider),
    openDataset: ref.watch(openDatasetUseCaseProvider),
    deleteDataset: ref.watch(deleteDatasetUseCaseProvider),
  );

  unawaited(viewModel.loadDatasets());

  return viewModel;
});
