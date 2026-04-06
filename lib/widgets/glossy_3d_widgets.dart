import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// ==================== GLOSSY 3D BUTTON ====================
class Glossy3DButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;
  final double width;
  final double height;
  final double elevation;

  const Glossy3DButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color = const Color(0xFF00BFA5),
    this.width = 200,
    this.height = 60,
    this.elevation = 8,
  });

  @override
  State<Glossy3DButton> createState() => _Glossy3DButtonState();
}

class _Glossy3DButtonState extends State<Glossy3DButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.identity()
          ..translate(0.0, _isPressed ? widget.elevation / 2 : 0.0, 0.0)
          ..setEntry(3, 2, 0.001),
        child: Stack(
          children: [
            // Shadow layers
            Positioned(
              top: widget.elevation / 2,
              left: widget.elevation / 3,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            // Main button
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color,
                    widget.color.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  // Top light
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    offset: const Offset(-2, -2),
                    blurRadius: 8,
                  ),
                  // Bottom shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: Offset(
                      _isPressed ? 2 : 4,
                      _isPressed ? 2 : 4,
                    ),
                    blurRadius: _isPressed ? 4 : 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Glossy overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0),
                            Colors.black.withOpacity(0),
                            Colors.black.withOpacity(0.1),
                          ],
                          stops: const [0, 0.4, 0.6, 1],
                        ),
                      ),
                    ),

                    // Animated shine
                    AnimatedBuilder(
                      animation: _shineController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            (widget.width * 2) * _shineController.value - widget.width,
                            0,
                          ),
                          child: Container(
                            width: widget.width * 0.3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.4),
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Content
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top highlight
            Positioned(
              top: 2,
              left: 2,
              right: 2,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==================== REALISTIC GLASS CARD ====================
class RealisticGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final bool enableShadow;
  final bool enable3D;

  const RealisticGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.elevation = 10,
    this.padding,
    this.margin,
    this.blurStrength = 15,
    this.enableShadow = true,
    this.enable3D = true,
  });

  @override
  State<RealisticGlassCard> createState() => _RealisticGlassCardState();
}

class _RealisticGlassCardState extends State<RealisticGlassCard> {
  Offset _pointerPosition = Offset.zero;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onPanUpdate: widget.enable3D
          ? (details) {
        setState(() => _pointerPosition = details.localPosition);
      }
          : null,
      onPanEnd: widget.enable3D
          ? (_) {
        setState(() {
          _isHovering = false;
          _pointerPosition = Offset.zero;
        });
      }
          : null,
      onPanStart: widget.enable3D
          ? (_) {
        setState(() => _isHovering = true);
      }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: widget.margin,
        transform: widget.enable3D ? _calculateTransform() : Matrix4.identity(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.enableShadow
                ? [
              // Outer shadow
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: widget.elevation * 2,
                offset: Offset(0, widget.elevation / 2),
                spreadRadius: -2,
              ),
              // Inner shadow (depth)
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: widget.elevation,
                offset: const Offset(0, 2),
                spreadRadius: -5,
              ),
              // Highlight shadow
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.05 : 0.5),
                blurRadius: widget.elevation,
                offset: Offset(0, -widget.elevation / 3),
                spreadRadius: -2,
              ),
            ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurStrength,
                sigmaY: widget.blurStrength,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ]
                        : [
                      Colors.white.withOpacity(0.7),
                      Colors.white.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    width: 1.5,
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.8),
                  ),
                ),
                child: Stack(
                  children: [
                    // Glossy shine effect
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GlossyShimmerPainter(
                          borderRadius: widget.borderRadius,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: widget.padding ?? const EdgeInsets.all(20),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Matrix4 _calculateTransform() {
    if (!_isHovering) return Matrix4.identity();

    const rotationStrength = 0.02;
    final dx = (_pointerPosition.dx - 150) * rotationStrength;
    final dy = (_pointerPosition.dy - 150) * rotationStrength;

    return Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(-dy)
      ..rotateY(dx);
  }
}

/// Glossy shimmer painter
class GlossyShimmerPainter extends CustomPainter {
  final double borderRadius;
  final bool isDark;

  GlossyShimmerPainter({
    required this.borderRadius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    // Top glossy highlight
    final highlightGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [
        Colors.white.withOpacity(isDark ? 0.3 : 0.6),
        Colors.white.withOpacity(0),
      ],
    );

    final highlightPaint = Paint()
      ..shader = highlightGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.4),
      );

    canvas.clipRRect(rect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.4),
      highlightPaint,
    );

    // Bottom subtle shadow
    final bottomGradient = LinearGradient(
      begin: Alignment.center,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withOpacity(0),
        Colors.black.withOpacity(isDark ? 0.2 : 0.05),
      ],
    );

    final bottomPaint = Paint()
      ..shader = bottomGradient.createShader(
        Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      bottomPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ==================== NEUMORPHIC CARD ====================
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isPressed;
  final Color? color;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.isPressed = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ??
        (isDark ? const Color(0xFF1E2740) : const Color(0xFFE0E5EC));

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: baseColor,
        boxShadow: isPressed
            ? [
          // Inner shadow (pressed)
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.02 : 0.7),
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ]
            : [
          // Elevated shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.15),
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.05 : 0.7),
            offset: const Offset(-8, -8),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// ==================== LIQUID GLASS CARD ====================
class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<Color> gradientColors;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.gradientColors = const [
      Color(0xFF00BFA5),
      Color(0xFF00E5FF),
      Color(0xFF651FFF),
    ],
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradientColors.map((color) {
                      return color.withOpacity(0.1 + (_controller.value * 0.2));
                    }).toList(),
                  ),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Stack(
                  children: [
                    // Animated liquid blobs
                    CustomPaint(
                      painter: LiquidBlobPainter(
                        animation: _controller,
                        colors: widget.gradientColors,
                      ),
                      child: Container(),
                    ),

                    // Glossy overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.center,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: widget.padding ?? const EdgeInsets.all(20),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Liquid blob painter
class LiquidBlobPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;

  LiquidBlobPainter({
    required this.animation,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw animated blobs
    for (int i = 0; i < 3; i++) {
      final offset = (animation.value + (i * 0.33)) % 1.0;
      final x = size.width * (0.2 + (offset * 0.6));
      final y = size.height * (0.3 + (math.sin(offset * math.pi * 2) * 0.4));
      final radius = size.width * (0.3 + (math.sin(offset * math.pi * 4) * 0.1));

      paint.shader = RadialGradient(
        colors: [
          colors[i % colors.length].withOpacity(0.3),
          colors[i % colors.length].withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ==================== METALLIC CARD ====================
class MetallicCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color baseColor;

  const MetallicCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.baseColor = const Color(0xFF00BFA5),
  });

  @override
  State<MetallicCard> createState() => _MetallicCardState();
}

class _MetallicCardState extends State<MetallicCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.baseColor.withOpacity(0.8),
                    widget.baseColor,
                    widget.baseColor.withOpacity(0.6),
                  ],
                  stops: [
                    0.0,
                    _controller.value,
                    1.0,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Metallic shine
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MetallicShinePainter(
                        animation: _controller,
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: widget.padding ?? const EdgeInsets.all(20),
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Metallic shine painter
class MetallicShinePainter extends CustomPainter {
  final Animation<double> animation;

  MetallicShinePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0),
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0),
        ],
        stops: [
          0,
          animation.value,
          1,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Diagonal stripes
    for (double i = -size.height; i < size.width + size.height; i += 50) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + size.height, size.height)
        ..lineTo(i + size.height + 20, size.height)
        ..lineTo(i + 20, 0)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ==================== FROSTED GLASS CARD ====================
class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double elevation;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.elevation = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.02 : 0.3),
            blurRadius: elevation,
            offset: Offset(0, -elevation / 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ]
                    : [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.6),
                ],
              ),
              border: Border.all(
                width: 1.5,
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
              ),
            ),
            child: Stack(
              children: [
                // Frost pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: FrostPatternPainter(isDark: isDark),
                  ),
                ),

                // Content
                Padding(
                  padding: padding ?? const EdgeInsets.all(20),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Frost pattern painter
class FrostPatternPainter extends CustomPainter {
  final bool isDark;

  FrostPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.02 : 0.15)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);

    // Draw random crystalline patterns
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;

      // Draw small circles
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Draw lines radiating from circles
      for (int j = 0; j < 6; j++) {
        final angle = (j * math.pi / 3);
        final endX = x + math.cos(angle) * (radius * 3);
        final endY = y + math.sin(angle) * (radius * 3);

        canvas.drawLine(
          Offset(x, y),
          Offset(endX, endY),
          paint..strokeWidth = 0.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}