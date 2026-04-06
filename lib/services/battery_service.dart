import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  final Battery _battery = Battery();

  // Get current battery level (0-100)
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return 100; // Default to 100% if error
    }
  }

  // Get battery state (charging, full, discharging)
  Future<BatteryState> getBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (e) {
      return BatteryState.unknown;
    }
  }

  // Check if battery is low (below 20%)
  Future<bool> isLowBattery() async {
    final level = await getBatteryLevel();
    return level < 20;
  }

  // Check if battery is critical (below 10%)
  Future<bool> isCriticalBattery() async {
    final level = await getBatteryLevel();
    return level < 10;
  }

  // Check if charging
  Future<bool> isCharging() async {
    final state = await getBatteryState();
    return state == BatteryState.charging || state == BatteryState.full;
  }

  // Get battery color based on level
  static BatteryColor getBatteryColor(int level) {
    if (level >= 50) {
      return BatteryColor.good; // Green
    } else if (level >= 20) {
      return BatteryColor.medium; // Orange
    } else {
      return BatteryColor.low; // Red
    }
  }

  // Get battery icon based on level and charging state
  static BatteryIcon getBatteryIcon(int level, bool isCharging) {
    if (isCharging) {
      return BatteryIcon.charging;
    }

    if (level >= 90) {
      return BatteryIcon.full;
    } else if (level >= 50) {
      return BatteryIcon.high;
    } else if (level >= 20) {
      return BatteryIcon.medium;
    } else {
      return BatteryIcon.low;
    }
  }

  // Stream of battery state changes
  Stream<BatteryState> get onBatteryStateChanged {
    return _battery.onBatteryStateChanged;
  }
}

// Enums for battery visualization
enum BatteryColor {
  good, // Green (50-100%)
  medium, // Orange (20-49%)
  low, // Red (0-19%)
}

enum BatteryIcon {
  full, // 90-100%
  high, // 50-89%
  medium, // 20-49%
  low, // 0-19%
  charging, // Charging
}