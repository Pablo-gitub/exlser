import 'package:flutter/material.dart';

/// Application color palette.
///
/// Brand:
/// - blue = data / reliability
/// - green = transformation / analytics
///
/// Neutral:
/// - white / graphite / border tones
class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF0F5EA8);
  static const Color primaryLight = Color(0xFF3EA9F5);

  static const Color secondary = Color(0xFF20C05C);
  static const Color secondaryLight = Color(0xFF7BEA8E);

  // Neutral colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFDCE3EB);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color blackSoft = Color(0xFF0F172A);

  // Semantic colors
  static const Color success = secondary;
  static const Color error = Color(0xFFDC2626);
}