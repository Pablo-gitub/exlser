// lib/core/database/connection/connection_native.dart

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:exlser/core/database/connection/web_database_status.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the SQLite database file for native platforms.
///
/// The database is stored inside the application's
/// document directory.
///
/// This ensures:
/// - Persistence across app launches
/// - Correct sandbox location on mobile/desktop
QueryExecutor openConnectionImpl() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();

    final file = File(
      p.join(dbFolder.path, 'exlser.sqlite'),
    );

    return NativeDatabase(file);
  });
}

/// Always null off the web: a file on disk has no storage to degrade to.
///
/// Declared here so [webDatabaseStatus] can be read on every platform without
/// the caller knowing which implementation it got.
ValueListenable<WebDatabaseStatus?> get webDatabaseStatus => _status;
final ValueNotifier<WebDatabaseStatus?> _status = ValueNotifier(null);
