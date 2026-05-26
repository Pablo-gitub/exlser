import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  group('FetchRowsUseCase', () {
    late MockQueryRepository repository;
    late FetchRowsUseCase useCase;

    setUp(() {
      repository = MockQueryRepository();
      useCase = FetchRowsUseCase(repository: repository);
    });

    test('should fetch rows from repository with given parameters', () async {
      /// Arrange
      const tableName = 'test_table';
      const limit = 10;
      const offset = 5;

      final expectedRows = [
        {'id': 1, 'name': 'Item 1'},
        {'id': 2, 'name': 'Item 2'},
      ];

      when(() => repository.fetchRows(
            tableName: any(named: 'tableName'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => expectedRows);

      /// Act
      final result = await useCase(
        tableName: tableName,
        limit: limit,
        offset: offset,
      );

      /// Assert
      expect(result, equals(expectedRows));
      verify(() => repository.fetchRows(
            tableName: tableName,
            limit: limit,
            offset: offset,
          )).called(1);
    });
  });
}
