import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'router_notifier.dart';

/// Global GoRouter provider.
///
/// Creates router once and keeps navigation state stable
/// across rebuilds (e.g. locale/theme changes).
final goRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return AppRouter.create(routerNotifier);
});
