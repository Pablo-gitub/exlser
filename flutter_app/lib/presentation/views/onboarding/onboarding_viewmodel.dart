import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/router_notifier.dart';

final onboardingViewModelProvider = Provider.autoDispose<OnboardingViewModel>(
  (ref) => OnboardingViewModel(ref),
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
  final Ref ref;

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
