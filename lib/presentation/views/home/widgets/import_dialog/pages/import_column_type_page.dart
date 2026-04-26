import 'package:flutter/material.dart';

/// Column type configuration page.
///
/// Future responsibilities:
/// - display detected columns
/// - show inferred types
/// - allow manual type correction
/// - show warnings for invalid/null values
class ImportColumnTypePage extends StatelessWidget {
  const ImportColumnTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Column type configuration will be shown here.'),
    );
  }
}