import 'package:flutter/material.dart';
import 'dart:ui';

/// Mixin to add glossy effects to existing widgets
mixin GlossyEffects {

  /// Add glossy shine overlay to any widget
  Widget addGlossyShine(Widget child, {double intensity = 0.3}) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(intensity),
                  Colors.white.withOpacity(0),
                  Colors.black.withOpacity(0),
                  Colors.black.withOpacity(intensity * 0.3),
                ],
                stops: const [0, 0.4, 0.6, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Add 3D depth shadows
  List<BoxShadow> get3DDepthShadows({
    required Color color,
    bool isPressed = false,
  }) {
    return [
// Top light
      BoxShadow(
        color: Colors.white.withOpacity(0.3),
        offset: Offset(-2, isPressed ? -1 : -2),
        blurRadius: isPressed ? 4 : 8,
      ),
// Bottom shadow
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        offset: Offset(isPressed ? 2 : 4, isPressed ? 2 : 4),
        blurRadius: isPressed ? 4 : 12,
      ),
// Color glow
      BoxShadow(
        color: color.withOpacity(0.4),
        blurRadius: isPressed ? 10 : 20,
        spreadRadius: isPressed ? 1 : 3,
      ),
    ];
  }

  /// Add metallic gradient
  LinearGradient getMetallicGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.8),
        baseColor,
        baseColor.withOpacity(0.6),
        baseColor.withOpacity(0.8),
      ],
      stops: const [0, 0.4, 0.6, 1],
    );
  }

  /// Add glass blur effect
  Widget addGlassBlur(Widget child, {double blur = 15}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
}