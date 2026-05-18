import 'package:exel_category/application/dto/chart_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatefulWidget {
  final CategoryChartData data;

  const PieChartWidget({super.key, required this.data});

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final colors = _chartColors(context);
    final total = widget.data.points.fold(0.0, (s, p) => s + p.value);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response!.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: [
                for (var i = 0; i < widget.data.points.length; i++)
                  _section(
                    point: widget.data.points[i],
                    color: colors[i % colors.length],
                    total: total,
                    isTouched: i == _touchedIndex,
                  ),
              ],
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Legend(points: widget.data.points, colors: colors),
      ],
    );
  }

  PieChartSectionData _section({
    required CategoryPoint point,
    required Color color,
    required double total,
    required bool isTouched,
  }) {
    final pct = total > 0 ? (point.value / total * 100) : 0.0;
    return PieChartSectionData(
      value: point.value,
      color: color,
      radius: isTouched ? 70 : 60,
      title: '${pct.toStringAsFixed(1)}%',
      titleStyle: TextStyle(
        fontSize: isTouched ? 14 : 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  List<Color> _chartColors(BuildContext context) {
    final base = Theme.of(context).colorScheme;
    return [
      base.primary,
      base.secondary,
      base.tertiary,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
  }
}

class _Legend extends StatelessWidget {
  final List<CategoryPoint> points;
  final List<Color> colors;

  const _Legend({required this.points, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (var i = 0; i < points.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                points[i].label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}
