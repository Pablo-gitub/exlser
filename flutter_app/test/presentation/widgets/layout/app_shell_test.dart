import 'package:exlser/presentation/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppShell responsive navigation', () {
    test('does not expand navigation on phone landscape sizes', () {
      expect(
        AppShell.shouldUseExpandedNavigationForSize(const Size(900, 430)),
        isFalse,
      );
    });

    test('expands navigation on wide non-phone sizes', () {
      expect(
        AppShell.shouldUseExpandedNavigationForSize(const Size(900, 700)),
        isTrue,
      );
    });
  });
}
