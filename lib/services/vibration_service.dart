import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VibrationService {
// Check if vibration is enabled in settings
  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('vibration_enabled') ?? true;
  }

// Check if device has vibration capability
  Future<bool> hasVibrator() async {
    try {
      return await Vibration.hasVibrator() ?? false;
    } catch (e) {
      return false;
    }
  }

// Light vibration for button taps (50ms)
  Future<void> light() async {
    final enabled = await isVibrationEnabled();
    if (!enabled) return;

    try {
      final hasVibration = await hasVibrator();
      if (hasVibration) {
        await Vibration.vibrate(duration: 50);
      }
    } catch (e) {
// Silently fail on web or unsupported platforms
    }
  }

// Medium vibration for interactions (100ms)
  Future<void> medium() async {
    final enabled = await isVibrationEnabled();
    if (!enabled) return;

    try {
      final hasVibration = await hasVibrator();
      if (hasVibration) {
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
// Silently fail
    }
  }

// Heavy vibration for important actions (200ms)
  Future<void> heavy() async {
    final enabled = await isVibrationEnabled();
    if (!enabled) return;

    try {
      final hasVibration = await hasVibrator();
      if (hasVibration) {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
// Silently fail
    }
  }

// Success pattern (short-short)
  Future<void> success() async {
    final enabled = await isVibrationEnabled();
    if (!enabled) return;

    try {
      final hasVibration = await hasVibrator();
      if (hasVibration) {
        await Vibration.vibrate(
          pattern: [0, 100, 100, 100],
          intensities: [0, 128, 0, 255],
        );
      }
    } catch (e) {
// Silently fail
    }
  }

// Error pattern (long vibration)
  Future<void> error() async {
    final enabled = await isVibrationEnabled();
    if (!enabled) return;

    try {
      final hasVibration = await hasVibrator();
      if (hasVibration) {
        await Vibration.vibrate(
          pattern: [0, 300],
          intensities: [0, 255],
        );
      }
    } catch (e) {
// Silently fail
    }
  }

// Warning pattern (triple short)
  Future<void> warning() async {
    final enabled = await isVibrationEnabled();
    if (!enabled) return;

    try {
      final hasVibration = await hasVibrator();
      if (hasVibration) {
        await Vibration.vibrate(
          pattern: [0, 100, 100, 100, 100, 100],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
    } catch (e) {
// Silently fail
    }
  }

// Panic alert pattern (continuous strong vibration)
  Future<void> panic() async {
    final enabled = await isVibrationEnabled();
    if (!enabled) return;

    try {
      final hasVibration = await hasVibrator();
      if (hasVibration) {
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
    } catch (e) {
// Silently fail
    }
  }

// Cancel any ongoing vibration
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
// Silently fail
    }
  }

  /// NEW: Emergency method required by UnifiedPanicManager
  Future<void> emergency() async {
    final enabled = await isVibrationEnabled();
    if (!enabled) return;

    try {
      final hasVibration = await hasVibrator();
      if (hasVibration) {
// Triggers a long, intense vibration for emergencies
        await Vibration.vibrate(
          pattern: [0, 1000, 500, 1000, 500, 1000],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
    } catch (e) {
// Silently fail
    }
  }
}