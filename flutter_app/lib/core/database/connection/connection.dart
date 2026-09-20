// lib/core/database/connection/connection.dart

import 'package:drift/drift.dart';
import 'package:exlser/core/database/connection/web_database_status.dart';
import 'package:flutter/foundation.dart';

import 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart' as impl;

/// Opens the database connection.
///
/// This file acts as the entry point for selecting the correct
/// database implementation depending on the platform.
///
/// - Mobile/Desktop → SQLite file
/// - Web → WASM SQLite
QueryExecutor openConnection() {
  return impl.openConnectionImpl();
}

/// How the database was opened in a browser, or null on every other platform
/// and before the first query opens it.
ValueListenable<WebDatabaseStatus?> get webDatabaseStatus =>
    impl.webDatabaseStatus;
