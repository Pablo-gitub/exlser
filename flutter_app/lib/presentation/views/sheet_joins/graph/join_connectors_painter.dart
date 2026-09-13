import 'package:flutter/material.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_models.dart';

class JoinConnectorsPainter extends CustomPainter {
  final List<GraphConnectionLayout> connections;
  final ColorScheme colorScheme;
  final int? selectedRelationshipId;

  const JoinConnectorsPainter({
    required this.connections,
    required this.colorScheme,
    this.selectedRelationshipId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connections) {
      final isSelected = conn.relationshipId != null &&
          conn.relationshipId == selectedRelationshipId;

      final Color lineColor = conn.isSuggestion
          ? colorScheme.tertiary.withValues(alpha: 0.65)
          : (isSelected
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.85));

      final double strokeWidth =
          isSelected ? 3.5 : (conn.isSuggestion ? 1.8 : 2.5);

      final paint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(conn.startPoint.dx, conn.startPoint.dy)
        ..cubicTo(
          conn.controlPoint1.dx,
          conn.controlPoint1.dy,
          conn.controlPoint2.dx,
          conn.controlPoint2.dy,
          conn.endPoint.dx,
          conn.endPoint.dy,
        );

      if (conn.isSuggestion) {
        // Draw dashed curve for unconfirmed suggestion
        _drawDashedPath(canvas, path, paint);
      } else {
        // Draw solid curve
        canvas.drawPath(path, paint);
      }

      // Draw start and end pin anchor dots
      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(conn.startPoint, 4, dotPaint);
      canvas.drawCircle(conn.endPoint, 4, dotPaint);

      final dotBorderPaint = Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(conn.startPoint, 4, dotBorderPaint);
      canvas.drawCircle(conn.endPoint, 4, dotBorderPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = distance + dashWidth > metric.length
            ? metric.length - distance
            : dashWidth;
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant JoinConnectorsPainter oldDelegate) {
    return oldDelegate.connections != connections ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.selectedRelationshipId != selectedRelationshipId;
  }
}
