import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../providers/auth_provider.dart';
import '../widgets/futuristic_widgets.dart';
import '../widgets/glossy_3d_widgets.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import 'login_screen.dart';

/// ==================== SIGNUP SCREEN ====================
///
/// AKEL PANIC BUTTON - USER REGISTRATION
///
/// BUILD 58 - INDUSTRIAL SCI-FI
///
/// Features:
/// - Email/Password signup
/// - Input validation
/// - Loading states
/// - Error handling
/// - Navigate to login
///
/// =====================================================

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _rotateController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotateController);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Use the correct method name from your AuthProvider
      final result = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: '', // Optional: add phone field if needed
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          // Success - Navigate to home or login
          _showSuccessDialog();
        } else {
          // Error occurred
          _showErrorDialog(result['message'] ?? 'Signup failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('An error occurred: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.carbonFiber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
          side: BorderSide(
            color: AkelDesign.primaryRed.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AkelDesign.primaryRed),
            const SizedBox(width: 12),
            const Text(
              'Signup Failed',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: AkelDesign.neonBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.carbonFiber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
          side: BorderSide(
            color: AkelDesign.successGreen.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AkelDesign.successGreen),
            const SizedBox(width: 12),
            const Text(
              'Account Created!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Your account has been created successfully. You can now sign in.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(
              'Sign In',
              style: TextStyle(color: AkelDesign.successGreen),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              AkelDesign.carbonFiber,
              AkelDesign.deepBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logo
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseAnimation,
                      _floatAnimation,
                      _glowAnimation,
                      _rotateAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Center(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer rotating ring
                                  Transform.rotate(
                                    angle: _rotateAnimation.value,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AkelDesign.neonBlue.withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Glow ring
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AkelDesign.neonBlue.withValues(
                                          alpha: _glowAnimation.value * 0.8,
                                        ),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AkelDesign.neonBlue.withValues(
                                            alpha: _glowAnimation.value * 0.5,
                                          ),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Inner circle with icon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AkelDesign.primaryRed.withValues(alpha: 0.2),
                                    ),
                                    child: Icon(
                                      Icons.person_add,
                                      size: 40,
                                      color: AkelDesign.neonBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Join AKEL for instant safety',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Name Field
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.3),
                        child: RealisticGlassCard(
                          enable3D: true,
                          child: TextFormField(
                            controller: _nameController,
                            validator: _validateName,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AkelDesign.neonBlue,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Email Field
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.4),
                        child: RealisticGlassCard(
                          enable3D: true,
                          child: TextFormField(
                            controller: _emailController,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AkelDesign.neonBlue,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password Field
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.5),
                        child: RealisticGlassCard(
                          enable3D: true,
                          child: TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AkelDesign.neonBlue,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password Field
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.6),
                        child: RealisticGlassCard(
                          enable3D: true,
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            validator: _validateConfirmPassword,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AkelDesign.neonBlue,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Sign Up Button
                  _isLoading
                      ? const Center(
                    child: FuturisticLoadingIndicator(
                      size: 50,
                      color: AkelDesign.neonBlue,
                    ),
                  )
                      : FuturisticButton(
                    text: 'CREATE ACCOUNT',
                    icon: Icons.person_add,
                    onPressed: _handleSignup,
                    color: AkelDesign.successGreen,
                  ),

                  const SizedBox(height: 24),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AkelDesign.neonBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}