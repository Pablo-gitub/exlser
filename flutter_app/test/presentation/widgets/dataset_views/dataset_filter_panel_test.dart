import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/presentation/widgets/dataset_views/dataset_filter_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('DatasetFilterPanel', () {
    testWidgets('adapts filter controls to narrow widths', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _LocalizedTestApp(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DatasetFilterPanel(
                columns: [
                  _column(
                    originalName: 'Price',
                    dbName: 'price',
                    type: ColumnType.real,
                  ),
                ],
                rows: const [
                  {'price': 1.5},
                  {'price': 42.8},
                ],
                filters: const [],
                onAddFilter: (_) {},
                onRemoveFilter: (_) {},
                onClearFilters: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Range'), findsOneWidget);
    });
  });
}

class _LocalizedTestApp extends StatelessWidget {
  final Widget child;

  const _LocalizedTestApp({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: child,
          );
        },
      ),
    );
  }
}

DatasetColumn _column({
  required String originalName,
  required String dbName,
  required ColumnType type,
}) {
  return DatasetColumn(
    id: 1,
    datasetTableId: 1,
    originalName: originalName,
    dbName: dbName,
    declaredType: type,
    inferredType: type,
    nullable: true,
  );
}
