import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/router_notifier.dart';

final onboardingViewModelProvider = Provider.autoDispose<OnboardingViewModel>(
  // The router notifier is resolved here, while the provider's Ref is alive.
  // Holding the Ref and reading through it later broke the flow: the view reads
  // this provider once, without watching it, so the autoDispose Ref is gone by
  // the time onboarding completes.
  (ref) => OnboardingViewModel(ref.read(routerNotifierProvider)),
);

enum OnboardingMediaType {
  image,
  video,
}

class OnboardingPageData {
  final String titleKey;
  final String assetPath;
  final OnboardingMediaType mediaType;

  const OnboardingPageData({
    required this.titleKey,
    required this.assetPath,
    required this.mediaType,
  });
}

/// ViewModel responsible for onboarding flow.
///
/// Responsibilities:
/// - manage onboarding page navigation
/// - expose current page state
/// - notify router when onboarding completes
class OnboardingViewModel {
  final RouterNotifier router;

  late final PageController pageController;

  final List<OnboardingPageData> pages = const [
    OnboardingPageData(
      titleKey: 'onboarding.welcome.title',
      assetPath: 'assets/images/logo_full_tagline_high.png',
      mediaType: OnboardingMediaType.image,
    ),
    OnboardingPageData(
      titleKey: 'onboarding.data.title',
      assetPath: 'assets/preview_exlser.mp4',
      mediaType: OnboardingMediaType.video,
    ),
    OnboardingPageData(
      titleKey: 'onboarding.cross_platform.title',
      assetPath: 'assets/exlser_crossplatform.png',
      mediaType: OnboardingMediaType.image,
    ),
  ];

  int currentPage = 0;

  OnboardingViewModel(this.router) {
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
    router.completeOnboarding();
  }

  void dispose() {
    pageController.dispose();
  }
}
