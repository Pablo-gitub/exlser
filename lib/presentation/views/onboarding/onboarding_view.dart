import 'package:flutter/material.dart';
import 'onboarding_viewmodel.dart';

/// Onboarding view displayed when the app is opened for the first time.
///
/// This view introduces the main features of the application through
/// a sequence of slides.
///
/// Planned slides:
/// 1. Import Excel/CSV file
/// 2. Confirm schema and column types
/// 3. Apply filters and analyze data
/// 4. Export results
///
/// This onboarding should be shown only once and skipped on
/// subsequent launches.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {

  late OnboardingViewModel viewModel;

  @override
  void initState() {
    super.initState();

    /// TODO:
    /// Initialize onboarding view model.
    viewModel = OnboardingViewModel();
  }

  @override
  Widget build(BuildContext context) {

    /// TODO:
    /// Implement PageView with onboarding slides.
    ///
    /// Each slide will show:
    /// - image or gif
    /// - short explanation text

    return const Scaffold(
      body: Placeholder(),
    );
  }
}