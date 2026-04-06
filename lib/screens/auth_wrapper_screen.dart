import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapperScreen extends StatelessWidget {
  const AuthWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    debugPrint('🔍 ========== AUTH WRAPPER (SIMPLIFIED) ==========');
    debugPrint('🔍 User: ${authProvider.user?.email ?? "NOT LOGGED IN"}');

// Show loading while checking auth state
    if (authProvider.isLoading) {
      debugPrint('⏳ Auth loading...');
      return _buildLoadingScreen();
    }

    final user = authProvider.user;

// Not logged in → Login Screen
    if (user == null) {
      debugPrint('🔐 User not logged in → LoginScreen');
      return const LoginScreen();
    }

// Logged in → Always go to Home Screen
// Home Screen will handle onboarding check
    debugPrint('🏠 User logged in → HomeScreen (will check onboarding)');
    return const HomeScreen();
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00BFA5)),
            SizedBox(height: 24),
            Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}