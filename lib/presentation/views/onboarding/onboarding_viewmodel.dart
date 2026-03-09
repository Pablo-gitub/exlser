/// ViewModel responsible for onboarding state.
///
/// Responsibilities:
/// - track current onboarding page
/// - persist onboarding completion flag
/// - allow skipping onboarding
class OnboardingViewModel {

  /// Index of the current onboarding page.
  int currentPage = 0;

  /// TODO:
  /// Mark onboarding as completed.
  ///
  /// This should persist a flag so onboarding
  /// is not shown again on next app launches.
  Future<void> completeOnboarding() async {
    throw UnimplementedError();
  }

  /// TODO:
  /// Move to next onboarding page.
  void nextPage() {
    currentPage++;
  }

  /// TODO:
  /// Skip onboarding entirely.
  Future<void> skipOnboarding() async {
    throw UnimplementedError();
  }
}