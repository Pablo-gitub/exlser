import 'package:flutter/material.dart';

/// Numeric filter widget.
///
/// Used for INTEGER / REAL columns.
///
/// Allows selecting:
/// - minimum value
/// - maximum value
///
/// UI example:
/// range slider or two numeric inputs.
class FilterNumericWidget extends StatelessWidget {

  final String columnName;

  const FilterNumericWidget({
    super.key,
    required this.columnName,
  });

  @override
  Widget build(BuildContext context) {

    /// TODO
    /// Render numeric range selector

    return const Placeholder();
  }
}