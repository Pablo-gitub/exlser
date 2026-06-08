import 'package:flutter/material.dart';

/// Text filter widget.
///
/// Used for TEXT columns.
///
/// Allows selecting values via checkbox list.
/// Values come from QueryRepository.getDistinctValues().
class FilterTextWidget extends StatelessWidget {
  final String columnName;

  const FilterTextWidget({
    super.key,
    required this.columnName,
  });

  @override
  Widget build(BuildContext context) {
    /// TODO
    /// Fetch distinct values
    /// Render checkbox list
    /// Notify ViewModel when selection changes

    return const Placeholder();
  }
}
