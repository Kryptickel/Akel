import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

import '../core/constants/themes/utils/akel_design_system.dart';
import 'auth_wrapper_screen.dart';

/// ==================== OPTIMIZED SPLASH SCREEN ====================
///
/// AKEL PANIC BUTTON - BUILD 58
///
/// Performance-optimized splash with:
/// - Smooth animations (no lag)
/// - Clean 3D effects
/// - Proper disposal
/// - Fast navigation
/// - 20 particles (not 100)
/// - Balanced wow factor
///
/// =================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _shieldController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shieldAnimation;

  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _setupAnimations();
    _generateParticles();
    _startSequence();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _shieldController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shieldAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.easeOut),
    );
  }

  void _generateParticles() {
    // Only 20 particles for performance
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 2 - 1,
        y: _random.nextDouble() * 2 - 1,
        z: _random.nextDouble(),
        speed: 0.001 + _random.nextDouble() * 0.003,
        size: 2 + _random.nextDouble() * 4,
        opacity: 0.4 + _random.nextDouble() * 0.6,
        color: _random.nextBool()
            ? const Color(0xFF00BFA5)
            : const Color(0xFF00E5FF),
      ));
    }
  }

  void _startSequence() async {
    _fadeController.forward();
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _shieldController.forward();

    await Future.delayed(const Duration(milliseconds: 2600));

    if (mounted && !_navigated) {
      _navigated = true;
      debugPrint(' Splash complete → AuthWrapperScreen');
      _stopAllAnimations();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const AuthWrapperScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _stopAllAnimations() {
    _fadeController.stop();
    _scaleController.stop();
    _rotateController.stop();
    _pulseController.stop();
    _glowController.stop();
    _particleController.stop();
    _shieldController.stop();
  }

  @override
  void dispose() {
    _stopAllAnimations();
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _shieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF001a1a),
                  Color(0xFF000d0d),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  time: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _fadeAnimation,
                _scaleAnimation,
                _pulseAnimation,
              ]),
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value * _pulseAnimation.value,
                    child: SizedBox(
                      width: 350,
                      height: 400,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 270,
                                height: 270,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AkelDesign.neonBlue
                                        .withOpacity(_glowAnimation.value * 0.7),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AkelDesign.neonBlue.withOpacity(
                                          _glowAnimation.value * 0.6),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                center: Alignment(-0.3, -0.3),
                                radius: 1.2,
                                colors: [
                                  Color(0xFF00E5FF),
                                  Color(0xFF00BFA5),
                                  Color(0xFF006064),
                                  Color(0xFF003d40),
                                ],
                                stops: [0.0, 0.4, 0.7, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00BFA5).withOpacity(0.8),
                                  blurRadius: 50,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.4, -0.4),
                                        radius: 0.6,
                                        colors: [
                                          Colors.white.withOpacity(0.7),
                                          Colors.white.withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const Center(
                                  child: Icon(
                                    Icons.shield,
                                    size: 90,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            bottom: 20,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white,
                                      Color(0xFF00BFA5),
                                      Color(0xFF00E5FF),
                                      Colors.white,
                                    ],
                                    stops: [0.0, 0.3, 0.7, 1.0],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'AKEL',
                                    style: TextStyle(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                AnimatedBuilder(
                                  animation: _glowAnimation,
                                  builder: (context, child) {
                                    return Text(
                                      'PANIC BUTTON',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 5,
                                        color: const Color(0xFF00E5FF),
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFF00E5FF)
                                                .withOpacity(_glowAnimation.value),
                                            blurRadius: 15,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'BUILD 58',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 3,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  double x, y, z;
  double speed;
  double size;
  double opacity;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.z,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.color,
  });

  void update() {
    z += speed;
    if (z > 1) z = 0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double time;

  ParticlePainter({
    required this.particles,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final screenX =
          (particle.x / particle.z) * size.width * 0.5 + size.width * 0.5;
      final screenY =
          (particle.y / particle.z) * size.height * 0.5 + size.height * 0.5;
      final screenSize = particle.size / particle.z;

      if (screenX >= 0 &&
          screenX <= size.width &&
          screenY >= 0 &&
          screenY <= size.height) {
        final paint = Paint()
          ..color =
          particle.color.withOpacity(particle.opacity * (1 - particle.z))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, screenSize * 0.3);

        canvas.drawCircle(
          Offset(screenX, screenY),
          screenSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}