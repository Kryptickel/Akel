import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class FallDetectionService {
  static final FallDetectionService _instance = FallDetectionService._internal();
  factory FallDetectionService() => _instance;
  FallDetectionService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isEnabled = false;
  bool _isFallDetected = false;

// Callback when fall is detected
  Function(BuildContext)? onFallDetected;

// Sensitivity levels
  static const double LOW_SENSITIVITY = 25.0; // Hard to trigger
  static const double MEDIUM_SENSITIVITY = 20.0; // Balanced
  static const double HIGH_SENSITIVITY = 15.0; // Easy to trigger

  double _sensitivity = MEDIUM_SENSITIVITY;

// Fall detection parameters
  static const double GRAVITY = 9.81;
  static const int FALL_THRESHOLD_MS = 500; // Time window for fall detection

  DateTime? _fallStartTime;
  bool _inFreeFall = false;
  List<double> _accelerationHistory = [];
  static const int HISTORY_SIZE = 10;

// Initialize fall detection
  Future<void> initialize() async {
    print('🏃 Initializing Fall Detection Service...');
  }

// Start monitoring for falls
  void startMonitoring(BuildContext context) {
    if (_isEnabled) {
      print('⚠️ Fall detection already running');
      return;
    }

    print('✅ Starting fall detection monitoring...');
    _isEnabled = true;
    _isFallDetected = false;

    _accelerometerSubscription = accelerometerEvents.listen(
          (AccelerometerEvent event) {
        _processAccelerometerData(event, context);
      },
      onError: (error) {
        print('❌ Accelerometer error: $error');
      },
    );

    print('📳 Fall detection is now active (sensitivity: ${_getSensitivityLabel()})');
  }

// Stop monitoring
  void stopMonitoring() {
    if (!_isEnabled) return;

    print('🛑 Stopping fall detection...');
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isEnabled = false;
    _isFallDetected = false;
    _inFreeFall = false;
    _fallStartTime = null;
    _accelerationHistory.clear();
    print('✅ Fall detection stopped');
  }

// Process accelerometer data
  void _processAccelerometerData(AccelerometerEvent event, BuildContext context) {
// Calculate total acceleration (magnitude)
    final double totalAcceleration = sqrt(
        event.x * event.x +
            event.y * event.y +
            event.z * event.z
    );

// Add to history
    _accelerationHistory.add(totalAcceleration);
    if (_accelerationHistory.length > HISTORY_SIZE) {
      _accelerationHistory.removeAt(0);
    }

// Detect free fall (low acceleration)
    if (totalAcceleration < GRAVITY * 0.5) {
      if (!_inFreeFall) {
        _inFreeFall = true;
        _fallStartTime = DateTime.now();
        print('📉 Free fall detected! Acceleration: ${totalAcceleration.toStringAsFixed(2)} m/s²');
      }
    }

// Detect impact (high acceleration after free fall)
    if (_inFreeFall && totalAcceleration > _sensitivity) {
      final duration = DateTime.now().difference(_fallStartTime!).inMilliseconds;

      if (duration < FALL_THRESHOLD_MS && !_isFallDetected) {
        print('💥 FALL DETECTED! Impact: ${totalAcceleration.toStringAsFixed(2)} m/s²');
        _onFallDetected(context);
      }

      _inFreeFall = false;
      _fallStartTime = null;
    }

// Reset free fall if too much time passed
    if (_inFreeFall && _fallStartTime != null) {
      final duration = DateTime.now().difference(_fallStartTime!).inMilliseconds;
      if (duration > FALL_THRESHOLD_MS) {
        _inFreeFall = false;
        _fallStartTime = null;
      }
    }
  }

// Handle fall detection
  void _onFallDetected(BuildContext context) {
    if (_isFallDetected) return; // Prevent multiple triggers

    _isFallDetected = true;
    print('🚨 FALL DETECTED - Triggering callback...');

// Call the callback
    if (onFallDetected != null) {
      onFallDetected!(context);
    }

// Reset after 10 seconds to allow re-detection
    Future.delayed(const Duration(seconds: 10), () {
      _isFallDetected = false;
    });
  }

// Set sensitivity
  void setSensitivity(double sensitivity) {
    _sensitivity = sensitivity;
    print('🎚️ Fall detection sensitivity set to: ${_getSensitivityLabel()}');
  }

  String _getSensitivityLabel() {
    if (_sensitivity == LOW_SENSITIVITY) return 'Low';
    if (_sensitivity == MEDIUM_SENSITIVITY) return 'Medium';
    if (_sensitivity == HIGH_SENSITIVITY) return 'High';
    return 'Custom';
  }

// Get current state
  bool get isEnabled => _isEnabled;
  bool get isFallDetected => _isFallDetected;
  double get sensitivity => _sensitivity;

// Dispose
  void dispose() {
    stopMonitoring();
  }
}