import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CloudProvider { aws, google }

class AccessibilityCloudService {
  static final AccessibilityCloudService _instance =
  AccessibilityCloudService._internal();
  factory AccessibilityCloudService() => _instance;
  AccessibilityCloudService._internal();

  bool _dyslexiaMode = false;
  String _dyslexiaFont = 'OpenDyslexic';
  Color _dyslexiaBackground = const Color(0xFFFFFAE6);
  Color _dyslexiaText = const Color(0xFF3E2723);
  double _letterSpacing = 1.5;
  double _lineHeight = 1.8;

  CloudProvider _currentProvider = CloudProvider.aws;
  bool _autoFailover = true;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _dyslexiaMode = prefs.getBool('dyslexia_mode') ?? false;
    _dyslexiaFont = prefs.getString('dyslexia_font') ?? 'OpenDyslexic';
    _letterSpacing = prefs.getDouble('letter_spacing') ?? 1.5;
    _lineHeight = prefs.getDouble('line_height') ?? 1.8;

    final bgColor = prefs.getInt('dyslexia_bg_color');
    if (bgColor != null) _dyslexiaBackground = Color(bgColor);

    final txtColor = prefs.getInt('dyslexia_text_color');
    if (txtColor != null) _dyslexiaText = Color(txtColor);

    final provider = prefs.getString('cloud_provider') ?? 'aws';
    _currentProvider = provider == 'google' ? CloudProvider.google : CloudProvider.aws;

    _autoFailover = prefs.getBool('cloud_auto_failover') ?? true;

    debugPrint(' Accessibility & Cloud Service initialized');
  }

  Future<void> enableDyslexiaMode({
    String? font,
    Color? backgroundColor,
    Color? textColor,
    double? letterSpacing,
    double? lineHeight,
  }) async {
    _dyslexiaMode = true;
    if (font != null) _dyslexiaFont = font;
    if (backgroundColor != null) _dyslexiaBackground = backgroundColor;
    if (textColor != null) _dyslexiaText = textColor;
    if (letterSpacing != null) _letterSpacing = letterSpacing;
    if (lineHeight != null) _lineHeight = lineHeight;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dyslexia_mode', true);
    await prefs.setString('dyslexia_font', _dyslexiaFont);
    await prefs.setInt('dyslexia_bg_color', _dyslexiaBackground.value);
    await prefs.setInt('dyslexia_text_color', _dyslexiaText.value);
    await prefs.setDouble('letter_spacing', _letterSpacing);
    await prefs.setDouble('line_height', _lineHeight);

    debugPrint(' Dyslexia mode enabled: Font=$_dyslexiaFont');
  }

  Future<void> disableDyslexiaMode() async {
    _dyslexiaMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dyslexia_mode', false);
    debugPrint(' Dyslexia mode disabled');
  }

  ThemeData getDyslexiaTheme(ThemeData baseTheme) {
    if (!_dyslexiaMode) return baseTheme;

    return baseTheme.copyWith(
      scaffoldBackgroundColor: _dyslexiaBackground,
      cardColor: _dyslexiaBackground.withOpacity(0.9),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: _dyslexiaText,
        displayColor: _dyslexiaText,
        fontFamily: _dyslexiaFont,
      ).copyWith(
        bodyLarge: TextStyle(
          color: _dyslexiaText,
          fontSize: 18,
          letterSpacing: _letterSpacing,
          height: _lineHeight,
          fontFamily: _dyslexiaFont,
        ),
        bodyMedium: TextStyle(
          color: _dyslexiaText,
          fontSize: 16,
          letterSpacing: _letterSpacing,
          height: _lineHeight,
          fontFamily: _dyslexiaFont,
        ),
      ),
    );
  }

  List<String> get availableFonts => [
    'OpenDyslexic',
    'Comic Sans MS',
    'Arial',
    'Lexend',
    'Verdana',
  ];

  Map<String, Map<String, Color>> get colorSchemes => {
    'Cream & Brown': {
      'background': const Color(0xFFFFFAE6),
      'text': const Color(0xFF3E2723),
    },
    'Yellow & Black': {
      'background': const Color(0xFFFFF9C4),
      'text': const Color(0xFF000000),
    },
    'Blue & Navy': {
      'background': const Color(0xFFE3F2FD),
      'text': const Color(0xFF0D47A1),
    },
    'Green & Dark Green': {
      'background': const Color(0xFFE8F5E9),
      'text': const Color(0xFF1B5E20),
    },
  };

  bool get isDyslexiaMode => _dyslexiaMode;
  String get currentFont => _dyslexiaFont;
  Color get backgroundColor => _dyslexiaBackground;
  Color get textColor => _dyslexiaText;
  double get letterSpacing => _letterSpacing;
  double get lineHeight => _lineHeight;

  Future<void> setCloudProvider(CloudProvider provider) async {
    _currentProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cloud_provider',
      provider == CloudProvider.aws ? 'aws' : 'google',
    );
    debugPrint(' Cloud provider set to: $provider');
  }

  Future<void> setAutoFailover(bool enabled) async {
    _autoFailover = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cloud_auto_failover', enabled);
    debugPrint(' Auto-failover: ${enabled ? "enabled" : "disabled"}');
  }

  CloudProvider get currentProvider => _currentProvider;
  bool get autoFailover => _autoFailover;

  String getVoiceEndpoint() {
    return _currentProvider == CloudProvider.aws
        ? 'https://polly.us-east-1.amazonaws.com'
        : 'https://texttospeech.googleapis.com';
  }

  String getStorageEndpoint() {
    return _currentProvider == CloudProvider.aws
        ? 'https://s3.amazonaws.com'
        : 'https://storage.googleapis.com';
  }

  String getDatabaseEndpoint() {
    return _currentProvider == CloudProvider.aws
        ? 'dynamodb.us-east-1.amazonaws.com'
        : 'firestore.googleapis.com';
  }

  Future<void> attemptFailover() async {
    if (!_autoFailover) return;

    final newProvider = _currentProvider == CloudProvider.aws
        ? CloudProvider.google
        : CloudProvider.aws;

    debugPrint(' Attempting failover: $_currentProvider → $newProvider');
    await setCloudProvider(newProvider);
  }
}