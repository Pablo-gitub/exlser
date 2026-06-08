import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final immersiveModeProvider =
    StateNotifierProvider<ImmersiveModeNotifier, bool>(
  (ref) => ImmersiveModeNotifier(),
);

class ImmersiveModeNotifier extends StateNotifier<bool> {
  ImmersiveModeNotifier() : super(false);

  void toggle() {
    state = !state;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (state) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
