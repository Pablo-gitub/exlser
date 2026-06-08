import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global router state provider.
///
/// Used by GoRouter to refresh redirects when:
/// - splash flow completes
/// - onboarding completes
///
/// Future extensions:
/// - persisted startup preferences
/// - auth / session guards
/// - active dataset state
final routerNotifierProvider = Provider<RouterNotifier>(
  (ref) => RouterNotifier(),
);

/// Router state holder used by GoRouter redirects.
///
/// Responsibilities:
/// - splash completion state
/// - onboarding completion state
///
/// This notifier should remain lightweight and focused only
/// on global navigation guards.
class RouterNotifier extends ChangeNotifier {
  bool _isSplashCompleted = false;
  bool _isOnboardingCompleted = false;

  bool get isSplashCompleted => _isSplashCompleted;

  bool get isOnboardingCompleted => _isOnboardingCompleted;

  /// Marks splash initialization as completed.
  void completeSplash() {
    if (_isSplashCompleted) return;

    _isSplashCompleted = true;
    notifyListeners();
  }

  /// Marks onboarding as completed.
  void completeOnboarding() {
    if (_isOnboardingCompleted) return;

    _isOnboardingCompleted = true;
    notifyListeners();
  }

  /// Sets initial persisted router state.
  ///
  /// Future use:
  /// - restore onboarding completion
  /// - restore startup flags
  void setInitialState({
    required bool isSplashCompleted,
    required bool isOnboardingCompleted,
  }) {
    _isSplashCompleted = isSplashCompleted;
    _isOnboardingCompleted = isOnboardingCompleted;

    notifyListeners();
  }
}
