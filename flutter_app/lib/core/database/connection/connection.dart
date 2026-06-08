// lib/core/database/connection/connection.dart

import 'package:drift/drift.dart';

import 'connection_native.dart' if (dart.library.html) 'connection_web.dart';

/// Opens the database connection.
///
/// This file acts as the entry point for selecting the correct
/// database implementation depending on the platform.
///
/// - Mobile/Desktop → SQLite file
/// - Web → WASM SQLite
QueryExecutor openConnection() {
  return openConnectionImpl();
}
