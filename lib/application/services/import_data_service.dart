/// Handles the pre-commit import flow:
/// 1. Save or reference uploaded file
/// 2. Detect file type
/// 3. Resolve parser
/// 4. Parse raw rows / sheets
/// 5. Infer schema for each parsed sheet
///
/// This service must NOT create persistent datasets/tables/rows.
/// That responsibility belongs to CreateDatasetService after user confirmation.
class ImportDataService {
  const ImportDataService();

  Future<void> prepareImport() async {
    // TODO:
    // 1. Save or reference uploaded file
    // 2. Detect file type
    // 3. Get parser from ParserFactory
    // 4. Parse raw rows / sheets
    // 5. Infer schema for each parsed sheet
    throw UnimplementedError();
  }
}