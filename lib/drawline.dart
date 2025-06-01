import 'package:flutter/material.dart';

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isNewLine;

  DrawnLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isNewLine = false,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;

  DrawingPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final paint =
          Paint()
            ..color = line.color
            ..strokeWidth = line.strokeWidth
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

      for (int i = 0; i < line.points.length - 1; i++) {
        // if (line.points[i] != null && line.points[i + 1] != null) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
        // }
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
