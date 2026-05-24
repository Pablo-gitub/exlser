/// Thrown when a chart configuration is invalid (e.g., SUM without Y column).
class InvalidChartConfigException implements Exception {
  final String message;

  InvalidChartConfigException(this.message);

  @override
  String toString() => message;
}
