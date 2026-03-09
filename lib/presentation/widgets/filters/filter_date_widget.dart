import 'package:flutter/material.dart';

/// Date filter widget.
///
/// Used for DATE columns.
///
/// Allows selecting:
/// - start date
/// - end date
///
/// Values must respect available range.
class FilterDateWidget extends StatelessWidget {

  final String columnName;

  const FilterDateWidget({
    super.key,
    required this.columnName,
  });

  @override
  Widget build(BuildContext context) {

    /// TODO
    /// Implement date range picker

    return const Placeholder();
  }
}