import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../providers/auth_provider.dart';
import '../widgets/futuristic_widgets.dart';
import '../widgets/glossy_3d_widgets.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import 'registration_screen.dart';

/// ==================== LOGIN SCREEN ====================
///
/// AKEL PANIC BUTTON - LOGIN
///
/// BUILD 58 - INDUSTRIAL SCI-FI
///
/// Features:
/// - Email/Password login
/// - Google Sign-In
/// - Forgot password
/// - Industrial sci-fi design
/// - Animated logo
/// - Neon accents
///
/// =====================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _floatController;
  late AnimationController _glowController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation (logo breathing)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotate animation (outer ring)
    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotateController);

    // Float animation (cards)
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted && authProvider.user != null) {
        // Login successful - AuthWrapper will handle navigation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(' Login successful!'),
              ],
            ),
            backgroundColor: AkelDesign.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(' Login failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AkelDesign.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.signInWithGoogle();

      if (mounted && authProvider.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(' Google sign-in successful!'),
              ],
            ),
            backgroundColor: AkelDesign.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(' Google sign-in failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AkelDesign.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _emailController.text.trim());
        return AlertDialog(
          backgroundColor: AkelDesign.darkPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
            side: BorderSide(
              color: AkelDesign.neonBlue.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AkelDesign.neonBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, color: AkelDesign.neonBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Reset Password', style: AkelDesign.h3.copyWith(fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you a password reset link.',
                style: AkelDesign.body.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.email, color: AkelDesign.neonBlue),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                    borderSide: BorderSide(color: AkelDesign.neonBlue.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                    borderSide: const BorderSide(color: AkelDesign.neonBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: AkelDesign.deepBlack.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          actions: [
            FuturisticButton(
              text: 'Cancel',
              onPressed: () => Navigator.pop(context),
              isOutlined: true,
              isSmall: true,
            ),
            const SizedBox(width: 8),
            FuturisticButton(
              text: 'Send Link',
              icon: Icons.send,
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              color: AkelDesign.neonBlue,
              isSmall: true,
            ),
          ],
        );
      },
    );

    if (email != null && email.isNotEmpty) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.resetPassword(email: email);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(' Password reset email sent! Check your inbox.'),
                  ),
                ],
              ),
              backgroundColor: AkelDesign.successGreen,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(' Error: ${e.toString()}'),
                  ),
                ],
              ),
              backgroundColor: AkelDesign.errorRed,
            ),
          );
        }
      }
    }
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _rotateAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AkelDesign.neonBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Middle glow ring
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AkelDesign.neonBlue.withValues(alpha: _glowAnimation.value * 0.6),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AkelDesign.neonBlue.withValues(alpha: _glowAnimation.value * 0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

                // Inner red circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AkelDesign.primaryRed.withValues(alpha: 0.8),
                        AkelDesign.primaryRed.withValues(alpha: 0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AkelDesign.primaryRed.withValues(alpha: _glowAnimation.value * 0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              AkelDesign.carbonFiber,
              AkelDesign.deepBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    _buildAnimatedLogo(),

                    const SizedBox(height: 40),

                    // Title with Glow Effect
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AkelDesign.neonBlue,
                              Colors.white,
                              AkelDesign.neonBlue,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'AKEL',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: AkelDesign.neonBlue.withValues(alpha: _glowAnimation.value * 0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'PANIC BUTTON SYSTEM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                        color: AkelDesign.neonBlue.withValues(alpha: 0.8),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Email Field with Float Animation
                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value * 0.3),
                          child: RealisticGlassCard(
                            enable3D: true,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                hintText: 'your.email@example.com',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                prefixIcon: const Icon(Icons.email_outlined, color: AkelDesign.neonBlue),
                                border: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    // Password Field with Float Animation
                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value * 0.4),
                          child: RealisticGlassCard(
                            enable3D: true,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                hintText: '••••••••',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                prefixIcon: const Icon(Icons.lock_outline, color: AkelDesign.neonBlue),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: AkelDesign.neonBlue,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AkelDesign.neonBlue.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Login Button
                    FuturisticButton(
                      text: _isLoading ? 'SIGNING IN...' : 'SIGN IN',
                      icon: _isLoading ? null : Icons.login,
                      onPressed: _isLoading ? () {} : _handleLogin,
                      color: AkelDesign.primaryRed,
                      isFullWidth: true,
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.2),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.2),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Google Sign In
                    FuturisticButton(
                      text: 'SIGN IN WITH GOOGLE',
                      icon: Icons.g_mobiledata,
                      onPressed: _isLoading ? () {} : _handleGoogleSignIn,
                      color: Colors.white,
                      isOutlined: true,
                      isFullWidth: true,
                    ),

                    const SizedBox(height: 30),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AkelDesign.neonBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Version
                    Text(
                      'BUILD 58 • INDUSTRIAL SCI-FI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: AkelDesign.neonBlue.withValues(alpha: 0.3),
                      ),
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
}