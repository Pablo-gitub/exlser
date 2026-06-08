import 'package:exlser/application/services/transaction_runner.dart';
import 'package:exlser/data/datasources/drift_datasource.dart';

/// Drift-backed implementation of [TransactionRunner].
class DriftTransactionRunner implements TransactionRunner {
  final DriftDatasource _datasource;

  DriftTransactionRunner(this._datasource);

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    late T result;
    await _datasource.runInTransaction(() async {
      result = await action();
    });
    return result;
  }
}
