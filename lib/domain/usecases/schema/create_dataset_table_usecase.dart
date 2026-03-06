/// Creates metadata for a dataset table.
///
/// A dataset table corresponds to one sheet (or logical table)
/// extracted from an imported file.
///
/// Responsibilities:
/// - create DatasetTable entity
/// - persist table metadata
///
/// Dependencies:
/// - SchemaRepository
///
/// Expected flow:
/// 1. Receive datasetId and sheet name
/// 2. Generate SQL-safe table name
/// 3. Create DatasetTable entity
/// 4. Persist metadata using repository
/// 5. Return created DatasetTable
class CreateDatasetTableUseCase {

  // TODO:
  // - inject SchemaRepository
  // - generate sqlTableName from sheet name
  // - create DatasetTable entity
  // - persist metadata via repository
  // - return created DatasetTable

}