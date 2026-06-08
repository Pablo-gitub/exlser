import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/usecases/query/get_distinct_values_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  group('GetDistinctValuesUseCase', () {
    late MockQueryRepository repository;
    late GetDistinctValuesUseCase useCase;

    setUp(() {
      repository = MockQueryRepository();
      useCase = GetDistinctValuesUseCase(repository: repository);
    });

    test('should retrieve distinct values from repository', () async {
      final column = _column();
      final expectedValues = ['book', 'pen'];

      when(() => repository.getDistinctValues(
            tableName: 'products',
            column: column,
          )).thenAnswer((_) async => expectedValues);

      final result = await useCase(
        tableName: 'products',
        column: column,
      );

      expect(result, expectedValues);
      verify(() => repository.getDistinctValues(
            tableName: 'products',
            column: column,
          )).called(1);
    });

    test('should reject empty table names', () {
      expect(
        () => useCase(
          tableName: ' ',
          column: _column(),
        ),
        throwsArgumentError,
      );
    });

    test('should reject empty column db names', () {
      expect(
        () => useCase(
          tableName: 'products',
          column: _column(dbName: ' '),
        ),
        throwsArgumentError,
      );
    });
  });
}

DatasetColumn _column({
  String dbName = 'product',
}) {
  return DatasetColumn(
    id: 0,
    datasetTableId: 0,
    originalName: dbName,
    dbName: dbName,
    declaredType: ColumnType.text,
    inferredType: ColumnType.text,
    nullable: true,
  );
}
