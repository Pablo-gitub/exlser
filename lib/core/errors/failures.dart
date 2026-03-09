/// Base class for application failures.
///
/// Failures represent recoverable errors that can be
/// handled by the presentation layer.
abstract class Failure {
  final String message;

  const Failure(this.message);
}