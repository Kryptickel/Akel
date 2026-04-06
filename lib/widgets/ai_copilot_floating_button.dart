import 'package:flutter/material.dart';
import 'dart:math' as math;

class AICopilotFloatingButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final AnimationController pulseController;

  const AICopilotFloatingButton({
    super.key,
    required this.onTap,
    required this.isActive,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final scale = 1.0 + (math.sin(pulseController.value * 2 * math.pi) * 0.1);

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isActive
                      ? [
                    const Color(0xFF00BFA5),
                    const Color(0xFF00E5FF),
                  ]
                      : [
                    Colors.grey,
                    Colors.grey.shade700,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? const Color(0xFF00BFA5).withOpacity(0.5)
                        : Colors.black26,
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),

                  // Icon
                  const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 36,
                  ),

                  // Active indicator
                  if (isActive)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}