import 'package:flutter/material.dart';

/// A thin, smooth trend line for cards (like the reference balance card).
class Sparkline extends StatelessWidget {
  final List<double> points;
  final Color color;
  final double height;
  const Sparkline(
      {super.key,
      required this.points,
      required this.color,
      this.height = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: IgnorePointer(
        child: CustomPaint(painter: _SparkPainter(points, color)),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _SparkPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final lo = points.reduce((a, b) => a < b ? a : b);
    final hi = points.reduce((a, b) => a > b ? a : b);
    final range = (hi - lo).abs() < 0.0001 ? 1.0 : (hi - lo);
    final dx = size.width / (points.length - 1);

    Offset at(int i) {
      final norm = (points[i] - lo) / range;
      final y = size.height - (norm * (size.height - 6)) - 3;
      return Offset(dx * i, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = at(i - 1);
      final p1 = at(i);
      final mx = (p0.dx + p1.dx) / 2;
      path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }

    // soft fill under the line
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
          ).createShader(Offset.zero & size));

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // end dot
    final last = at(points.length - 1);
    canvas.drawCircle(last, 3.2, Paint()..color = color);
    canvas.drawCircle(
        last, 5.5, Paint()..color = color.withOpacity(0.18));
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.points != points || old.color != color;
}
