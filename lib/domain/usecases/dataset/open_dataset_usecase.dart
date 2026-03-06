/// Marks a dataset as opened and retrieves its metadata.
///
/// Used when a user selects an existing dataset from the UI.
///
/// Responsibilities:
/// - update lastOpenedAt timestamp
/// - retrieve dataset metadata
///
/// Dependencies:
/// - DatasetsRepository
///
/// Expected flow:
/// 1. Receive datasetId
/// 2. Call repository.markDatasetOpened(datasetId)
/// 3. Retrieve dataset metadata
/// 4. Return Dataset entity
class OpenDatasetUseCase {

  // TODO:
  // - inject DatasetsRepository
  // - implement call(datasetId)
  // - update lastOpenedAt timestamp
  // - retrieve dataset entity

}