import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/constants/themes/utils/akel_design_system.dart';

/// ==================== FUTURISTIC PANIC BUTTON (UPGRADED) ====================
/// 3D-styled panic button with chrome rings, blue glow, rotating accents, and hexagonal grid
/// Premium version with enhanced animations and visual effects
class FuturisticPanicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final bool isActive;
  final double size;
  final double progress; // 0.0 to 1.0 for long press indicator
  final String? label;

  const FuturisticPanicButton({
    super.key,
    required this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.isActive = false,
    this.size = 280,
    this.progress = 0,
    this.label,
  });

  @override
  State<FuturisticPanicButton> createState() => _FuturisticPanicButtonState();
}

class _FuturisticPanicButtonState extends State<FuturisticPanicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation (breathing effect)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation (spinning corner accents)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Glow animation (pulsing glow intensity)
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onLongPressStart: (_) => widget.onLongPressStart?.call(),
      onLongPressEnd: (_) => widget.onLongPressEnd?.call(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Multi-layer glow rings
                  _buildGlowRings(),

                  // Rotating outer ring with corner accents
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: CornerAccentsPainter(
                            color: AkelDesign.neonBlue,
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    },
                  ),

                  // Chrome ring (metallic)
                  Container(
                    width: widget.size * 0.85,
                    height: widget.size * 0.85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AkelDesign.chromeGradient,
                      boxShadow: AkelDesign.chromeShadow,
                    ),
                  ),

                  // Blue glow ring
                  Container(
                    width: widget.size * 0.75,
                    height: widget.size * 0.75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AkelDesign.neonBlue,
                        width: 3,
                      ),
                      boxShadow: AkelDesign.neonBlueShadow,
                    ),
                  ),

                  // Progress indicator (for long press)
                  if (widget.progress > 0)
                    SizedBox(
                      width: widget.size * 0.75,
                      height: widget.size * 0.75,
                      child: CircularProgressIndicator(
                        value: widget.progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),

                  // Panic button core (red glossy)
                  Container(
                    width: widget.size * 0.65,
                    height: widget.size * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AkelDesign.panicGradient,
                      boxShadow: AkelDesign.redGlowShadow,
                    ),
                  ),

                  // Hexagonal grid overlay
                  Container(
                    width: widget.size * 0.65,
                    height: widget.size * 0.65,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: CustomPaint(
                      painter: HexagonalGridPainter(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),

                  // Center content
                  _buildCenterContent(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlowRings() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AkelDesign.primaryRed.withValues(alpha: _glowAnimation.value * 0.6),
                blurRadius: 60,
                spreadRadius: 30,
              ),
            ],
          ),
        ),
        // Middle glow
        Container(
          width: widget.size * 0.95,
          height: widget.size * 0.95,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AkelDesign.primaryRed.withValues(alpha: _glowAnimation.value * 0.8),
                blurRadius: 40,
                spreadRadius: 15,
              ),
            ],
          ),
        ),
        // Inner glow
        Container(
          width: widget.size * 0.9,
          height: widget.size * 0.9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AkelDesign.primaryRed.withValues(alpha: _glowAnimation.value),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCenterContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.isActive ? Icons.warning_rounded : Icons.emergency,
          color: Colors.white,
          size: widget.size * 0.25,
          shadows: [
            Shadow(
              color: AkelDesign.neonBlue.withValues(alpha: 0.8),
              blurRadius: 20,
            ),
          ],
        ),
        SizedBox(height: widget.size * 0.03),
        Text(
          widget.label ?? (widget.isActive ? 'ACTIVE' : 'PANIC'),
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.11,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ==================== HEXAGONAL GRID PAINTER ====================
class HexagonalGridPainter extends CustomPainter {
  final Color color;

  HexagonalGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final hexSize = size.width / 8;

    for (var row = -3; row <= 3; row++) {
      for (var col = -3; col <= 3; col++) {
        final x = center.dx + (col * hexSize * 1.5);
        final y = center.dy + (row * hexSize * 1.732) + (col % 2 == 0 ? 0 : hexSize * 0.866);

        _drawHexagon(canvas, paint, Offset(x, y), hexSize * 0.4);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ==================== CORNER ACCENTS PAINTER ====================
class CornerAccentsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  CornerAccentsPainter({
    required this.color,
    this.strokeWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final path = Path();
      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        math.pi / 6,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ==================== FUTURISTIC CARD (UPGRADED) ====================
class FuturisticCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool hasGlow;
  final Color? glowColor;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Gradient? gradient;

  const FuturisticCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hasGlow = false,
    this.glowColor,
    this.onTap,
    this.borderRadius,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AkelDesign.md),
      decoration: BoxDecoration(
        gradient: gradient ?? AkelDesign.carbonGradient,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AkelDesign.radiusLg,
        ),
        border: Border.all(
          color: (glowColor ?? AkelDesign.metalChrome).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: hasGlow
            ? [
          BoxShadow(
            color: (glowColor ?? AkelDesign.neonBlue).withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ]
            : AkelDesign.cardShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AkelDesign.radiusLg),
        child: card,
      );
    }

    return card;
  }
}

/// ==================== FUTURISTIC BUTTON (UPGRADED) ====================
class FuturisticButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final bool isOutlined;
  final bool isFullWidth;
  final bool isSmall;
  final bool isDisabled;

  const FuturisticButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.isSmall = false,
    this.isDisabled = false,
  });

  @override
  State<FuturisticButton> createState() => _FuturisticButtonState();
}

class _FuturisticButtonState extends State<FuturisticButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDisabled
        ? AkelDesign.textDim
        : (widget.color ?? AkelDesign.neonBlue);

    return GestureDetector(
      onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isDisabled
          ? null
          : (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AkelDesign.durationFast,
        width: widget.isFullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isSmall ? AkelDesign.md : AkelDesign.lg,
          vertical: widget.isSmall ? AkelDesign.sm : AkelDesign.md,
        ),
        decoration: BoxDecoration(
          gradient: widget.isOutlined || widget.isDisabled
              ? null
              : LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: widget.isOutlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
          border: widget.isOutlined ? Border.all(color: color, width: 2) : null,
          boxShadow: _isPressed || widget.isDisabled
              ? []
              : [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                color: widget.isOutlined ? color : Colors.white,
                size: widget.isSmall ? 16 : 20,
              ),
              SizedBox(width: widget.isSmall ? AkelDesign.xs : AkelDesign.sm),
            ],
            Text(
              widget.text,
              style: (widget.isSmall ? AkelDesign.caption : AkelDesign.button).copyWith(
                color: widget.isOutlined ? color : Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==================== FUTURISTIC ICON BUTTON ====================
class FuturisticIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const FuturisticIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 48,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AkelDesign.neonBlue;

    final button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              iconColor.withValues(alpha: 0.3),
              iconColor.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// ==================== STATUS INDICATOR ====================
class StatusIndicator extends StatefulWidget {
  final bool isActive;
  final String label;
  final Color? activeColor;
  final Color? inactiveColor;

  const StatusIndicator({
    super.key,
    required this.isActive,
    required this.label,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCol = widget.activeColor ?? AkelDesign.successGreen;
    final inactiveCol = widget.inactiveColor ?? AkelDesign.metalChrome;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _blinkController,
          builder: (context, child) {
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isActive
                    ? activeCol.withValues(alpha: 0.3 + (_blinkController.value * 0.7))
                    : inactiveCol.withValues(alpha: 0.3),
                boxShadow: widget.isActive
                    ? [
                  BoxShadow(
                    color: activeCol.withValues(alpha: _blinkController.value * 0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
                    : [],
              ),
            );
          },
        ),
        const SizedBox(width: AkelDesign.sm),
        Text(
          widget.label,
          style: AkelDesign.caption.copyWith(
            color: widget.isActive ? activeCol : inactiveCol,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// ==================== PROGRESS RING ====================
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget? center;
  final String? label;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.color = AkelDesign.neonBlue,
    this.center,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              color: color,
            ),
          ),
          if (center != null) center!,
          if (label != null && center == null)
            Text(
              label!,
              style: AkelDesign.h3.copyWith(fontSize: size * 0.25),
            ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = AkelDesign.metalChrome.withValues(alpha: 0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// ==================== MODE CHIP ====================
class ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;

  const ModeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AkelDesign.neonBlue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AkelDesign.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AkelDesign.md,
          vertical: AkelDesign.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? color : AkelDesign.darkPanel,
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
          border: Border.all(
            color: isActive ? color : AkelDesign.metalChrome.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AkelDesign.metalChrome,
              size: 16,
            ),
            const SizedBox(width: AkelDesign.xs),
            Text(
              label,
              style: AkelDesign.caption.copyWith(
                color: isActive ? Colors.white : AkelDesign.metalChrome,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==================== FUTURISTIC CHIP (NEW) ====================
class FuturisticChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;

  const FuturisticChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AkelDesign.neonBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AkelDesign.radiusCircle),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AkelDesign.md,
          vertical: AkelDesign.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              effectiveColor.withValues(alpha: 0.3),
              effectiveColor.withValues(alpha: 0.1),
            ],
          )
              : null,
          color: isSelected ? null : AkelDesign.darkPanel,
          borderRadius: BorderRadius.circular(AkelDesign.radiusCircle),
          border: Border.all(
            color: isSelected ? effectiveColor : AkelDesign.metalChrome.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? effectiveColor : AkelDesign.metalChrome,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AkelDesign.caption.copyWith(
                color: isSelected ? effectiveColor : AkelDesign.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==================== FUTURISTIC BADGE (NEW) ====================
class FuturisticBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;

  const FuturisticBadge({
    super.key,
    required this.text,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AkelDesign.successGreen;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AkelDesign.sm,
        vertical: AkelDesign.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            effectiveColor.withValues(alpha: 0.3),
            effectiveColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: effectiveColor, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AkelDesign.caption.copyWith(
              fontSize: 11,
              color: effectiveColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ==================== FUTURISTIC TEXT FIELD (NEW) ====================
class FuturisticTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  const FuturisticTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(labelText!, style: AkelDesign.caption),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            gradient: AkelDesign.carbonGradient,
            borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
            border: Border.all(
              color: AkelDesign.neonBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            style: AkelDesign.body,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AkelDesign.caption,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AkelDesign.neonBlue) : null,
              suffixIcon: suffixIcon != null
                  ? IconButton(
                icon: Icon(suffixIcon, color: AkelDesign.metalChrome),
                onPressed: onSuffixTap,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AkelDesign.md),
            ),
          ),
        ),
      ],
    );
  }
}

/// ==================== FUTURISTIC PROGRESS BAR (NEW) ====================
class FuturisticProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  final String? label;

  const FuturisticProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AkelDesign.neonBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label!, style: AkelDesign.caption),
              Text(
                '${(value * 100).toInt()}%',
                style: AkelDesign.caption.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AkelDesign.metalChrome.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          effectiveColor,
                          effectiveColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ==================== SECTION HEADER ====================
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = color ?? AkelDesign.neonBlue;

    return Row(
      children: [
        Icon(icon, color: headerColor, size: 24),
        const SizedBox(width: AkelDesign.sm),
        Expanded(
          child: Text(
            title,
            style: AkelDesign.h3.copyWith(fontSize: 20),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// ==================== INFO ROW ====================
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor ?? AkelDesign.neonBlue,
          size: 20,
        ),
        const SizedBox(width: AkelDesign.sm),
        Expanded(
          child: Text(
            label,
            style: AkelDesign.body.copyWith(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: AkelDesign.body.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// ==================== GLOWING DIVIDER (UPGRADED) ====================
class GlowingDivider extends StatelessWidget {
  final Color? color;
  final Color? glowColor; // ADDED THIS
  final bool hasGlow;
  final double thickness;
  final EdgeInsets? margin;

  const GlowingDivider({
    super.key,
    this.color,
    this.glowColor, // ADDED THIS
    this.hasGlow = false,
    this.thickness = 1,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? AkelDesign.metalChrome.withValues(alpha: 0.3);
    final effectiveGlowColor = glowColor ?? color ?? AkelDesign.neonBlue; // ADDED THIS

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: AkelDesign.md),
      height: thickness,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            effectiveGlowColor.withValues(alpha: hasGlow ? 0.8 : 0.3),
            Colors.transparent,
          ],
        ),
        boxShadow: hasGlow
            ? [
          BoxShadow(
            color: effectiveGlowColor.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
    );
  }
}

/// ==================== METRIC CARD ====================
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FuturisticCard(
      onTap: onTap,
      hasGlow: true,
      glowColor: color,
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: AkelDesign.h2.copyWith(
                  fontSize: 28,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AkelDesign.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// ==================== LOADING INDICATOR ====================
class FuturisticLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const FuturisticLoadingIndicator({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  State<FuturisticLoadingIndicator> createState() => _FuturisticLoadingIndicatorState();
}

class _FuturisticLoadingIndicatorState extends State<FuturisticLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CornerAccentsPainter(
              color: widget.color ?? AkelDesign.neonBlue,
              strokeWidth: 4,
            ),
          ),
        );
      },
    );
  }
}