import 'package:flutter/foundation.dart';

/// Router state holder used by GoRouter redirects.
///
/// For now it manages only:
/// - splash completion
/// - onboarding completion
///
/// In the future it can be extended with:
/// - active dataset state
/// - navigation guards
/// - restoration / persisted routing state
class RouterNotifier extends ChangeNotifier {
  bool _isSplashCompleted = false;
  bool _isOnboardingCompleted = false;

  bool get isSplashCompleted => _isSplashCompleted;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  void completeSplash() {
    if (_isSplashCompleted) return;
    _isSplashCompleted = true;
    notifyListeners();
  }

  void completeOnboarding() {
    if (_isOnboardingCompleted) return;
    _isOnboardingCompleted = true;
    notifyListeners();
  }

  /// Optional utility for bootstrapping persisted preferences later.
  void setInitialState({
    required bool isSplashCompleted,
    required bool isOnboardingCompleted,
  }) {
    _isSplashCompleted = isSplashCompleted;
    _isOnboardingCompleted = isOnboardingCompleted;
    notifyListeners();
  }
}