import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exel_category/core/usecases/usecase.dart';
import 'package:exel_category/features/excel/domain/entities/excel_data_entity.dart';
import 'package:exel_category/features/excel/domain/repositories/excel_repository.dart';
import 'package:exel_category/features/excel/domain/usecases/read_excel_usecase.dart';

class MockExcelRepository extends Mock implements ExcelRepository {}

void main() {
  late MockExcelRepository repo;
  late ReadExcelUseCase usecase;

  setUp(() {
    repo = MockExcelRepository();
    usecase = ReadExcelUseCase(repo);
  });

  test('should read excel file via repository', () async {
    final fakeData = [
      const ExcelDataEntity(values: {'A': 1})
    ];

    when(() => repo.readExcelFile()).thenAnswer((_) async => fakeData);

    final result = await usecase(const NoParams());

    expect(result, fakeData);
    verify(() => repo.readExcelFile()).called(1);
    verifyNoMoreInteractions(repo);
  });
}
