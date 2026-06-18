import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An animated circular progress ring. Turns red when over 100%.
class BudgetRing extends StatelessWidget {
  final double percent; // 0..1+ (values > 1 render full + red)
  final double size;
  final double stroke;
  final Widget child;
  final List<Color> colors;

  const BudgetRing({
    super.key,
    required this.percent,
    required this.child,
    this.size = 168,
    this.stroke = 14,
    this.colors = const [Color(0xFF2ECC71), Color(0xFFB8F2C9)],
  });

  @override
  Widget build(BuildContext context) {
    final target = percent.clamp(0.0, 1.0);
    final over = percent > 1.0;
    final ringColors = over
        ? const [Color(0xFFFF8A80), Color(0xFFE74C3C)]
        : colors;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeOutCubic,
        builder: (context, val, _) => CustomPaint(
          painter: _RingPainter(val, stroke, ringColors),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double p;
  final double stroke;
  final List<Color> colors;
  _RingPainter(this.p, this.stroke, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    const start = -math.pi / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withOpacity(0.16),
    );

    if (p <= 0) return;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [...colors, colors.first],
        transform: const GradientRotation(start),
      ).createShader(rect);
    canvas.drawArc(rect, start, 2 * math.pi * p, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.p != p || o.colors != colors || o.stroke != stroke;
}
