import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/location_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/offline_mode_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const AkelPanicButtonApp());
}

class AkelPanicButtonApp extends StatelessWidget {
  const AkelPanicButtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akel Panic Button',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
        '/location': (context) => const LocationScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/offline': (context) => const OfflineModeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}