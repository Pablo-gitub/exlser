import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShellAction {
  final String id;
  final WidgetBuilder builder;

  const AppShellAction({
    required this.id,
    required this.builder,
  });
}

final appShellActionsProvider =
    StateNotifierProvider<AppShellActionsNotifier, List<AppShellAction>>(
  (ref) => AppShellActionsNotifier(),
);

class AppShellActionsNotifier extends StateNotifier<List<AppShellAction>> {
  AppShellActionsNotifier() : super(const []);

  void setAction(AppShellAction action) {
    state = [
      for (final currentAction in state)
        if (currentAction.id != action.id) currentAction,
      action,
    ];
  }

  void removeAction(String id) {
    state = [
      for (final action in state)
        if (action.id != id) action,
    ];
  }

  void clear() {
    state = const [];
  }
}
