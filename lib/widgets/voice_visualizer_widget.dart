import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ==================== VOICE VISUALIZER WIDGET ====================
/// Animated voice wave visualization
/// BUILD 55 - HOUR 3
/// ================================================================

class VoiceVisualizerWidget extends StatefulWidget {
  final bool isListening;
  final double amplitude;
  final Color color;
  final double size;

  const VoiceVisualizerWidget({
    Key? key,
    required this.isListening,
    this.amplitude = 0.5,
    this.color = Colors.blue,
    this.size = 200,
  }) : super(key: key);

  @override
  State<VoiceVisualizerWidget> createState() => _VoiceVisualizerWidgetState();
}

class _VoiceVisualizerWidgetState extends State<VoiceVisualizerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: VoiceWavePainter(
              animation: _controller.value,
              isListening: widget.isListening,
              amplitude: widget.amplitude,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final double animation;
  final bool isListening;
  final double amplitude;
  final Color color;

  VoiceWavePainter({
    required this.animation,
    required this.isListening,
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw center circle
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.3, centerPaint);

    if (isListening) {
      // Draw animated waves
      for (int i = 0; i < 3; i++) {
        final wavePaint = Paint()
          ..color = color.withOpacity(0.3 - (i * 0.1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        final waveRadius = radius * (0.5 + (i * 0.2)) *
            (1 + amplitude * math.sin(animation * 2 * math.pi + i));

        canvas.drawCircle(center, waveRadius, wavePaint);
      }

      // Draw particles
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * math.pi + animation * 2 * math.pi;
        final particleRadius = radius * 0.7;
        final particleX = center.dx + particleRadius * math.cos(angle);
        final particleY = center.dy + particleRadius * math.sin(angle);

        final particlePaint = Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(particleX, particleY),
          3,
          particlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(VoiceWavePainter oldDelegate) => true;
}