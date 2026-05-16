import 'package:exel_category/application/services/create_dataset_service.dart';
import 'package:exel_category/application/services/import_data_service.dart';
import 'package:exel_category/data/adapters/parsers/parser_factory.dart';
import 'package:exel_category/presentation/providers/usecase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final parserFactoryProvider = Provider<ParserFactory>((ref) {
  return ParserFactory();
});

final importDataServiceProvider = Provider<ImportDataService>((ref) {
  return ImportDataService(
    parserFactory: ref.watch(parserFactoryProvider),
    inferSchemaUseCase: ref.watch(inferSchemaUseCaseProvider),
  );
});

final createDatasetServiceProvider = Provider<CreateDatasetService>((ref) {
  return CreateDatasetService(
    createDatasetUseCase: ref.watch(createDatasetUseCaseProvider),
    registerDatasetFileUseCase: ref.watch(registerDatasetFileUseCaseProvider),
    createDatasetTableUseCase: ref.watch(createDatasetTableUseCaseProvider),
    registerColumnsUseCase: ref.watch(registerColumnsUseCaseProvider),
    buildDynamicTableUseCase: ref.watch(buildDynamicTableUseCaseProvider),
    insertRowsUseCase: ref.watch(insertRowsUseCaseProvider),
  );
});
