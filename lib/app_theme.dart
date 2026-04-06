import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Dark Theme
  static const Color primaryTeal = Color(0xFF00BFA5);
  static const Color darkNavy = Color(0xFF0A0E27);
  static const Color cardDark = Color(0xFF1E2740);
  static const Color crimsonRed = Color(0xFFDC143C);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);

  // Colors - Light Theme
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient glowGradient = RadialGradient(
    colors: [
      primaryTeal,
      Color(0xFF00897B),
      Colors.transparent,
    ],
  );

  // Shadows
  static List<BoxShadow> glowShadow({double blur = 30, double spread = 10}) {
    return [
      BoxShadow(
        color: primaryTeal.withValues(alpha: 0.4),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Text Styles - Dark
  static const TextStyle headerLargeDark = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle headerMediumDark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle bodyLargeDark = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );

  static const TextStyle bodySmallDark = TextStyle(
    fontSize: 14,
    color: Colors.white54,
  );

  // Text Styles - Light
  static const TextStyle headerLargeLight = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: lightText,
  );

  static const TextStyle headerMediumLight = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: lightText,
  );

  static const TextStyle bodyLargeLight = TextStyle(
    fontSize: 16,
    color: lightTextSecondary,
  );

  static const TextStyle bodySmallLight = TextStyle(
    fontSize: 14,
    color: lightTextSecondary,
  );

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: darkNavy,
      cardColor: cardDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: primaryTeal,
        surface: cardDark,
        error: crimsonRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: headerLargeDark,
        headlineMedium: headerMediumDark,
        bodyLarge: bodyLargeDark,
        bodySmall: bodySmallDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: primaryTeal,
        surface: lightCard,
        error: crimsonRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.black26,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: headerLargeLight,
        headlineMedium: headerMediumLight,
        bodyLarge: bodyLargeLight,
        bodySmall: bodySmallLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),
    );
  }
}