import 'package:flutter/material.dart';

/// Akel Futuristic Design System
/// Inspired by the 3D carbon fiber metallic logo with chrome rings,
/// neon blue accents, and glossy red panic button

class AkelDesign {
  AkelDesign._();

  // ==================== PRIMARY COLORS ====================

  static const Color primaryRed = Color(0xFFE63946);
  static const Color deepRed = Color(0xFFBE0A1F);
  static const Color primaryBlue = Color(0xFF00D4FF);
  static const Color neonBlue = Color(0xFF00B4D8);
  static const Color metalChrome = Color(0xFFB8BDC1);
  static const Color lightChrome = Color(0xFFD4D8DD);
  static const Color darkChrome = Color(0xFF8B9099);

  // ==================== BACKGROUND COLORS ====================

  static const Color carbonFiber = Color(0xFF1A1D23);
  static const Color deepBlack = Color(0xFF0D0F13);
  static const Color darkPanel = Color(0xFF1E2329);
  static const Color cardBg = Color(0xFF252A31);
  static const Color lightPanel = Color(0xFF2A2F38);

  // ==================== ACCENT COLORS ====================

  static const Color successGreen = Color(0xFF06FFA5);
  static const Color warningOrange = Color(0xFFFF9F1C);
  static const Color errorRed = Color(0xFFFF006E);
  static const Color infoBlue = Color(0xFF4CC9F0);
  static const Color glowBlue = Color(0xFF00B4D8);

  // ==================== TEXT COLORS ====================

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB8BDC1);
  static const Color textLight = Color(0xFFD4D8DD);
  static const Color textDim = Color(0xFF8B9099);

  // ==================== GRADIENTS ====================

  static const LinearGradient panicGradient = LinearGradient(
    colors: [Color(0xFFE63946), Color(0xFFBE0A1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chromeGradient = LinearGradient(
    colors: [Color(0xFFD4D8DD), Color(0xFF8B9099), Color(0xFFB8BDC1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGlowGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0096C7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient carbonGradient = LinearGradient(
    colors: [Color(0xFF1A1D23), Color(0xFF0D0F13)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPanelGradient = LinearGradient(
    colors: [Color(0xFF1E2329), Color(0xFF252A31)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF06FFA5), Color(0xFF04CC84)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF9F1C), Color(0xFFE67E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== SHADOWS ====================

  static List<BoxShadow> get neonBlueShadow => [
    BoxShadow(
      color: neonBlue.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: neonBlue.withOpacity(0.3),
      blurRadius: 40,
      spreadRadius: 5,
    ),
  ];

  static List<BoxShadow> get redGlowShadow => [
    BoxShadow(
      color: primaryRed.withOpacity(0.6),
      blurRadius: 30,
      spreadRadius: 5,
    ),
    BoxShadow(
      color: primaryRed.withOpacity(0.4),
      blurRadius: 60,
      spreadRadius: 10,
    ),
  ];

  static List<BoxShadow> get chromeShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: metalChrome.withOpacity(0.2),
      blurRadius: 5,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: neonBlue.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get successShadow => [
    BoxShadow(
      color: successGreen.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get warningShadow => [
    BoxShadow(
      color: warningOrange.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // ==================== BORDERS ====================

  static Border get neonBorder => Border.all(color: neonBlue, width: 2);
  static Border get chromeBorder => Border.all(color: metalChrome, width: 1.5);
  static Border get subtleBorder => Border.all(color: metalChrome.withOpacity(0.3), width: 1);
  static Border get successBorder => Border.all(color: successGreen, width: 2);
  static Border get warningBorder => Border.all(color: warningOrange, width: 2);
  static Border get errorBorder => Border.all(color: errorRed, width: 2);

  // ==================== TYPOGRAPHY ====================

  static const TextStyle h1 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
    color: Colors.white,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: Color(0xFFB8BDC1),
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: Color(0xFFD4D8DD),
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    color: Color(0xFFD4D8DD),
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    letterSpacing: 1,
    color: Color(0xFF8B9099),
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: Colors.white,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.5,
    color: Colors.white,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: Colors.white,
  );

  // ==================== SPACING ====================

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ==================== BORDER RADIUS ====================

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusXxl = 32;
  static const double radiusCircle = 999;

  // ==================== ANIMATION DURATIONS ====================

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ==================== ICON SIZES ====================

  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  static const double iconXxl = 64;
}