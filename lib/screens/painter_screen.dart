import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ❌ Forces an offscreen pass every frame: saveLayer + a blur mask filter.
class SlowWavePainter extends CustomPainter {
  final double t;
  SlowWavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // saveLayer allocates an offscreen buffer; the blur reads it back.
    canvas.saveLayer(Offset.zero & size, Paint());
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(_wave(size, t), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SlowWavePainter old) => old.t != t;
}

/// ✅ No saveLayer, no blur — a crisp stroke drawn directly.
class FastWavePainter extends CustomPainter {
  final double t;
  FastWavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(_wave(size, t), paint);
  }

  @override
  bool shouldRepaint(FastWavePainter old) => old.t != t;
}

Path _wave(Size size, double t) {
  final path = Path()..moveTo(0, size.height / 2);
  for (double x = 0; x <= size.width; x += 4) {
    final y = size.height / 2 +
        math.sin((x / size.width * 4 * math.pi) + t * 2 * math.pi) *
            size.height /
            3;
    path.lineTo(x, y);
  }
  return path;
}

class PainterScreen extends StatefulWidget {
  const PainterScreen({super.key});
  @override
  State<PainterScreen> createState() => _PainterScreenState();
}

class _PainterScreenState extends State<PainterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _panel(String label, Color color, CustomPainter Function(double) make) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 8),
        // RepaintBoundary isolates the animation's layer (Article 3, §3).
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              size: const Size(double.infinity, 140),
              painter: make(_c.value),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CustomPainter cost · Article 4')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Both animate the same wave. The red one forces an '
              'offscreen pass (saveLayer + blur) every frame; the green one '
              'draws directly. Measure the raster-thread cost with the '
              'integration_test perf harness (see test/ and Article 6).',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 20),
          _panel('❌ saveLayer + blur (offscreen pass)', Colors.red,
              (t) => SlowWavePainter(t)),
          const SizedBox(height: 24),
          _panel('✅ direct stroke (no offscreen)', Colors.green,
              (t) => FastWavePainter(t)),
        ],
      ),
    );
  }
}
