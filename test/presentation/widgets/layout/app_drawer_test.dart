import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/presentation/providers/immersive_mode_provider.dart';
import 'package:exlser/presentation/router/routes.dart';
import 'package:exlser/presentation/widgets/layout/app_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GoRouter _makeRouter(String initialPath) => GoRouter(
      initialLocation: initialPath,
      routes: [
        GoRoute(
          path: AppRoutes.homePath,
          builder: (_, __) => const _DrawerHost(),
        ),
        GoRoute(
          path: AppRoutes.datasetListPath,
          builder: (_, __) => const _DrawerHost(),
        ),
        GoRoute(
          path: AppRoutes.settingsPath,
          builder: (_, __) => const _DrawerHost(),
        ),
      ],
    );

// AppBar auto-inserts a DrawerButton (Icons.menu) when a drawer is present.
// We tap that icon in _openDrawer() instead of relying on GlobalKey or
// find.byType(Scaffold) which may match multiple widgets.
class _DrawerHost extends StatelessWidget {
  const _DrawerHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: const AppDrawer(),
      body: const SizedBox.shrink(),
    );
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required GoRouter router,
  List<Override> overrides = const [],
}) async {
  // Clear previous tree to avoid GlobalKey conflicts between tests.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  // EasyLocalization loads translations via rootBundle (a real platform channel
  // in widget tests). pumpAndSettle() only advances fake timers, so we need
  // tester.runAsync() to let the real async load complete before settling.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: ProviderScope(
          overrides: overrides,
          child: Builder(
            builder: (context) => MaterialApp.router(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              routerConfig: router,
            ),
          ),
        ),
      ),
    );
    // Allow the asset load future to actually complete.
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

Future<void> _openDrawer(WidgetTester tester) async {
  // Use the ScaffoldState directly — more reliable than tapping Icons.menu
  // (the hamburger may not be rendered in wide viewports or before the
  // localization delegate finishes loading on slower machines).
  tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// IMPORTANT: debugDefaultTargetPlatformOverride must be reset INSIDE the test
// body using try/finally, not in tearDown.
// Reason: Flutter's _verifyInvariants() fires AFTER the test body but BEFORE
// tearDown callbacks, so any non-null value left at that point fails the test.
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // ── Layout tests ─────────────────────────────────────────────────────────────

  group('AppDrawer — layout', () {
    testWidgets('portrait (Pixel 6): nav and footer visible, no overflow',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await _pumpApp(tester, router: _makeRouter(AppRoutes.homePath));
        await _openDrawer(tester);

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Works'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Developer'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('landscape (Pixel 6 ~411dp height): no overflow, footer visible',
        (tester) async {
      // This is the regression case: footer (~200dp) + immersive toggle (~90dp)
      // + nav (~190dp) > body height (~355dp). Previously caused overflow.
      // Expanded>SingleChildScrollView for nav keeps footer always in view.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(2400, 1080);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await _pumpApp(tester, router: _makeRouter(AppRoutes.homePath));
        await _openDrawer(tester);

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Works'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Developer'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('extreme landscape (360px): no overflow', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await _pumpApp(tester, router: _makeRouter(AppRoutes.homePath));
        await _openDrawer(tester);

        expect(find.text('Home'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('iOS portrait: no overflow, no Switch', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await _pumpApp(tester, router: _makeRouter(AppRoutes.homePath));
        await _openDrawer(tester);

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Developer'), findsOneWidget);
        expect(find.byType(Switch), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  // ── Immersive toggle ─────────────────────────────────────────────────────────

  group('AppDrawer — immersive toggle', () {
    testWidgets('Switch visible on Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await _pumpApp(tester, router: _makeRouter(AppRoutes.homePath));
        await _openDrawer(tester);

        expect(find.byType(Switch), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('tapping Switch toggles immersiveModeProvider', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      try {
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
                  builder: (context) => MaterialApp.router(
                    locale: context.locale,
                    supportedLocales: context.supportedLocales,
                    localizationsDelegates: context.localizationDelegates,
                    routerConfig: _makeRouter(AppRoutes.homePath),
                  ),
                ),
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
        await _openDrawer(tester);

        expect(container.read(immersiveModeProvider), isFalse);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(container.read(immersiveModeProvider), isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  // ── Active route highlight ───────────────────────────────────────────────────

  group('AppDrawer — active route highlight', () {
    testWidgets('Home tile selected on /home, Works tile not selected',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await _pumpApp(tester, router: _makeRouter(AppRoutes.homePath));
        await _openDrawer(tester);

        final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
        final homeTile = tiles.firstWhere(
          (t) => t.title is Text && (t.title as Text).data == 'Home',
        );
        final worksTile = tiles.firstWhere(
          (t) => t.title is Text && (t.title as Text).data == 'Works',
        );

        expect(homeTile.selected, isTrue);
        expect(worksTile.selected, isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
