import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/presentation/providers/immersive_mode_provider.dart';
import 'package:exlser/presentation/views/settings/settings_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpSettings(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: UncontrolledProviderScope(
          container: container,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const Scaffold(
                body: SettingsView(),
              ),
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows and toggles full immersion only on Android',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    try {
      await _pumpSettings(tester, container: container);

      expect(find.text('Full immersion'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(container.read(immersiveModeProvider), isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(container.read(immersiveModeProvider), isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('hides full immersion outside Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    try {
      await _pumpSettings(tester, container: container);

      expect(find.text('Full immersion'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
