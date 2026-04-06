import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/doctor_annie_appearance.dart';
import '../services/facial_animation_service.dart';

/// Doctor Annie 3D/2D Animated Avatar Widget
/// Pixar-style medical professional with facial expressions and lip sync
class DoctorAnnieAvatarWidget extends StatefulWidget {
  final DoctorAnnieAppearance appearance;
  final double size;
  final bool enableAnimations;
  final bool showHolographicBackground;
  final VoidCallback? onTap;

  const DoctorAnnieAvatarWidget({
    super.key,
    required this.appearance,
    this.size = 300,
    this.enableAnimations = true,
    this.showHolographicBackground = true,
    this.onTap,
  });

  @override
  State<DoctorAnnieAvatarWidget> createState() => _DoctorAnnieAvatarWidgetState();
}

class _DoctorAnnieAvatarWidgetState extends State<DoctorAnnieAvatarWidget>
    with TickerProviderStateMixin {
  final FacialAnimationService _facialService = FacialAnimationService();

  late AnimationController _breathingController;
  late AnimationController _idleController;
  late AnimationController _blinkController;

  FacialExpression _currentExpression = FacialExpression.neutral;
  Phoneme _currentPhoneme = Phoneme.silence;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
  }

  void _initializeAnimations() {
    // Breathing animation (subtle up/down movement)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Idle animation (slight sway)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    // Blink animation
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  void _setupListeners() {
    _facialService.expressionStream.listen((expression) {
      if (mounted) {
        setState(() => _currentExpression = expression);
      }
    });

    _facialService.phonemeStream.listen((phoneme) {
      if (mounted) {
        setState(() => _currentPhoneme = phoneme);
      }
    });

    _facialService.blinkStream.listen((isBlinking) {
      if (mounted) {
        setState(() => _isBlinking = isBlinking);
        if (isBlinking) {
          _blinkController.forward().then((_) => _blinkController.reverse());
        }
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _idleController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Holographic background
            if (widget.showHolographicBackground) _buildHolographicBackground(),

            // Main avatar
            AnimatedBuilder(
              animation: Listenable.merge([_breathingController, _idleController]),
              builder: (context, child) {
                final breathOffset = math.sin(_breathingController.value * 2 * math.pi) * 3;
                final idleOffset = math.sin(_idleController.value * 2 * math.pi) * 2;

                return Transform.translate(
                  offset: Offset(idleOffset, breathOffset),
                  child: _buildAvatar(),
                );
              },
            ),

            // Glossy overlay effects
            if (widget.appearance.enableReflections) _buildGlossyOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHolographicBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          return CustomPaint(
            painter: HolographicBackgroundPainter(
              animationValue: _idleController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow
        if (widget.appearance.enableShadows)
          Positioned(
            bottom: 0,
            child: Container(
              width: widget.size * 0.8,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),

        // Main character body
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Head with face
            _buildHead(),
            const SizedBox(height: 8),
            // Body with clothing
            _buildBody(),
          ],
        ),
      ],
    );
  }

  Widget _buildHead() {
    return SizedBox(
      width: widget.size * 0.5,
      height: widget.size * 0.5,
      child: Stack(
        children: [
          // Head base (face)
          _buildFaceBase(),

          // Hair
          _buildHair(),

          // Eyes
          Positioned(
            top: widget.size * 0.18,
            left: widget.size * 0.12,
            right: widget.size * 0.12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEye(isLeft: true),
                _buildEye(isLeft: false),
              ],
            ),
          ),

          // Nose
          Positioned(
            top: widget.size * 0.25,
            left: widget.size * 0.23,
            child: _buildNose(),
          ),

          // Mouth with lip sync
          Positioned(
            top: widget.size * 0.32,
            left: widget.size * 0.15,
            right: widget.size * 0.15,
            child: _buildMouth(),
          ),

          // Glasses
          if (widget.appearance.hasGlasses)
            Positioned(
              top: widget.size * 0.15,
              left: widget.size * 0.08,
              right: widget.size * 0.08,
              child: _buildGlasses(),
            ),
        ],
      ),
    );
  }

  Widget _buildFaceBase() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.appearance.skinTone,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }

  Widget _buildHair() {
    return CustomPaint(
      painter: HairPainter(
        style: widget.appearance.hairStyle,
        color: widget.appearance.hairColor,
        glossyIntensity: widget.appearance.glossyIntensity,
      ),
    );
  }

  Widget _buildEye({required bool isLeft}) {
    final eyeExpression = _getEyeShapeForExpression(_currentExpression);

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final blinkScale = 1.0 - (_blinkController.value * 0.9);

        return Transform.scale(
          scaleY: blinkScale,
          child: Container(
            width: widget.size * 0.08,
            height: widget.size * 0.08,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Iris
                Container(
                  width: widget.size * 0.055,
                  height: widget.size * 0.055,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6D4C3D), // Brown
                  ),
                ),
                // Pupil
                Container(
                  width: widget.size * 0.03,
                  height: widget.size * 0.03,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
                // Highlight (glossy effect)
                Positioned(
                  top: widget.size * 0.015,
                  left: widget.size * 0.02,
                  child: Container(
                    width: widget.size * 0.02,
                    height: widget.size * 0.02,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNose() {
    return CustomPaint(
      size: Size(widget.size * 0.04, widget.size * 0.06),
      painter: NosePainter(
        skinTone: widget.appearance.skinTone,
      ),
    );
  }

  Widget _buildMouth() {
    return CustomPaint(
      size: Size(widget.size * 0.2, widget.size * 0.08),
      painter: MouthPainter(
        expression: _currentExpression,
        phoneme: _currentPhoneme,
        skinTone: widget.appearance.skinTone,
      ),
    );
  }

  Widget _buildGlasses() {
    return CustomPaint(
      size: Size(widget.size * 0.34, widget.size * 0.12),
      painter: GlassesPainter(
        style: widget.appearance.glassesStyle ?? GlassesStyle.modern,
        glassyTransparency: widget.appearance.glassyTransparency,
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: widget.size * 0.65,
      height: widget.size * 0.6,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Clothing
          _buildClothing(),

          // Stethoscope
          if (widget.appearance.hasStethoscope)
            Positioned(
              top: widget.size * 0.05,
              child: _buildStethoscope(),
            ),

          // Tablet
          if (widget.appearance.hasTablet)
            Positioned(
              bottom: widget.size * 0.05,
              right: widget.size * 0.05,
              child: _buildTablet(),
            ),
        ],
      ),
    );
  }

  Widget _buildClothing() {
    return CustomPaint(
      size: Size(widget.size * 0.65, widget.size * 0.6),
      painter: ClothingPainter(
        type: widget.appearance.clothing,
        color: widget.appearance.clothingColor,
        glossyIntensity: widget.appearance.glossyIntensity,
      ),
    );
  }

  Widget _buildStethoscope() {
    return CustomPaint(
      size: Size(widget.size * 0.3, widget.size * 0.4),
      painter: StethoscopePainter(),
    );
  }

  Widget _buildTablet() {
    return Container(
      width: widget.size * 0.15,
      height: widget.size * 0.2,
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildGlossyOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: widget.appearance.glossyIntensity * 0.3),
                Colors.transparent,
                Colors.white.withValues(alpha: widget.appearance.glossyIntensity * 0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  String _getEyeShapeForExpression(FacialExpression expression) {
    switch (expression) {
      case FacialExpression.smile:
      case FacialExpression.encouraging:
        return 'happy';
      case FacialExpression.concerned:
      case FacialExpression.empathetic:
        return 'sad';
      case FacialExpression.surprised:
        return 'wide';
      case FacialExpression.thinking:
        return 'squint';
      default:
        return 'normal';
    }
  }
}

// ==================== CUSTOM PAINTERS ====================

class HolographicBackgroundPainter extends CustomPainter {
  final double animationValue;

  HolographicBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw circular holographic rings
    for (int i = 0; i < 5; i++) {
      final radius = (size.width * 0.3) + (i * 30) + (animationValue * 20);
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        paint,
      );
    }

    // Draw medical data lines
    final dataPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.4)
      ..strokeWidth = 2;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (animationValue * math.pi * 2);
      final startX = size.width / 2 + math.cos(angle) * 80;
      final startY = size.height / 2 + math.sin(angle) * 80;
      final endX = size.width / 2 + math.cos(angle) * 120;
      final endY = size.height / 2 + math.sin(angle) * 120;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        dataPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HolographicBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class HairPainter extends CustomPainter {
  final HairStyle style;
  final Color color;
  final double glossyIntensity;

  HairPainter({
    required this.style,
    required this.color,
    required this.glossyIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (style) {
      case HairStyle.bun:
        _drawBun(canvas, size, paint);
        break;
      case HairStyle.ponytail:
        _drawPonytail(canvas, size, paint);
        break;
      case HairStyle.shoulder:
      case HairStyle.braided:
        _drawBraidedHair(canvas, size, paint);
        break;
      default:
        _drawDefaultHair(canvas, size, paint);
    }

    // Add glossy highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: glossyIntensity * 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.2),
      size.width * 0.08,
      highlightPaint,
    );
  }

  void _drawBraidedHair(Canvas canvas, Size size, Paint paint) {
    // Top of head coverage
    final headPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.1,
        size.width * 0.85,
        size.height * 0.2,
      )
      ..lineTo(size.width * 0.85, size.height * 0.35)
      ..lineTo(size.width * 0.15, size.height * 0.35)
      ..close();

    canvas.drawPath(headPath, paint);

    // Side-swept braid
    final braidPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.6,
        size.width * 0.25,
        size.height * 0.95,
      );

    final braidPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(braidPath, braidPaint);

    // Braid texture (segments)
    final segmentPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double i = 0.3; i < 0.95; i += 0.08) {
      final y = size.height * i;
      final x = size.width * 0.2 + (math.sin(i * 10) * 5);
      canvas.drawLine(
        Offset(x - 15, y),
        Offset(x + 15, y),
        segmentPaint,
      );
    }
  }

  void _drawBun(Canvas canvas, Size size, Paint paint) {
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.1),
      size.width * 0.15,
      paint,
    );
  }

  void _drawPonytail(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.6,
        size.width * 0.5,
        size.height * 0.9,
      );

    final ponytailPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, ponytailPaint);
  }

  void _drawDefaultHair(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.1,
        size.width * 0.9,
        size.height * 0.3,
      )
      ..lineTo(size.width * 0.9, size.height * 0.5)
      ..lineTo(size.width * 0.1, size.height * 0.5)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HairPainter oldDelegate) => false;
}

class NosePainter extends CustomPainter {
  final Color skinTone;

  NosePainter({required this.skinTone});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = skinTone.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height,
        size.width * 0.7,
        size.height * 0.7,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Nostrils
    final nostrilPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.8),
      size.width * 0.08,
      nostrilPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.8),
      size.width * 0.08,
      nostrilPaint,
    );
  }

  @override
  bool shouldRepaint(covariant NosePainter oldDelegate) => false;
}

class MouthPainter extends CustomPainter {
  final FacialExpression expression;
  final Phoneme phoneme;
  final Color skinTone;

  MouthPainter({
    required this.expression,
    required this.phoneme,
    required this.skinTone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4696E)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = _getMouthPath(size);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);

    // Teeth for certain phonemes
    if ([Phoneme.ah, Phoneme.ee, Phoneme.oh].contains(phoneme)) {
      _drawTeeth(canvas, size);
    }
  }

  Path _getMouthPath(Size size) {
    final path = Path();

    switch (expression) {
      case FacialExpression.smile:
      case FacialExpression.encouraging:
      // Wide smile
        path.moveTo(0, size.height * 0.3);
        path.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.8,
          size.width,
          size.height * 0.3,
        );
        break;

      case FacialExpression.concerned:
      // Slight frown
        path.moveTo(0, size.height * 0.6);
        path.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.4,
          size.width,
          size.height * 0.6,
        );
        break;

      case FacialExpression.surprised:
      // Open mouth (O shape)
        path.addOval(Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.5),
          width: size.width * 0.5,
          height: size.height * 0.7,
        ));
        break;

      default:
      // Neutral or speaking
        final openness = _getOpennessForPhoneme(phoneme);
        path.moveTo(0, size.height * 0.5);
        path.quadraticBezierTo(
          size.width * 0.5,
          size.height * (0.5 + openness),
          size.width,
          size.height * 0.5,
        );
    }

    return path;
  }

  double _getOpennessForPhoneme(Phoneme phoneme) {
    switch (phoneme) {
      case Phoneme.silence:
      case Phoneme.m:
        return 0.0;
      case Phoneme.eh:
      case Phoneme.f:
        return 0.15;
      case Phoneme.ah:
        return 0.4;
      case Phoneme.oh:
      case Phoneme.oo:
        return 0.3;
      case Phoneme.ee:
        return 0.2;
      default:
        return 0.1;
    }
  }

  void _drawTeeth(Canvas canvas, Size size) {
    final teethPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final teethRect = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.4,
      size.height * 0.2,
    );

    canvas.drawRect(teethRect, teethPaint);
  }

  @override
  bool shouldRepaint(covariant MouthPainter oldDelegate) {
    return oldDelegate.expression != expression ||
        oldDelegate.phoneme != phoneme;
  }
}

class GlassesPainter extends CustomPainter {
  final GlassesStyle style;
  final double glassyTransparency;

  GlassesPainter({
    required this.style,
    required this.glassyTransparency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final lensPaint = Paint()
      ..color = Colors.blue.withValues(alpha: glassyTransparency * 0.2)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Left lens
    final leftLens = Rect.fromCenter(
      center: Offset(size.width * 0.25, size.height * 0.5),
      width: size.width * 0.35,
      height: size.height * 0.7,
    );

    // Right lens
    final rightLens = Rect.fromCenter(
      center: Offset(size.width * 0.75, size.height * 0.5),
      width: size.width * 0.35,
      height: size.height * 0.7,
    );

    switch (style) {
      case GlassesStyle.modern:
      case GlassesStyle.rectangular:
        canvas.drawRRect(
          RRect.fromRectAndRadius(leftLens, const Radius.circular(8)),
          lensPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(leftLens, const Radius.circular(8)),
          framePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rightLens, const Radius.circular(8)),
          lensPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rightLens, const Radius.circular(8)),
          framePaint,
        );
        break;

      case GlassesStyle.round:
        canvas.drawOval(leftLens, lensPaint);
        canvas.drawOval(leftLens, framePaint);
        canvas.drawOval(rightLens, lensPaint);
        canvas.drawOval(rightLens, framePaint);
        break;

      default:
        canvas.drawRect(leftLens, lensPaint);
        canvas.drawRect(leftLens, framePaint);
        canvas.drawRect(rightLens, lensPaint);
        canvas.drawRect(rightLens, framePaint);
    }

    // Bridge
    canvas.drawLine(
      Offset(size.width * 0.425, size.height * 0.5),
      Offset(size.width * 0.575, size.height * 0.5),
      framePaint,
    );

    // Glossy highlights on lenses
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.35),
      size.width * 0.05,
      highlightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.35),
      size.width * 0.05,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GlassesPainter oldDelegate) => false;
}

class ClothingPainter extends CustomPainter {
  final ClothingType type;
  final Color color;
  final double glossyIntensity;

  ClothingPainter({
    required this.type,
    required this.color,
    required this.glossyIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (type) {
      case ClothingType.labCoat:
        _drawLabCoat(canvas, size, paint);
        break;
      case ClothingType.scrubs:
        _drawScrubs(canvas, size, paint);
        break;
      default:
        _drawLabCoat(canvas, size, paint);
    }

    // Add glossy highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: glossyIntensity * 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.2),
      size.width * 0.08,
      highlightPaint,
    );
  }

  void _drawLabCoat(Canvas canvas, Size size, Paint paint) {
    // Collar
    final collarPath = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.2, size.height * 0.15)
      ..lineTo(size.width * 0.35, size.height * 0.2)
      ..close();

    canvas.drawPath(collarPath, paint);

    final collarPath2 = Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.8, size.height * 0.15)
      ..lineTo(size.width * 0.65, size.height * 0.2)
      ..close();

    canvas.drawPath(collarPath2, paint);

    // Main coat body
    final coatPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.15)
      ..lineTo(size.width * 0.1, size.height)
      ..lineTo(size.width * 0.9, size.height)
      ..lineTo(size.width * 0.8, size.height * 0.15)
      ..close();

    canvas.drawPath(coatPath, paint);

    // Center line (buttons)
    final buttonPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    for (double i = 0.25; i < 0.9; i += 0.15) {
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * i),
        size.width * 0.02,
        buttonPaint,
      );
    }
  }

  void _drawScrubs(Canvas canvas, Size size, Paint paint) {
    // V-neck top
    final topPath = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.9, size.height * 0.6)
      ..lineTo(size.width * 0.1, size.height * 0.6)
      ..close();

    canvas.drawPath(topPath, paint);
  }

  @override
  bool shouldRepaint(covariant ClothingPainter oldDelegate) => false;
}

class StethoscopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Tubes
    final leftTube = Path()
      ..moveTo(size.width * 0.2, 0)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.9,
      );

    final rightTube = Path()
      ..moveTo(size.width * 0.8, 0)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.9,
      );

    canvas.drawPath(leftTube, paint);
    canvas.drawPath(rightTube, paint);

    // Chest piece
    final chestPiecePaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.95),
      size.width * 0.08,
      chestPiecePaint,
    );

    // Metallic highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.93),
      size.width * 0.03,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StethoscopePainter oldDelegate) => false;
}