import 'package:flutter/material.dart';

/// Table visualization of dataset rows.
///
/// Displays rows in a spreadsheet-like structure.
///
/// Features:
/// - dynamic columns
/// - horizontal scrolling
/// - optional column visibility
/// - optional sorting
///
/// This widget receives already filtered data from DatasetViewModel.
class DatasetTableView extends StatelessWidget {

  final List<Map<String, dynamic>> rows;

  const DatasetTableView({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {

    /// TODO
    /// Build dynamic DataTable based on dataset columns

    return const Placeholder();
  }
}