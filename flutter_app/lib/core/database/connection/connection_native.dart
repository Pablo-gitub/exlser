// lib/core/database/connection/connection_native.dart

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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
