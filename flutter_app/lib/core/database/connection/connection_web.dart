// lib/core/database/connection/connection_web.dart

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:exlser/core/database/connection/web_database_status.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Raised when the browser cannot provide a database at all.
///
/// Opening the database on the web depends on the browser: the WASM binary has
/// to load, and a worker has to start. When that fails the failure used to
/// escape as whatever the browser threw — a bare `TypeError: Failed to fetch` —
/// which told the user nothing and told the developer even less.
class WebDatabaseUnavailableException implements Exception {
  final Object cause;

  const WebDatabaseUnavailableException(this.cause);

  @override
  String toString() => 'WebDatabaseUnavailableException: $cause';
}

/// The outcome of opening the web database, or null before the first attempt.
///
/// A [ValueListenable] so a widget can react without polling: the database is
/// opened lazily, on the first query, which is long after the first frame.
ValueListenable<WebDatabaseStatus?> get webDatabaseStatus => _status;
final ValueNotifier<WebDatabaseStatus?> _status = ValueNotifier(null);

/// Absolute URL of an asset shipped next to the app.
///
/// Both of these used to be passed relative. Drift hands them to a worker,
/// which resolves what it is given in its own context, so a relative path did
/// not point at the app's assets and every query failed with a bare
/// `TypeError: Failed to fetch`.
///
/// Resolved against the document's base URL rather than [Uri.base]: the demo is
/// served under `/demo/` with a `<base href>`, while [Uri.base] is whatever
/// route the user is on, so `/demo/datasets/3` would look for the WASM binary
/// inside `/demo/datasets/`.
Uri _assetUri(String fileName) {
  final base = Uri.tryParse(web.document.baseURI) ?? Uri.base;
  return base.resolve(fileName);
}

/// Opens the Drift database on the web using SQLite WASM.
///
/// Required static assets in `web/`:
/// - sqlite3.wasm
/// - drift_worker.js
QueryExecutor openConnectionImpl() {
  return LazyDatabase(() async {
    final WasmDatabaseResult result;

    try {
      result = await WasmDatabase.open(
        databaseName: 'exlser',
        sqlite3Uri: _assetUri('sqlite3.wasm'),
        driftWorkerUri: _assetUri('drift_worker.js'),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[exlser] the web database could not be opened: $error');
        debugPrintStack(stackTrace: stackTrace, maxFrames: 20);
      }
      throw WebDatabaseUnavailableException(error);
    }

    _status.value = WebDatabaseStatus(
      durability: switch (result.chosenImplementation) {
        WasmStorageImplementation.inMemory => WebDatabaseDurability.inMemory,
        WasmStorageImplementation.unsafeIndexedDb =>
          WebDatabaseDurability.unreliable,
        _ => WebDatabaseDurability.persistent,
      },
      implementation: result.chosenImplementation.name,
      missingFeatures: [
        for (final feature in result.missingFeatures) feature.name,
      ],
    );

    if (kDebugMode) {
      debugPrint(
        '[exlser] web database storage: ${result.chosenImplementation.name}'
        '${result.missingFeatures.isEmpty ? '' : ', missing browser features: '
            '${result.missingFeatures.map((f) => f.name).join(', ')}'}',
      );
    }

    return result.resolvedExecutor;
  });
}
