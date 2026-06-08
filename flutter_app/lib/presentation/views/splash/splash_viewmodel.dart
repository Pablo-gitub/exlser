import 'package:exlser/presentation/router/router_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefsResult = await Future.wait([
      Future.delayed(const Duration(milliseconds: 500)),
      SharedPreferences.getInstance(),
    ]);

    final prefs = prefsResult[1] as SharedPreferences;
    final isOnboardingCompleted =
        prefs.getBool('onboarding_completed') ?? false;

    ref.read(routerNotifierProvider).setInitialState(
          isSplashCompleted: true,
          isOnboardingCompleted: isOnboardingCompleted,
        );
  }
}
