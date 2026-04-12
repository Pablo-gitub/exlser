import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'splash_viewmodel.dart';

/// Splash screen displayed during application startup.
///
/// Responsibilities:
/// - display branding
/// - trigger lightweight app initialization
/// - provide smooth transition after native splash
///
/// Navigation is delegated to router state.
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(splashViewModelProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 120,
        ),
      ),
    );
  }
}