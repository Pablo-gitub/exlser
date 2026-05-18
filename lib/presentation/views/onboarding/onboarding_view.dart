import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_viewmodel.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  late final OnboardingViewModel viewModel;

  @override
  void initState() {
    super.initState();

    viewModel = ref.read(onboardingViewModelProvider);
  }

  @override
  void dispose() {
    viewModel.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = viewModel.isLastPage;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: viewModel.completeOnboarding,
            child: Text(
              AppStrings.skip.tr(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: viewModel.pageController,
                itemCount: viewModel.pages.length,
                onPageChanged: (index) {
                  setState(() {
                    viewModel.onPageChanged(index);
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: Text(
                      viewModel.pages[index],
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: viewModel.canGoBack
                      ? () async {
                          await viewModel.previousPage();

                          setState(() {});
                        }
                      : null,
                  child: Text(
                    AppStrings.previous.tr(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await viewModel.nextPage();

                    setState(() {});
                  },
                  child: Text(
                    isLastPage ? AppStrings.start.tr() : AppStrings.next.tr(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
