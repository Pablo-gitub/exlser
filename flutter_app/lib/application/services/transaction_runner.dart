/// Abstraction over database transaction support.
///
/// Allows application services to run a sequence of operations atomically
/// without depending on a specific database implementation.
///
/// If any operation inside [run] throws, the transaction is rolled back
/// and no partial writes are visible.
abstract class TransactionRunner {
  Future<T> run<T>(Future<T> Function() action);
}
