import 'package:exel_category/data/repositories/dataset_file_repository_impl.dart';
import 'package:exel_category/data/repositories/dataset_repository_impl.dart';
import 'package:exel_category/data/repositories/query_repository_impl.dart';
import 'package:exel_category/data/repositories/schema_repository_impl.dart';
import 'package:exel_category/data/schema/dynamic_table_builder.dart';
import 'package:exel_category/domain/repositories/dataset_file_repository.dart';
import 'package:exel_category/domain/repositories/datasets_repository.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/presentation/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dynamicTableBuilderProvider = Provider<DynamicTableBuilder>((ref) {
  return DynamicTableBuilder();
});

final datasetsRepositoryProvider = Provider<DatasetsRepository>((ref) {
  return DatasetsRepositoryImpl(
    dao: ref.watch(datasetsDaoProvider),
  );
});

final datasetFileRepositoryProvider = Provider<DatasetFileRepository>((ref) {
  return DatasetFileRepositoryImpl(
    dao: ref.watch(datasetFilesDaoProvider),
  );
});

final schemaRepositoryProvider = Provider<SchemaRepository>((ref) {
  return SchemaRepositoryImpl(
    ref.watch(driftDatasourceProvider),
    ref.watch(dynamicTableBuilderProvider),
  );
});

final queryRepositoryProvider = Provider<QueryRepository>((ref) {
  return QueryRepositoryImpl(
    ref.watch(driftDatasourceProvider),
  );
});
