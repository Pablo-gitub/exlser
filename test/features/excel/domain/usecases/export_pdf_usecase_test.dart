import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exel_category/features/excel/domain/entities/excel_data_entity.dart';
import 'package:exel_category/features/excel/domain/repositories/export_repository.dart';
import 'package:exel_category/features/excel/domain/usecases/export_excel_usecase.dart';
import 'package:exel_category/features/excel/domain/usecases/export_pdf_usecase.dart';

class MockExportRepository extends Mock implements ExportRepository {}

void main() {
  late MockExportRepository repo;
  late ExportPdfUseCase usecase;

  setUp(() {
    repo = MockExportRepository();
    usecase = ExportPdfUseCase(repo);
  });

  test('should export to pdf via repository', () async {
    final data = [
      const ExcelDataEntity(values: {'A': 1})
    ];
    final columns = ['A'];

    when(() => repo.exportToPdf(data, columns))
        .thenAnswer((_) async {});

    await usecase(ExportParams(filteredData: data, columnOrder: columns));

    verify(() => repo.exportToPdf(data, columns)).called(1);
  });
}
