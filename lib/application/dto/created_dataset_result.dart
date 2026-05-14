/// Result returned after a dataset has been fully created.
///
/// The UI uses this DTO to navigate to the real dataset id and to show
/// completion feedback without querying the database again.
class CreatedDatasetResult {
  final int datasetId;
  final String datasetName;
  final String sourceFileName;
  final int tableCount;
  final int columnCount;
  final int rowCount;

  const CreatedDatasetResult({
    required this.datasetId,
    required this.datasetName,
    required this.sourceFileName,
    required this.tableCount,
    required this.columnCount,
    required this.rowCount,
  });
}
