import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

/// ==================== SHAKE DETECTION SERVICE ====================
///
/// ACCELEROMETER-BASED SHAKE DETECTION
/// Complete shake-to-alert panic trigger system:
/// - Real-time accelerometer monitoring
/// - Configurable sensitivity levels
/// - False positive prevention
/// - Pattern recognition
/// - Haptic feedback
/// - Auto-trigger panic on shake
///
/// 6-HOUR SPRINT - HOUR 1
/// ================================================================

// ==================== SHAKE SENSITIVITY ====================

enum ShakeSensitivity {
  light, // Gentle shake (threshold: 8)
  medium, // Normal shake (threshold: 12)
  hard, // Strong shake (threshold: 18)
  disabled, // Shake detection off
}

extension ShakeSensitivityExtension on ShakeSensitivity {
  double get threshold {
    switch (this) {
      case ShakeSensitivity.light:
        return 8.0;
      case ShakeSensitivity.medium:
        return 12.0;
      case ShakeSensitivity.hard:
        return 18.0;
      case ShakeSensitivity.disabled:
        return double.infinity;
    }
  }

  String get displayName {
    switch (this) {
      case ShakeSensitivity.light:
        return 'Light (Gentle Shake)';
      case ShakeSensitivity.medium:
        return 'Medium (Normal Shake)';
      case ShakeSensitivity.hard:
        return 'Hard (Strong Shake)';
      case ShakeSensitivity.disabled:
        return 'Disabled';
    }
  }

  String get description {
    switch (this) {
      case ShakeSensitivity.light:
        return 'Triggers with gentle shaking';
      case ShakeSensitivity.medium:
        return 'Triggers with normal shaking';
      case ShakeSensitivity.hard:
        return 'Triggers only with strong shaking';
      case ShakeSensitivity.disabled:
        return 'Shake detection turned off';
    }
  }

  Color get color {
    switch (this) {
      case ShakeSensitivity.light:
        return Colors.green;
      case ShakeSensitivity.medium:
        return Colors.orange;
      case ShakeSensitivity.hard:
        return Colors.red;
      case ShakeSensitivity.disabled:
        return Colors.grey;
    }
  }
}

// ==================== SHAKE EVENT ====================

class ShakeEvent {
  final DateTime timestamp;
  final double magnitude;
  final ShakeSensitivity sensitivity;
  final bool triggeredPanic;

  ShakeEvent({
    required this.timestamp,
    required this.magnitude,
    required this.sensitivity,
    required this.triggeredPanic,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'magnitude': magnitude,
      'sensitivity': sensitivity.toString(),
      'triggeredPanic': triggeredPanic,
    };
  }
}

// ==================== SHAKE DETECTION SERVICE ====================

class ShakeDetectionService {
  // State
  bool _isInitialized = false;
  bool _isEnabled = false;
  bool _isMonitoring = false;

  ShakeSensitivity _sensitivity = ShakeSensitivity.medium;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Shake detection parameters
  static const int _shakeDetectionWindowMs = 500; // Time window for shake detection
  static const int _minimumShakeCount = 2; // Minimum shakes to trigger
  static const int _cooldownMs = 3000; // Cooldown between triggers (3 seconds)

  DateTime? _lastShakeTime;
  DateTime? _lastTriggerTime;
  int _shakeCount = 0;
  double _lastMagnitude = 0;

  final List<ShakeEvent> _shakeHistory = [];

  // Callbacks
  Function()? onShakeDetected;
  Function(ShakeEvent event)? onShakeTriggered;
  Function(String message)? onLog;
  Function(String error)? onError;

  // Getters
  bool isInitialized() => _isInitialized;
  bool isEnabled() => _isEnabled;
  bool isMonitoring() => _isMonitoring;
  ShakeSensitivity getSensitivity() => _sensitivity;
  List<ShakeEvent> getShakeHistory() => List.unmodifiable(_shakeHistory);

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(' Initializing Shake Detection Service...');

      // Load saved settings
      await _loadSettings();

      _isInitialized = true;
      debugPrint(' Shake Detection Service initialized');

      // Auto-start if enabled
      if (_isEnabled) {
        await startMonitoring();
      }
    } catch (e) {
      debugPrint(' Shake Detection initialization error: $e');
      onError?.call('Failed to initialize shake detection: $e');
      rethrow;
    }
  }

  void dispose() {
    stopMonitoring();
    _shakeHistory.clear();
    _isInitialized = false;
    debugPrint(' Shake Detection Service disposed');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _isEnabled = prefs.getBool('shake_detection_enabled') ?? false;

    final sensitivityString = prefs.getString('shake_sensitivity') ?? 'medium';
    _sensitivity = ShakeSensitivity.values.firstWhere(
          (s) => s.toString().split('.').last == sensitivityString,
      orElse: () => ShakeSensitivity.medium,
    );

    debugPrint(' Loaded settings: enabled=$_isEnabled, sensitivity=$_sensitivity');
  }

  // ==================== MONITORING ====================

  /// Start shake detection monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring || !_isEnabled) return;

    try {
      debugPrint(' Starting shake monitoring (sensitivity: ${_sensitivity.displayName})');

      _accelerometerSubscription = accelerometerEvents.listen(
        _handleAccelerometerEvent,
        onError: (error) {
          debugPrint(' Accelerometer error: $error');
          onError?.call('Accelerometer error: $error');
        },
      );

      _isMonitoring = true;
      onLog?.call('Shake detection monitoring started');
      debugPrint(' Shake monitoring active');
    } catch (e) {
      debugPrint(' Failed to start monitoring: $e');
      onError?.call('Failed to start shake monitoring: $e');
      rethrow;
    }
  }

  /// Stop shake detection monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isMonitoring = false;

    _shakeCount = 0;
    _lastShakeTime = null;

    onLog?.call('Shake detection monitoring stopped');
    debugPrint(' Shake monitoring stopped');
  }

  /// Handle accelerometer data
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Calculate magnitude of acceleration vector
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Remove gravity (9.8 m/s²)
    final normalizedMagnitude = magnitude - 9.8;

    // Check if magnitude exceeds threshold
    if (normalizedMagnitude.abs() > _sensitivity.threshold) {
      _detectShake(normalizedMagnitude.abs());
    }
  }

  /// Detect shake pattern
  void _detectShake(double magnitude) {
    final now = DateTime.now();

    // Check cooldown period
    if (_lastTriggerTime != null) {
      final timeSinceLastTrigger = now.difference(_lastTriggerTime!).inMilliseconds;
      if (timeSinceLastTrigger < _cooldownMs) {
        return; // Still in cooldown
      }
    }

    // Check if within detection window
    if (_lastShakeTime != null) {
      final timeSinceLastShake = now.difference(_lastShakeTime!).inMilliseconds;

      if (timeSinceLastShake < _shakeDetectionWindowMs) {
        // Within window, increment shake count
        _shakeCount++;
        _lastMagnitude = max(_lastMagnitude, magnitude);

        debugPrint(' Shake detected: count=$_shakeCount, magnitude=${magnitude.toStringAsFixed(2)}');

        // Check if enough shakes to trigger
        if (_shakeCount >= _minimumShakeCount) {
          _triggerShake(now, _lastMagnitude);
        }
      } else {
        // Outside window, reset
        _shakeCount = 1;
        _lastMagnitude = magnitude;
      }
    } else {
      // First shake
      _shakeCount = 1;
      _lastMagnitude = magnitude;
    }

    _lastShakeTime = now;
  }

  /// Trigger shake event
  void _triggerShake(DateTime timestamp, double magnitude) {
    debugPrint(' SHAKE TRIGGER! Magnitude: ${magnitude.toStringAsFixed(2)}, Sensitivity: ${_sensitivity.displayName}');

    // Create shake event
    final event = ShakeEvent(
      timestamp: timestamp,
      magnitude: magnitude,
      sensitivity: _sensitivity,
      triggeredPanic: true,
    );

    // Add to history
    _shakeHistory.insert(0, event);
    if (_shakeHistory.length > 50) {
      _shakeHistory.removeLast();
    }

    // Reset counters
    _shakeCount = 0;
    _lastTriggerTime = timestamp;

    // Notify listeners
    onShakeDetected?.call();
    onShakeTriggered?.call(event);
    onLog?.call('Shake detected! Triggering panic alert...');
  }

  // ==================== SETTINGS ====================

  /// Enable shake detection
  Future<void> enable() async {
    _isEnabled = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shake_detection_enabled', true);

    onLog?.call('Shake detection enabled');
    debugPrint(' Shake detection enabled');

    await startMonitoring();
  }

  /// Disable shake detection
  Future<void> disable() async {
    _isEnabled = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shake_detection_enabled', false);

    onLog?.call('Shake detection disabled');
    debugPrint(' Shake detection disabled');

    await stopMonitoring();
  }

  /// Set sensitivity level
  Future<void> setSensitivity(ShakeSensitivity sensitivity) async {
    _sensitivity = sensitivity;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shake_sensitivity', sensitivity.toString().split('.').last);

    onLog?.call('Sensitivity set to: ${sensitivity.displayName}');
    debugPrint(' Sensitivity changed to: ${sensitivity.displayName}');

    // Restart monitoring if active
    if (_isMonitoring) {
      await stopMonitoring();
      await startMonitoring();
    }
  }

  // ==================== TESTING ====================

  /// Test shake detection with simulated shake
  Future<void> testShake() async {
    if (!_isEnabled) {
      onLog?.call('Shake detection is disabled. Enable it first.');
      return;
    }

    debugPrint(' Testing shake detection...');
    onLog?.call('Testing shake detection...');

    // Simulate shake
    final now = DateTime.now();
    final testMagnitude = _sensitivity.threshold + 2.0;

    _detectShake(testMagnitude);
    await Future.delayed(const Duration(milliseconds: 100));
    _detectShake(testMagnitude);
    await Future.delayed(const Duration(milliseconds: 100));
    _detectShake(testMagnitude);

    onLog?.call('Shake test completed');
  }

  // ==================== STATISTICS ====================

  Map<String, dynamic> getStatistics() {
    final totalShakes = _shakeHistory.length;
    final triggeredPanics = _shakeHistory.where((e) => e.triggeredPanic).length;

    return {
      'totalShakes': totalShakes,
      'triggeredPanics': triggeredPanics,
      'currentSensitivity': _sensitivity.toString().split('.').last,
      'isEnabled': _isEnabled,
      'isMonitoring': _isMonitoring,
      'averageMagnitude': _shakeHistory.isEmpty
          ? 0.0
          : _shakeHistory.map((e) => e.magnitude).reduce((a, b) => a + b) / _shakeHistory.length,
    };
  }

  /// Clear shake history
  void clearHistory() {
    _shakeHistory.clear();
    debugPrint(' Shake history cleared');
  }

  // ==================== CALIBRATION ====================

  /// Auto-calibrate sensitivity based on user feedback
  Future<void> calibrate() async {
    debugPrint(' Calibrating shake detection...');
    onLog?.call('Calibration started. Shake your device normally 3 times.');

    final List<double> calibrationReadings = [];
    int shakeCount = 0;

    final subscription = accelerometerEvents.listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final normalized = magnitude - 9.8;

      if (normalized.abs() > 5.0) {
        calibrationReadings.add(normalized.abs());
        shakeCount++;
        debugPrint(' Calibration shake $shakeCount recorded: ${normalized.abs().toStringAsFixed(2)}');
      }
    });

    // Wait for 3 shakes or 10 seconds
    await Future.delayed(const Duration(seconds: 10));
    await subscription.cancel();

    if (calibrationReadings.length >= 3) {
      final average = calibrationReadings.reduce((a, b) => a + b) / calibrationReadings.length;

      // Determine best sensitivity
      ShakeSensitivity recommended;
      if (average < 10) {
        recommended = ShakeSensitivity.light;
      } else if (average < 15) {
        recommended = ShakeSensitivity.medium;
      } else {
        recommended = ShakeSensitivity.hard;
      }

      await setSensitivity(recommended);
      onLog?.call('Calibration complete! Recommended: ${recommended.displayName}');
      debugPrint(' Calibration complete: ${recommended.displayName} (avg: ${average.toStringAsFixed(2)})');
    } else {
      onLog?.call('Calibration failed. Not enough shakes detected.');
      debugPrint(' Calibration failed: insufficient data');
    }
  }

  // ==================== UTILITY ====================

  /// Get time since last trigger
  Duration? getTimeSinceLastTrigger() {
    if (_lastTriggerTime == null) return null;
    return DateTime.now().difference(_lastTriggerTime!);
  }

  /// Check if in cooldown period
  bool isInCooldown() {
    if (_lastTriggerTime == null) return false;
    final timeSince = DateTime.now().difference(_lastTriggerTime!).inMilliseconds;
    return timeSince < _cooldownMs;
  }

  /// Get cooldown remaining
  Duration getCooldownRemaining() {
    if (!isInCooldown()) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastTriggerTime!).inMilliseconds;
    final remaining = _cooldownMs - elapsed;
    return Duration(milliseconds: max(0, remaining));
  }
}