import 'package:exel_category/domain/value_objects/column_type.dart';

enum ChartType {
  line,
  bar,
  pie,
  scatter,
  none;

  List<ColumnType> get validXColumnTypes => switch (this) {
        ChartType.line => [ColumnType.date],
        ChartType.bar => [ColumnType.text, ColumnType.boolean, ColumnType.date],
        ChartType.pie => [ColumnType.text, ColumnType.boolean],
        ChartType.scatter => [ColumnType.integer, ColumnType.real],
        ChartType.none => [],
      };

  List<ColumnType> get validYColumnTypes => switch (this) {
        ChartType.line ||
        ChartType.bar ||
        ChartType.pie ||
        ChartType.scatter =>
          [ColumnType.integer, ColumnType.real],
        ChartType.none => [],
      };

  bool get requiresYColumn =>
      this == ChartType.line || this == ChartType.scatter;

  bool get isImplemented =>
      this == ChartType.line || this == ChartType.bar || this == ChartType.pie;

  String get label => switch (this) {
        ChartType.line => 'Line',
        ChartType.bar => 'Bar',
        ChartType.pie => 'Pie',
        ChartType.scatter => 'Scatter',
        ChartType.none => '',
      };
}
