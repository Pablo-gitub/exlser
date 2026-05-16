import 'package:exel_category/application/usecases/file/save_uploaded_file_usecase.dart';
import 'package:exel_category/data/adapters/normalizers/boolean_normalizer.dart';
import 'package:exel_category/data/adapters/normalizers/date_normalizer.dart';
import 'package:exel_category/data/adapters/normalizers/number_normalizer.dart';
import 'package:exel_category/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/get_datasets_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exel_category/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exel_category/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exel_category/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exel_category/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exel_category/presentation/providers/database_providers.dart';
import 'package:exel_category/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final numberNormalizerProvider = Provider<NumberNormalizer>((ref) {
  return NumberNormalizer();
});

final dateNormalizerProvider = Provider<DateNormalizer>((ref) {
  return DateNormalizer();
});

final booleanNormalizerProvider = Provider<BooleanNormalizer>((ref) {
  return BooleanNormalizer();
});

final inferSchemaUseCaseProvider = Provider<InferSchemaUseCase>((ref) {
  return InferSchemaUseCase(
    numberNormalizer: ref.watch(numberNormalizerProvider),
    dateNormalizer: ref.watch(dateNormalizerProvider),
    booleanNormalizer: ref.watch(booleanNormalizerProvider),
  );
});

final saveUploadedFileUseCaseProvider =
    Provider<SaveUploadedFileUseCase>((ref) {
  return SaveUploadedFileUseCase(
    datasource: ref.watch(fileDatasourceProvider),
  );
});

final createDatasetUseCaseProvider = Provider<CreateDatasetUseCase>((ref) {
  return CreateDatasetUseCase(
    repository: ref.watch(datasetsRepositoryProvider),
  );
});

final registerDatasetFileUseCaseProvider =
    Provider<RegisterDatasetFileUseCase>((ref) {
  return RegisterDatasetFileUseCase(
    repository: ref.watch(datasetFileRepositoryProvider),
  );
});

final getDatasetsUseCaseProvider = Provider<GetDatasetsUseCase>((ref) {
  return GetDatasetsUseCase(
    repository: ref.watch(datasetsRepositoryProvider),
  );
});

final deleteDatasetUseCaseProvider = Provider<DeleteDatasetUseCase>((ref) {
  return DeleteDatasetUseCase(
    datasetsRepository: ref.watch(datasetsRepositoryProvider),
    schemaRepository: ref.watch(schemaRepositoryProvider),
    datasetFileRepository: ref.watch(datasetFileRepositoryProvider),
  );
});

final createDatasetTableUseCaseProvider =
    Provider<CreateDatasetTableUseCase>((ref) {
  return CreateDatasetTableUseCase(
    repository: ref.watch(schemaRepositoryProvider),
  );
});

final registerColumnsUseCaseProvider = Provider<RegisterColumnsUseCase>((ref) {
  return RegisterColumnsUseCase(
    repository: ref.watch(schemaRepositoryProvider),
  );
});

final buildDynamicTableUseCaseProvider =
    Provider<BuildDynamicTableUseCase>((ref) {
  return BuildDynamicTableUseCase(
    repository: ref.watch(schemaRepositoryProvider),
  );
});

final insertRowsUseCaseProvider = Provider<InsertRowsUseCase>((ref) {
  return InsertRowsUseCase(
    ref.watch(queryRepositoryProvider),
  );
});

final fetchRowsUseCaseProvider = Provider<FetchRowsUseCase>((ref) {
  return FetchRowsUseCase(
    repository: ref.watch(queryRepositoryProvider),
  );
});
