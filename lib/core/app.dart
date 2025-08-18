import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/registration_page.dart';
import '../features/panic/presentation/pages/panic_dashboard.dart';
import '../features/emergency/presentation/pages/emergency_contacts_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../shared/themes/app_theme.dart';

class AkelApp extends StatelessWidget {
  const AkelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Akel - Panic Button Safety App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: '/registration',
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const PanicDashboard(),
    ),
    GoRoute(
      path: '/emergency-contacts',
      builder: (context, state) => const EmergencyContactsPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);