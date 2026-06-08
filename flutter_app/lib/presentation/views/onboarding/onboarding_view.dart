import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

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
            onPressed: () async => viewModel.completeOnboarding(),
            child: Text(
              AppStrings.skip.tr(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
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
                    return OnboardingPage(
                      page: viewModel.pages[index],
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
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData page;

  const OnboardingPage({
    required this.page,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaHeight =
              (constraints.maxHeight * 0.68).clamp(220.0, 520.0);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: mediaHeight,
                width: double.infinity,
                child: OnboardingMedia(page: page),
              ),
              const SizedBox(height: 28),
              Text(
                page.titleKey.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class OnboardingMedia extends StatelessWidget {
  final OnboardingPageData page;

  const OnboardingMedia({
    required this.page,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (page.mediaType) {
      case OnboardingMediaType.image:
        return Image.asset(
          page.assetPath,
          fit: BoxFit.contain,
        );
      case OnboardingMediaType.video:
        return OnboardingVideoPreview(assetPath: page.assetPath);
    }
  }
}

class OnboardingVideoPreview extends StatefulWidget {
  final String assetPath;

  const OnboardingVideoPreview({
    required this.assetPath,
    super.key,
  });

  @override
  State<OnboardingVideoPreview> createState() => _OnboardingVideoPreviewState();
}

class _OnboardingVideoPreviewState extends State<OnboardingVideoPreview> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideo;
  bool _hasEnded = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(widget.assetPath);
    _controller.addListener(_handleVideoProgress);
    _initializeVideo = _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleVideoProgress)
      ..dispose();
    super.dispose();
  }

  void _handleVideoProgress() {
    final value = _controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) {
      return;
    }

    final hasEnded = value.position >= value.duration;
    if (hasEnded != _hasEnded && mounted) {
      setState(() {
        _hasEnded = hasEnded;
      });
    }
  }

  Future<void> _openFullscreen() async {
    await _controller.pause();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => FullscreenOnboardingVideoDialog(
        assetPath: widget.assetPath,
      ),
    );

    if (!mounted || _hasEnded) return;
    await _controller.play();
  }

  Future<void> _replayInline() async {
    if (!_controller.value.isInitialized) return;

    await _controller.seekTo(Duration.zero);
    await _controller.play();

    if (mounted) {
      setState(() {
        _hasEnded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeVideo,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.black,
                  child: InkWell(
                    onTap: _openFullscreen,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoPlayer(_controller),
                        if (_hasEnded) ...[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.34),
                            ),
                          ),
                          Center(
                            child: FilledButton.icon(
                              onPressed: _replayInline,
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(
                                AppStrings.onboardingReplayPreview.tr(),
                              ),
                            ),
                          ),
                        ],
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: FilledButton.icon(
                            onPressed: _openFullscreen,
                            icon: const Icon(Icons.open_in_full),
                            label: Text(AppStrings.onboardingPlayPreview.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FullscreenOnboardingVideoDialog extends StatefulWidget {
  final String assetPath;

  const FullscreenOnboardingVideoDialog({
    required this.assetPath,
    super.key,
  });

  @override
  State<FullscreenOnboardingVideoDialog> createState() =>
      _FullscreenOnboardingVideoDialogState();
}

class _FullscreenOnboardingVideoDialogState
    extends State<FullscreenOnboardingVideoDialog> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideo;
  bool _hasClosedAtEnd = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(widget.assetPath);
    _initializeVideo = _controller.initialize().then((_) {
      if (!mounted) return;
      _controller
        ..addListener(_closeWhenFinished)
        ..play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_closeWhenFinished)
      ..dispose();
    super.dispose();
  }

  void _closeWhenFinished() {
    final value = _controller.value;
    if (_hasClosedAtEnd ||
        !value.isInitialized ||
        value.duration == Duration.zero) {
      return;
    }

    if (value.position >= value.duration) {
      _hasClosedAtEnd = true;
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: FutureBuilder<void>(
              future: _initializeVideo,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }

                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                );
              },
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
                tooltip: AppStrings.close.tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
