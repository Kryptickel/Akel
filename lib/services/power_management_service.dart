import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'battery_service.dart';

enum PowerMode {
  normal,
  lowPower,
  ultraLowPower,
  emergencyReserve,
}

class BatteryStats {
  final int currentLevel;
  final bool isCharging;
  final PowerMode currentMode;
  final DateTime timestamp;
  final double? temperature;

  BatteryStats({
    required this.currentLevel,
    required this.isCharging,
    required this.currentMode,
    required this.timestamp,
    this.temperature,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentLevel': currentLevel,
      'isCharging': isCharging,
      'currentMode': _modeToString(currentMode),
      'timestamp': FieldValue.serverTimestamp(),
      'temperature': temperature,
    };
  }

  static String _modeToString(PowerMode mode) {
    switch (mode) {
      case PowerMode.normal:
        return 'normal';
      case PowerMode.lowPower:
        return 'lowPower';
      case PowerMode.ultraLowPower:
        return 'ultraLowPower';
      case PowerMode.emergencyReserve:
        return 'emergencyReserve';
    }
  }
}

class PowerManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BatteryService _batteryService = BatteryService();

  static const String _powerModeKey = 'power_mode';
  static const String _autoLowPowerKey = 'auto_low_power';
  static const String _lowPowerThresholdKey = 'low_power_threshold';
  static const String _ultraLowPowerThresholdKey = 'ultra_low_power_threshold';
  static const String _emergencyReserveThresholdKey = 'emergency_reserve_threshold';

  // Get current power mode
  Future<PowerMode> getCurrentPowerMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_powerModeKey) ?? 'normal';
      return _stringToMode(modeString);
    } catch (e) {
      debugPrint(' Get current power mode error: $e');
      return PowerMode.normal;
    }
  }

  // Set power mode
  Future<bool> setPowerMode(PowerMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_powerModeKey, _modeToString(mode));

      debugPrint(' Power mode set to: ${_modeToString(mode)}');
      return true;
    } catch (e) {
      debugPrint(' Set power mode error: $e');
      return false;
    }
  }

  // Enable auto power saving
  Future<bool> setAutoLowPower({
    required bool enabled,
    int lowPowerThreshold = 30,
    int ultraLowPowerThreshold = 15,
    int emergencyReserveThreshold = 5,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoLowPowerKey, enabled);
      await prefs.setInt(_lowPowerThresholdKey, lowPowerThreshold);
      await prefs.setInt(_ultraLowPowerThresholdKey, ultraLowPowerThreshold);
      await prefs.setInt(_emergencyReserveThresholdKey, emergencyReserveThreshold);

      debugPrint(' Auto low power ${enabled ? "enabled" : "disabled"}');
      return true;
    } catch (e) {
      debugPrint(' Set auto low power error: $e');
      return false;
    }
  }

  // Check and apply auto power saving
  Future<PowerMode?> checkAndApplyAutoPowerSaving() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoEnabled = prefs.getBool(_autoLowPowerKey) ?? false;

      if (!autoEnabled) return null;

      final batteryLevel = await _batteryService.getBatteryLevel();
      final isCharging = await _batteryService.isCharging();

      // Don't apply power saving if charging
      if (isCharging) return null;

      final lowPowerThreshold = prefs.getInt(_lowPowerThresholdKey) ?? 30;
      final ultraLowPowerThreshold = prefs.getInt(_ultraLowPowerThresholdKey) ?? 15;
      final emergencyReserveThreshold = prefs.getInt(_emergencyReserveThresholdKey) ?? 5;

      PowerMode? newMode;

      if (batteryLevel <= emergencyReserveThreshold) {
        newMode = PowerMode.emergencyReserve;
      } else if (batteryLevel <= ultraLowPowerThreshold) {
        newMode = PowerMode.ultraLowPower;
      } else if (batteryLevel <= lowPowerThreshold) {
        newMode = PowerMode.lowPower;
      }

      if (newMode != null) {
        await setPowerMode(newMode);
        debugPrint(' Auto power mode changed to: ${_modeToString(newMode)}');
        return newMode;
      }

      return null;
    } catch (e) {
      debugPrint(' Check auto power saving error: $e');
      return null;
    }
  }

  // Get battery statistics
  Future<Map<String, dynamic>> getBatteryStatistics(String userId) async {
    try {
      final batteryLevel = await _batteryService.getBatteryLevel();
      final isCharging = await _batteryService.isCharging();
      final currentMode = await getCurrentPowerMode();

      // Get battery history from last 24 hours
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final historySnapshot = await _firestore
          .collection('battery_history')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: yesterday)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final historyCount = historySnapshot.docs.length;

      // Calculate average battery level
      int totalLevel = batteryLevel;
      for (final doc in historySnapshot.docs) {
        final data = doc.data();
        totalLevel += (data['batteryLevel'] as int? ?? 0);
      }
      final avgLevel = historyCount > 0 ? totalLevel ~/ (historyCount + 1) : batteryLevel;

      // Get power saving status
      final prefs = await SharedPreferences.getInstance();
      final autoEnabled = prefs.getBool(_autoLowPowerKey) ?? false;

      return {
        'currentLevel': batteryLevel,
        'isCharging': isCharging,
        'currentMode': _modeToString(currentMode),
        'averageLevel24h': avgLevel,
        'historyCount': historyCount,
        'autoPowerSaving': autoEnabled,
        'batteryHealth': _getBatteryHealth(batteryLevel, isCharging),
      };
    } catch (e) {
      debugPrint(' Get battery statistics error: $e');
      return {};
    }
  }

  // Log battery status
  Future<void> logBatteryStatus(String userId) async {
    try {
      final batteryLevel = await _batteryService.getBatteryLevel();
      final isCharging = await _batteryService.isCharging();
      final currentMode = await getCurrentPowerMode();

      final stats = BatteryStats(
        currentLevel: batteryLevel,
        isCharging: isCharging,
        currentMode: currentMode,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('battery_history').add({
        'userId': userId,
        'batteryLevel': stats.currentLevel,
        'isCharging': stats.isCharging,
        'powerMode': stats.toMap()['currentMode'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(' Battery status logged: $batteryLevel%');
    } catch (e) {
      debugPrint(' Log battery status error: $e');
    }
  }

  // Get power mode features
  Map<String, bool> getPowerModeFeatures(PowerMode mode) {
    switch (mode) {
      case PowerMode.normal:
        return {
          'backgroundSync': true,
          'locationTracking': true,
          'pushNotifications': true,
          'vibration': true,
          'sounds': true,
          'animations': true,
        };
      case PowerMode.lowPower:
        return {
          'backgroundSync': false,
          'locationTracking': true,
          'pushNotifications': true,
          'vibration': true,
          'sounds': true,
          'animations': false,
        };
      case PowerMode.ultraLowPower:
        return {
          'backgroundSync': false,
          'locationTracking': false,
          'pushNotifications': true,
          'vibration': false,
          'sounds': true,
          'animations': false,
        };
      case PowerMode.emergencyReserve:
        return {
          'backgroundSync': false,
          'locationTracking': false,
          'pushNotifications': true,
          'vibration': false,
          'sounds': false,
          'animations': false,
        };
    }
  }

  // Get power saving tips
  List<String> getPowerSavingTips(int batteryLevel, bool isCharging) {
    final tips = <String>[];

    if (batteryLevel < 20 && !isCharging) {
      tips.add('Battery critically low - consider charging soon');
      tips.add('Enable Emergency Reserve Mode to preserve battery');
    }

    if (batteryLevel < 50 && !isCharging) {
      tips.add('Enable Low Power Mode to extend battery life');
      tips.add('Reduce screen brightness');
      tips.add('Disable background app refresh');
    }

    if (!isCharging) {
      tips.add('Close unused apps');
      tips.add('Turn off location services when not needed');
      tips.add('Reduce auto-lock time');
    }

    if (isCharging && batteryLevel > 80) {
      tips.add('Battery is charging well');
      tips.add('Consider unplugging at 80-90% for battery health');
    }

    return tips;
  }

  // Helper methods
  PowerMode _stringToMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'lowpower':
        return PowerMode.lowPower;
      case 'ultralowpower':
        return PowerMode.ultraLowPower;
      case 'emergencyreserve':
        return PowerMode.emergencyReserve;
      default:
        return PowerMode.normal;
    }
  }

  String _modeToString(PowerMode mode) {
    switch (mode) {
      case PowerMode.normal:
        return 'normal';
      case PowerMode.lowPower:
        return 'lowPower';
      case PowerMode.ultraLowPower:
        return 'ultraLowPower';
      case PowerMode.emergencyReserve:
        return 'emergencyReserve';
    }
  }

  String _getBatteryHealth(int level, bool isCharging) {
    if (isCharging) return 'Charging';
    if (level > 80) return 'Excellent';
    if (level > 50) return 'Good';
    if (level > 20) return 'Fair';
    return 'Critical';
  }

  // Get power mode icon
  static String getPowerModeIcon(PowerMode mode) {
    switch (mode) {
      case PowerMode.normal:
        return ' ';
      case PowerMode.lowPower:
        return ' ';
      case PowerMode.ultraLowPower:
        return ' ';
      case PowerMode.emergencyReserve:
        return ' ';
    }
  }

  // Get power mode label
  static String getPowerModeLabel(PowerMode mode) {
    switch (mode) {
      case PowerMode.normal:
        return 'Normal Mode';
      case PowerMode.lowPower:
        return 'Low Power Mode';
      case PowerMode.ultraLowPower:
        return 'Ultra Low Power';
      case PowerMode.emergencyReserve:
        return 'Emergency Reserve';
    }
  }

  // Get power mode description
  static String getPowerModeDescription(PowerMode mode) {
    switch (mode) {
      case PowerMode.normal:
        return 'All features enabled, normal battery usage';
      case PowerMode.lowPower:
        return 'Reduced background activity, extended battery life';
      case PowerMode.ultraLowPower:
        return 'Minimal features, maximum battery preservation';
      case PowerMode.emergencyReserve:
        return 'Emergency features only, critical battery saving';
    }
  }

  // Get power mode color
  static String getPowerModeColor(PowerMode mode) {
    switch (mode) {
      case PowerMode.normal:
        return '#4CAF50'; // Green
      case PowerMode.lowPower:
        return '#FF9800'; // Orange
      case PowerMode.ultraLowPower:
        return '#F44336'; // Red
      case PowerMode.emergencyReserve:
        return '#9C27B0'; // Purple
    }
  }
}