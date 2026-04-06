import 'package:torch_light/torch_light.dart';
import 'dart:async';

class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  bool _isFlashing = false;
  Timer? _flashTimer;
  int _cycleCount = 0;
  int _maxCycles = 0;

  // Morse code timing (in milliseconds)
  static const int dotDuration = 200; // Short flash (·)
  static const int dashDuration = 600; // Long flash (—)
  static const int symbolGap = 200; // Gap between dots/dashes
  static const int letterGap = 600; // Gap between letters
  static const int cycleGap = 2000; // Gap between SOS cycles

  // SOS pattern: · · · (S) — — — (O) · · · (S)
  static const List<Map<String, dynamic>> sosPattern = [
    // Letter S: · · ·
    {'type': 'dot', 'duration': dotDuration},
    {'type': 'gap', 'duration': symbolGap},
    {'type': 'dot', 'duration': dotDuration},
    {'type': 'gap', 'duration': symbolGap},
    {'type': 'dot', 'duration': dotDuration},
    {'type': 'gap', 'duration': letterGap},

    // Letter O: — — —
    {'type': 'dash', 'duration': dashDuration},
    {'type': 'gap', 'duration': symbolGap},
    {'type': 'dash', 'duration': dashDuration},
    {'type': 'gap', 'duration': symbolGap},
    {'type': 'dash', 'duration': dashDuration},
    {'type': 'gap', 'duration': letterGap},

    // Letter S: · · ·
    {'type': 'dot', 'duration': dotDuration},
    {'type': 'gap', 'duration': symbolGap},
    {'type': 'dot', 'duration': dotDuration},
    {'type': 'gap', 'duration': symbolGap},
    {'type': 'dot', 'duration': dotDuration},
    {'type': 'gap', 'duration': cycleGap},
  ];

  // Check if flashlight is available
  Future<bool> isFlashlightAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (e) {
      print(' Error checking flashlight: $e');
      return false;
    }
  }

  // Turn flashlight on
  Future<bool> turnOn() async {
    try {
      await TorchLight.enableTorch();
      return true;
    } catch (e) {
      print(' Error turning on flashlight: $e');
      return false;
    }
  }

  // Turn flashlight off
  Future<bool> turnOff() async {
    try {
      await TorchLight.disableTorch();
      return true;
    } catch (e) {
      print(' Error turning off flashlight: $e');
      return false;
    }
  }

  // Start SOS flashing
  Future<bool> startSOS({int cycles = 0}) async {
    try {
      // Check if already flashing
      if (_isFlashing) {
        print(' SOS already in progress');
        return false;
      }

      // Check if flashlight is available
      final available = await isFlashlightAvailable();
      if (!available) {
        print(' Flashlight not available');
        return false;
      }

      print('========================================');
      print(' STARTING SOS SIGNAL');
      print('Cycles: ${cycles == 0 ? "Infinite" : cycles}');
      print('Pattern: · · · — — — · · · (SOS)');
      print('========================================');

      _isFlashing = true;
      _cycleCount = 0;
      _maxCycles = cycles;

      // Start the SOS pattern
      _flashSOSPattern();

      return true;
    } catch (e) {
      print(' Error starting SOS: $e');
      _isFlashing = false;
      return false;
    }
  }

  // Flash the SOS pattern
  Future<void> _flashSOSPattern() async {
    if (!_isFlashing) return;

    print(' Starting SOS cycle ${_cycleCount + 1}${_maxCycles > 0 ? "/$_maxCycles" : ""}');

    for (int i = 0; i < sosPattern.length; i++) {
      if (!_isFlashing) break;

      final step = sosPattern[i];
      final type = step['type'];
      final duration = step['duration'] as int;

      if (type == 'dot' || type == 'dash') {
        // Turn on flashlight
        await turnOn();
        print(' ${type == 'dot' ? '·' : '—'} Flash ON (${duration}ms)');
        await Future.delayed(Duration(milliseconds: duration));

        // Turn off flashlight
        await turnOff();
      } else if (type == 'gap') {
        // Wait (flashlight off)
        await Future.delayed(Duration(milliseconds: duration));
      }
    }

    _cycleCount++;

    // Check if we should continue
    if (_maxCycles > 0 && _cycleCount >= _maxCycles) {
      print(' SOS completed $_cycleCount cycles');
      stopSOS();
    } else if (_isFlashing) {
      // Continue with next cycle
      _flashSOSPattern();
    }
  }

  // Stop SOS flashing
  Future<void> stopSOS() async {
    print(' Stopping SOS signal...');
    _isFlashing = false;
    _flashTimer?.cancel();
    _flashTimer = null;

    // Make sure flashlight is off
    await turnOff();

    print('========================================');
    print(' SOS STOPPED');
    print('Total cycles completed: $_cycleCount');
    print('========================================');
  }

  // Get current status
  Map<String, dynamic> getStatus() {
    return {
      'isFlashing': _isFlashing,
      'cycleCount': _cycleCount,
      'maxCycles': _maxCycles,
      'isInfinite': _maxCycles == 0,
    };
  }

  // Check if SOS is currently active
  bool get isActive => _isFlashing;

  // Get total duration for one SOS cycle (in milliseconds)
  static int get cycleDuration {
    int total = 0;
    for (final step in sosPattern) {
      total += step['duration'] as int;
    }
    return total;
  }

  // Dispose and cleanup
  void dispose() {
    stopSOS();
  }
}