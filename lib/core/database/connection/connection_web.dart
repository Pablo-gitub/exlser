// lib/core/database/connection/connection_web.dart

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens the Drift database on the web using SQLite WASM.
///
/// Required static assets in `web/`:
/// - sqlite3.wasm
/// - drift_worker.dart.js
///
/// The database is stored persistently using IndexedDB.
QueryExecutor openConnectionImpl() {
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'excel_category',

      // Path to the SQLite WASM binary
      sqlite3Uri: Uri.parse('sqlite3.wasm'),

      // Web worker used by Drift to run SQLite off the main thread
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    return db.resolvedExecutor;
  });
}
