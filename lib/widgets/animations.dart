import 'package:flutter/material.dart';

/// A card wrapper that tilts in 3D perspective as the user drags across it,
/// and springs back to flat on release. No dependencies — pure Matrix4.
class Tilt3D extends StatefulWidget {
  final Widget child;
  final double maxTilt; // radians
  const Tilt3D({super.key, required this.child, this.maxTilt = 0.16});

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  double _rotX = 0;
  double _rotY = 0;
  Duration _dur = const Duration(milliseconds: 350);

  void _onUpdate(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final px = (local.dx / size.width).clamp(0.0, 1.0);
    final py = (local.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _dur = Duration.zero; // 1:1 tracking while dragging
      _rotY = (px - 0.5) * 2 * widget.maxTilt;
      _rotX = -(py - 0.5) * 2 * widget.maxTilt;
    });
  }

  void _reset() {
    setState(() {
      _dur = const Duration(milliseconds: 350);
      _rotX = 0;
      _rotY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 180,
        );
        return GestureDetector(
          onPanDown: (d) => _onUpdate(d.localPosition, size),
          onPanUpdate: (d) => _onUpdate(d.localPosition, size),
          onPanEnd: (_) => _reset(),
          onPanCancel: _reset,
          child: AnimatedContainer(
            duration: _dur,
            curve: Curves.easeOutBack,
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspective
              ..rotateX(_rotX)
              ..rotateY(_rotY),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A number that counts up smoothly when its value changes.
/// Only re-animates when [value] actually changes (safe inside rebuilds).
class AnimatedCount extends StatelessWidget {
  final double value;
  final String prefix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.value,
    this.prefix = '₱',
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 750),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '$prefix${v.toStringAsFixed(decimals)}',
        style: style,
      ),
    );
  }
}

/// Fades + slides a widget into place on mount, with an optional delay.
/// Useful for staggered entrances.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offsetY; // fraction of child height
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 0.14,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _in = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _in = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _in ? Offset.zero : Offset(0, widget.offsetY),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _in ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Scales down slightly on press for a tactile, "pressable" feel.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
