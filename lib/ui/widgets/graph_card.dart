import 'package:flutter/material.dart';

import '../../core/services/calculation_engine.dart';

class GraphCard extends StatelessWidget {
  const GraphCard({
    super.key,
    required this.points,
    required this.expression,
  });

  final List<OffsetPoint> points;
  final String expression;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Visual Math Mode', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            expression,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: _GraphPainter(
                points: points,
                axisColor: Colors.white.withValues(alpha: 0.26),
                lineColor: theme.colorScheme.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.points,
    required this.axisColor,
    required this.lineColor,
  });

  final List<OffsetPoint> points;
  final Color axisColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axisPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      axisPaint,
    );

    if (points.length < 2) {
      return;
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final dx = ((point.x + 10) / 20) * size.width;
      final dy = size.height - (((point.y + 10) / 20) * size.height);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.lineColor != lineColor;
  }
}
