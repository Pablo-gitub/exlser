import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/router_notifier.dart';

final onboardingViewModelProvider = Provider.autoDispose<OnboardingViewModel>(
  (ref) => OnboardingViewModel(ref),
);

/// ViewModel responsible for onboarding flow.
///
/// Responsibilities:
/// - manage onboarding page navigation
/// - expose current page state
/// - notify router when onboarding completes
class OnboardingViewModel {
  final Ref ref;

  late final PageController pageController;

  final List<String> pages = [
    'Here I will create first onboarding',
    'Here I will create second onboarding',
    'Here I will create third onboarding',
    'Here I will create fourth onboarding',
  ];

  int currentPage = 0;

  OnboardingViewModel(this.ref) {
    pageController = PageController();
  }

  bool get isLastPage => currentPage == pages.length - 1;

  bool get canGoBack => currentPage > 0;

  void onPageChanged(int index) {
    currentPage = index;
  }

  Future<void> nextPage() async {
    if (!isLastPage) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await completeOnboarding();
    }
  }

  Future<void> previousPage() async {
    if (!canGoBack) return;

    await pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    ref.read(routerNotifierProvider).completeOnboarding();
  }

  void dispose() {
    pageController.dispose();
  }
}
