/// Persists column metadata for a dataset table.
///
/// Columns are inferred from the imported dataset and then stored
/// as metadata in the database.
///
/// Responsibilities:
/// - receive inferred columns
/// - attach them to a dataset table
/// - persist them through SchemaRepository
///
/// Dependencies:
/// - SchemaRepository
///
/// Expected flow:
/// 1. Receive tableId and inferred columns
/// 2. associate columns with datasetTableId
/// 3. persist column metadata via repository
class RegisterColumnsUseCase {

  // TODO:
  // - inject SchemaRepository
  // - assign datasetTableId to columns
  // - persist column list via repository

}