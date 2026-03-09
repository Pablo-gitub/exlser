import 'package:flutter/material.dart';

/// Dialog used to confirm inferred schema before importing dataset.
///
/// UI layout:
/// ├ Table preview (first rows)
/// ├ Column configuration list
/// │   ├ Column name field
/// │   └ Column type dropdown
/// └ Confirm button
///
/// Responsibilities:
/// - Display parsed preview rows
/// - Allow editing column names
/// - Allow selecting column types
/// - Confirm schema before table creation
class SchemaConfirmationDialog extends StatelessWidget {
  const SchemaConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    /// TODO:
    /// Build schema confirmation UI.
    ///
    /// Components:
    /// - preview table
    /// - editable column list
    /// - confirm button
    return const SizedBox();
  }
}