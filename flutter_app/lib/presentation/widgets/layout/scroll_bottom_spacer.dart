import 'package:exlser/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class ScrollBottomSpacer extends StatelessWidget {
  final double extraSpacing;

  const ScrollBottomSpacer({
    super.key,
    this.extraSpacing = AppSpacing.xl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.viewPaddingOf(context).bottom + extraSpacing,
    );
  }
}
