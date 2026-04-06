import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// ==================== GESTURE CONTROL SERVICE ====================
///
/// 4-IN-1 GESTURE CONTROL SYSTEM:
/// 1. Shake Detection - Shake phone to trigger panic
/// 2. Tap Patterns - Secret tap sequences
/// 3. Screen Gestures - Swipe patterns for stealth activation
/// 4. Motion Detection - Movement-based triggers
///
/// BUILD 55 - HOUR 9
/// ================================================================

class GestureControlService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  bool _isShakeEnabled = false;
  bool _isTapPatternEnabled = false;
  bool _isMotionEnabled = false;

  // Shake detection
  static const double _shakeThreshold = 15.0;
  DateTime? _lastShakeTime;
  int _shakeCount = 0;
  Timer? _shakeResetTimer;

  // Tap pattern
  List<DateTime> _tapTimes = [];
  List<int> _currentPattern = [];
  List<int> _secretPattern = [1, 2, 1]; // Single, Double, Single tap
  Timer? _patternResetTimer;

  // Motion detection
  DateTime? _lastMotionTime;
  bool _isMotionActive = false;

  // Callbacks
  VoidCallback? onShakeDetected;
  VoidCallback? onPatternMatched;
  VoidCallback? onMotionDetected;
  Function(String)? onGestureLog;

  // ==================== INITIALIZATION ====================

  Future<bool> initialize() async {
    try {
      debugPrint(' Initializing Gesture Control Service...');

      await _loadSettings();

      if (_isShakeEnabled || _isMotionEnabled) {
        _startAccelerometer();
      }

      debugPrint(' Gesture Control Service initialized');
      return true;
    } catch (e) {
      debugPrint(' Gesture Control initialization error: $e');
      return false;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isShakeEnabled = prefs.getBool('shake_enabled') ?? false;
    _isTapPatternEnabled = prefs.getBool('tap_pattern_enabled') ?? false;
    _isMotionEnabled = prefs.getBool('motion_enabled') ?? false;

    final patternString = prefs.getString('secret_pattern');
    if (patternString != null) {
      _secretPattern = patternString.split(',').map(int.parse).toList();
    }

    debugPrint(' Loaded settings: shake=$_isShakeEnabled, tap=$_isTapPatternEnabled, motion=$_isMotionEnabled');
  }

  // ==================== 1. SHAKE DETECTION ====================

  void _startAccelerometer() {
    _accelerometerSubscription?.cancel();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (_isShakeEnabled) {
        _detectShake(event);
      }

      if (_isMotionEnabled) {
        _detectMotion(event);
      }
    });

    debugPrint(' Accelerometer started');
  }

  void _detectShake(AccelerometerEvent event) {
    final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);

    if (magnitude > _shakeThreshold * _shakeThreshold) {
      final now = DateTime.now();

      if (_lastShakeTime == null || now.difference(_lastShakeTime!) > const Duration(milliseconds: 500)) {
        _shakeCount++;
        _lastShakeTime = now;

        debugPrint(' Shake detected: count=$_shakeCount');

        // Reset timer
        _shakeResetTimer?.cancel();
        _shakeResetTimer = Timer(const Duration(seconds: 2), () {
          if (_shakeCount >= 3) {
            _triggerShakePanic();
          }
          _shakeCount = 0;
        });
      }
    }
  }

  void _triggerShakePanic() {
    debugPrint(' Shake panic triggered!');
    _vibrate();
    onShakeDetected?.call();
    onGestureLog?.call('Shake panic activated (${_shakeCount} shakes)');
    _shakeCount = 0;
  }

  Future<void> setShakeEnabled(bool enabled) async {
    _isShakeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shake_enabled', enabled);

    if (enabled) {
      _startAccelerometer();
    }

    debugPrint(' Shake detection: $enabled');
  }

  bool isShakeEnabled() => _isShakeEnabled;

  // ==================== 2. TAP PATTERN DETECTION ====================

  void registerTap(int tapCount) {
    if (!_isTapPatternEnabled) return;

    final now = DateTime.now();
    _currentPattern.add(tapCount);
    _tapTimes.add(now);

    debugPrint(' Tap registered: $tapCount (pattern: $_currentPattern)');

    // Reset timer
    _patternResetTimer?.cancel();
    _patternResetTimer = Timer(const Duration(seconds: 3), () {
      _currentPattern.clear();
      _tapTimes.clear();
    });

    // Check if pattern matches
    if (_currentPattern.length == _secretPattern.length) {
      if (_patternsMatch()) {
        _triggerPatternPanic();
      }
      _currentPattern.clear();
      _tapTimes.clear();
    }
  }

  bool _patternsMatch() {
    if (_currentPattern.length != _secretPattern.length) return false;

    for (int i = 0; i < _currentPattern.length; i++) {
      if (_currentPattern[i] != _secretPattern[i]) return false;
    }

    return true;
  }

  void _triggerPatternPanic() {
    debugPrint(' Tap pattern panic triggered!');
    _vibrate();
    onPatternMatched?.call();
    onGestureLog?.call('Tap pattern matched: ${_secretPattern.join("-")}');
  }

  Future<void> setTapPatternEnabled(bool enabled) async {
    _isTapPatternEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tap_pattern_enabled', enabled);

    debugPrint(' Tap pattern detection: $enabled');
  }

  Future<void> setSecretPattern(List<int> pattern) async {
    _secretPattern = pattern;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secret_pattern', pattern.join(','));

    debugPrint(' Secret pattern updated: $pattern');
  }

  bool isTapPatternEnabled() => _isTapPatternEnabled;
  List<int> getSecretPattern() => _secretPattern;
  List<int> getCurrentPattern() => _currentPattern;

  // ==================== 3. SCREEN GESTURES ====================

  bool detectSwipePattern(String direction, double velocity) {
    debugPrint(' Swipe detected: $direction (velocity: ${velocity.toStringAsFixed(2)})');

    // Example: Fast upward swipe
    if (direction == 'up' && velocity > 1000) {
      onGestureLog?.call('Emergency swipe detected');
      return true;
    }

    return false;
  }

  bool detectDrawPattern(List<Offset> points) {
    // Simplified: Check if drawing pattern matches emergency symbol
    // In production, use path matching algorithms

    if (points.length < 10) return false;

    // Example: Check for "SOS" pattern or specific shape
    debugPrint(' Draw pattern detected: ${points.length} points');

    return false;
  }

  // ==================== 4. MOTION DETECTION ====================

  void _detectMotion(AccelerometerEvent event) {
    final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);

    if (magnitude > 5.0) {
      final now = DateTime.now();

      if (_lastMotionTime == null || now.difference(_lastMotionTime!) > const Duration(seconds: 5)) {
        _isMotionActive = true;
        _lastMotionTime = now;

        debugPrint(' Motion detected');
        onMotionDetected?.call();
        onGestureLog?.call('Motion detected');
      }
    }
  }

  Future<void> setMotionEnabled(bool enabled) async {
    _isMotionEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('motion_enabled', enabled);

    if (enabled) {
      _startAccelerometer();
    }

    debugPrint(' Motion detection: $enabled');
  }

  bool isMotionEnabled() => _isMotionEnabled;
  bool isMotionActive() => _isMotionActive;

  // ==================== VIBRATION ====================

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getGestureStats() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'shake_triggers': prefs.getInt('shake_triggers') ?? 0,
      'pattern_triggers': prefs.getInt('pattern_triggers') ?? 0,
      'motion_triggers': prefs.getInt('motion_triggers') ?? 0,
      'total_gestures': prefs.getInt('total_gestures') ?? 0,
    };
  }

  Future<void> incrementGestureStat(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${type}_triggers';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);

    final total = prefs.getInt('total_gestures') ?? 0;
    await prefs.setInt('total_gestures', total + 1);
  }

  // ==================== CLEANUP ====================

  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _shakeResetTimer?.cancel();
    _patternResetTimer?.cancel();
    debugPrint(' Gesture Control Service disposed');
  }
}

/// ==================== GESTURE MODELS ====================

class GestureEvent {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  GestureEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

enum GestureType {
  shake,
  tapPattern,
  swipe,
  draw,
  motion,
}

class TapPattern {
  final List<int> pattern;
  final String name;
  final String description;

  TapPattern({
    required this.pattern,
    required this.name,
    required this.description,
  });

  static List<TapPattern> getPresetPatterns() {
    return [
      TapPattern(
        pattern: [1, 2, 1],
        name: 'SOS Pattern',
        description: 'Single, Double, Single tap',
      ),
      TapPattern(
        pattern: [3, 3, 3],
        name: 'Triple Tap',
        description: 'Three triple taps',
      ),
      TapPattern(
        pattern: [1, 1, 1, 1],
        name: 'Four Taps',
        description: 'Four single taps',
      ),
      TapPattern(
        pattern: [2, 1, 2],
        name: 'Double-Single-Double',
        description: 'Double, Single, Double tap',
      ),
      TapPattern(
        pattern: [1, 3, 1],
        name: 'Morse SOS',
        description: 'Single, Triple, Single tap',
      ),
    ];
  }
}

class Offset {
  final double dx;
  final double dy;

  const Offset(this.dx, this.dy);
}