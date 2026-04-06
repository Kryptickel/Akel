import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../providers/auth_provider.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/glossy_3d_widgets.dart';

/// ==================== FULL SCREEN ONBOARDING ====================
///
/// AKEL PANIC BUTTON - BUILD 58
///
/// TRUE FULL SCREEN onboarding with:
/// - Edge-to-edge design
/// - No gaps or padding
/// - Status bar overlay
/// - Immersive experience
/// - 4 onboarding pages
/// - Skip button
/// - Animated transitions
///
/// =================================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set FULL SCREEN mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    _fadeController.reset();
    _scaleController.reset();
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      await authProvider.updateOnboardingComplete(userId, true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      debugPrint(' Onboarding completed');
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      body: Stack(
        children: [
          // Background gradient (full screen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AkelDesign.carbonFiber,
                    AkelDesign.deepBlack,
                    const Color(0xFF000000),
                  ],
                ),
              ),
            ),
          ),

          // Animated background effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPatternPainter(
                    animationValue: _rotateController.value,
                  ),
                );
              },
            ),
          ),

          // PageView (full screen)
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildPage(
                index: 0,
                icon: Icons.shield_rounded,
                title: 'Welcome to AKEL',
                description: 'Your personal safety companion with AI-powered protection',
                color: AkelDesign.primaryRed,
                topPadding: topPadding,
                bottomPadding: bottomPadding,
              ),
              _buildPage(
                index: 1,
                icon: Icons.location_on,
                title: 'Location Tracking',
                description: 'Real-time GPS sharing with emergency contacts when you need help',
                color: AkelDesign.neonBlue,
                topPadding: topPadding,
                bottomPadding: bottomPadding,
              ),
              _buildPage(
                index: 2,
                icon: Icons.contacts,
                title: 'Emergency Contacts',
                description: 'Add trusted contacts who will be notified during emergencies',
                color: const Color(0xFF00BFA5),
                topPadding: topPadding,
                bottomPadding: bottomPadding,
              ),
              _buildPage(
                index: 3,
                icon: Icons.psychology,
                title: 'Doctor Annie AI',
                description: 'Your intelligent AI companion ready to assist 24/7',
                color: const Color(0xFF00E5FF),
                topPadding: topPadding,
                bottomPadding: bottomPadding,
              ),
            ],
          ),

          // Top skip button (over status bar)
          Positioned(
            top: topPadding + 16,
            right: 20,
            child: AnimatedOpacity(
              opacity: _currentPage < 3 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: TextButton(
                onPressed: _currentPage < 3 ? _completeOnboarding : null,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  'SKIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls (over nav bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 40,
            child: Column(
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AkelDesign.neonBlue
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: _currentPage == index
                            ? [
                          BoxShadow(
                            color: AkelDesign.neonBlue.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                            : [],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // Next/Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Glossy3DButton(
                    text: _currentPage == 3 ? 'GET STARTED' : 'NEXT',
                    onPressed: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    color: _currentPage == 3
                        ? AkelDesign.primaryRed
                        : AkelDesign.neonBlue,
                    icon: _currentPage == 3
                        ? Icons.check_circle
                        : Icons.arrow_forward,
                    width: double.infinity,
                    height: 56,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required double topPadding,
    required double bottomPadding,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 80,
        bottom: bottomPadding + 180,
        left: 30,
        right: 30,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glossy effect
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Glossy sphere
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.3),
                          colors: [
                            Colors.white.withOpacity(0.2),
                            color.withOpacity(0.4),
                            color.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        ),
                      ),
                    ),

                    // Glossy highlight
                    Positioned(
                      top: 30,
                      left: 30,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.6),
                              Colors.white.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Icon
                    Center(
                      child: Icon(
                        icon,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.6,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Feature badges (only on last page)
              if (index == 3)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFeatureBadge('150+ Features', Icons.star),
                    _buildFeatureBadge('AI Powered', Icons.psychology),
                    _buildFeatureBadge('24/7 Active', Icons.access_time),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AkelDesign.neonBlue),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== BACKGROUND PATTERN PAINTER ====================

class BackgroundPatternPainter extends CustomPainter {
  final double animationValue;

  BackgroundPatternPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw rotating circles
    for (int i = 1; i <= 5; i++) {
      final radius = i * 80.0;
      final offset = animationValue * 2 * math.pi;

      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(offset * (i.isOdd ? 1 : -1));

      canvas.drawCircle(
        Offset.zero,
        radius,
        paint..color = Colors.white.withOpacity(0.02 / i),
      );

      canvas.restore();
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.01)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        gridPaint,
      );
    }

    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}