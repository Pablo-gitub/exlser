import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:exel_category/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('should insert and retrieve a dataset', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert dataset
    final id = await database.into(database.datasets).insert(
          DatasetsCompanion.insert(
            name: 'Test Dataset',
            sourceFileName: 'test.xlsx',
            createdAt: now,
          ),
        );

    // Retrieve dataset
    final result = await (database.select(database.datasets)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    expect(result.name, 'Test Dataset');
  });
}
