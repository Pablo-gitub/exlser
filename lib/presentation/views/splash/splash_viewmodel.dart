import 'package:exel_category/presentation/router/router_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashViewModelProvider = Provider<SplashViewModel>(
  (ref) => SplashViewModel(ref),
);

/// ViewModel responsible for lightweight application startup.
///
/// Responsibilities:
/// - Initialize essential services
/// - Prepare app startup state
/// - Notify router when splash flow is complete
///
/// This ViewModel must remain lightweight:
/// no heavy data loading should happen here.
class SplashViewModel {
  final Ref ref;

  SplashViewModel(this.ref);

  /// Initializes the minimal application startup flow.
  ///
  /// Current responsibilities:
  /// - wait for splash transition
  /// - notify router
  ///
  /// Future responsibilities:
  /// - initialize Drift database
  /// - initialize dependency container
  /// - load user preferences
  /// - load theme / locale settings
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));

    ref.read(routerNotifierProvider).completeSplash();
  }
}
