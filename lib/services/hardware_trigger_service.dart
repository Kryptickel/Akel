import 'package:flutter/foundation.dart'; // ✅ ADDED - for debugPrint
import 'package:flutter/services.dart';
import 'dart:async';
import 'vibration_service.dart';
import 'sound_service.dart';

/// Hardware Trigger Service
/// Handles volume button and power button panic triggers
class HardwareTriggerService {
  static final HardwareTriggerService _instance = HardwareTriggerService._internal();
  factory HardwareTriggerService() => _instance;
  HardwareTriggerService._internal();

  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

// Volume button tracking
  int _volumeButtonPresses = 0;
  Timer? _volumeResetTimer;
  DateTime? _lastVolumePress;

// Power button tracking
  int _powerButtonPresses = 0;
  Timer? _powerResetTimer;
  DateTime? _lastPowerPress;

// Callbacks
  VoidCallback? _onVolumePanicTriggered;
  VoidCallback? _onPowerPanicTriggered;

  bool _volumeTriggerEnabled = true;
  bool _powerTriggerEnabled = true;

// ==================== INITIALIZATION ====================

  /// Initialize hardware trigger listeners
  void initialize() {
    _setupVolumeListener();
    _setupPowerListener();
    if (kDebugMode) {
      print('🔧 Hardware Trigger Service initialized');
    }
  }

  /// Set volume panic callback
  void setOnVolumePanicTriggered(VoidCallback callback) {
    _onVolumePanicTriggered = callback;
  }

  /// Set power panic callback
  void setOnPowerPanicTriggered(VoidCallback callback) {
    _onPowerPanicTriggered = callback;
  }

// ==================== VOLUME BUTTON TRIGGER ====================

  void _setupVolumeListener() {
// Platform channel for volume button detection
    const platform = MethodChannel('com.akel.panic_button/hardware');

    platform.setMethodCallHandler((call) async {
      if (call.method == 'volumeButtonPressed') {
        _handleVolumePress();
      } else if (call.method == 'powerButtonPressed') {
        _handlePowerPress();
      }
    });
  }

  void _handleVolumePress() {
    if (!_volumeTriggerEnabled) return;

    final now = DateTime.now();

// Reset if more than 2 seconds since last press
    if (_lastVolumePress != null &&
        now.difference(_lastVolumePress!) > const Duration(seconds: 2)) {
      _volumeButtonPresses = 0;
    }

    _volumeButtonPresses++;
    _lastVolumePress = now;

// Light vibration on each press
    _vibrationService.light();

// Cancel previous reset timer
    _volumeResetTimer?.cancel();

// Check if we've hit 5 presses
    if (_volumeButtonPresses >= 5) {
      _triggerVolumePanic();
    } else {
// Reset counter after 2 seconds
      _volumeResetTimer = Timer(const Duration(seconds: 2), () {
        _volumeButtonPresses = 0;
      });
    }

    if (kDebugMode) {
      print('🔊 Volume press count: $_volumeButtonPresses/5');
    }
  }

  void _triggerVolumePanic() {
    if (kDebugMode) {
      print('🚨 VOLUME PANIC TRIGGERED!');
    }

    _vibrationService.panic();
    _soundService.playWarning();

    _volumeButtonPresses = 0;
    _volumeResetTimer?.cancel();

    _onVolumePanicTriggered?.call();
  }

// ==================== POWER BUTTON TRIGGER ====================

  void _setupPowerListener() {
// Already set up in volume listener
  }

  void _handlePowerPress() {
    if (!_powerTriggerEnabled) return;

    final now = DateTime.now();

// Reset if more than 1 second since last press
    if (_lastPowerPress != null &&
        now.difference(_lastPowerPress!) > const Duration(seconds: 1)) {
      _powerButtonPresses = 0;
    }

    _powerButtonPresses++;
    _lastPowerPress = now;

// Medium vibration on each press
    _vibrationService.medium();

// Cancel previous reset timer
    _powerResetTimer?.cancel();

// Check if we've hit 3 presses
    if (_powerButtonPresses >= 3) {
      _triggerPowerPanic();
    } else {
// Reset counter after 1 second
      _powerResetTimer = Timer(const Duration(seconds: 1), () {
        _powerButtonPresses = 0;
      });
    }

    if (kDebugMode) {
      print('⚡ Power press count: $_powerButtonPresses/3');
    }
  }

  void _triggerPowerPanic() {
    if (kDebugMode) {
      print('🚨 POWER BUTTON PANIC TRIGGERED!');
    }

    _vibrationService.panic();
    _soundService.playWarning();

    _powerButtonPresses = 0;
    _powerResetTimer?.cancel();

    _onPowerPanicTriggered?.call();
  }

// ==================== SETTINGS ====================

  /// Enable/disable volume trigger
  void setVolumeTriggerEnabled(bool enabled) {
    _volumeTriggerEnabled = enabled;
    if (kDebugMode) {
      print('🔊 Volume trigger: ${enabled ? "ENABLED" : "DISABLED"}');
    }
  }

  /// Enable/disable power trigger
  void setPowerTriggerEnabled(bool enabled) {
    _powerTriggerEnabled = enabled;
    if (kDebugMode) {
      print('⚡ Power trigger: ${enabled ? "ENABLED" : "DISABLED"}');
    }
  }

  /// Check if volume trigger is enabled
  bool get isVolumeTriggerEnabled => _volumeTriggerEnabled;

  /// Check if power trigger is enabled
  bool get isPowerTriggerEnabled => _powerTriggerEnabled;

// ==================== CLEANUP ====================

  void dispose() {
    _volumeResetTimer?.cancel();
    _powerResetTimer?.cancel();
  }
}