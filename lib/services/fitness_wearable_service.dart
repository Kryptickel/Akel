import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

enum FitnessBrand {
  fitbit,
  garmin,
  whoop,
  polar,
  suunto,
  other,
}

class FitnessDevice {
  final String id;
  final String name;
  final FitnessBrand brand;
  final bool isConnected;
  final DateTime lastSync;
  final int batteryLevel;

  FitnessDevice({
    required this.id,
    required this.name,
    required this.brand,
    required this.isConnected,
    required this.lastSync,
    required this.batteryLevel,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand.index,
    'isConnected': isConnected,
    'lastSync': lastSync.toIso8601String(),
    'batteryLevel': batteryLevel,
  };

  factory FitnessDevice.fromJson(Map<String, dynamic> json) => FitnessDevice(
    id: json['id'],
    name: json['name'],
    brand: FitnessBrand.values[json['brand']],
    isConnected: json['isConnected'],
    lastSync: DateTime.parse(json['lastSync']),
    batteryLevel: json['batteryLevel'],
  );
}

class HeartRateReading {
  final DateTime timestamp;
  final int bpm;
  final String zone; // resting, fat-burn, cardio, peak

  HeartRateReading({
    required this.timestamp,
    required this.bpm,
    required this.zone,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'bpm': bpm,
    'zone': zone,
  };

  factory HeartRateReading.fromJson(Map<String, dynamic> json) =>
      HeartRateReading(
        timestamp: DateTime.parse(json['timestamp']),
        bpm: json['bpm'],
        zone: json['zone'],
      );
}

class ActivityData {
  final DateTime date;
  final int steps;
  final double distance; // kilometers
  final int caloriesBurned;
  final int activeMinutes;
  final int restingHeartRate;

  ActivityData({
    required this.date,
    required this.steps,
    required this.distance,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.restingHeartRate,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'steps': steps,
    'distance': distance,
    'caloriesBurned': caloriesBurned,
    'activeMinutes': activeMinutes,
    'restingHeartRate': restingHeartRate,
  };

  factory ActivityData.fromJson(Map<String, dynamic> json) => ActivityData(
    date: DateTime.parse(json['date']),
    steps: json['steps'],
    distance: json['distance'],
    caloriesBurned: json['caloriesBurned'],
    activeMinutes: json['activeMinutes'],
    restingHeartRate: json['restingHeartRate'],
  );
}

class HeartRateAlert {
  final String id;
  final DateTime timestamp;
  final int bpm;
  final String alertType; // high, low, irregular
  final bool emergencyContacted;

  HeartRateAlert({
    required this.id,
    required this.timestamp,
    required this.bpm,
    required this.alertType,
    required this.emergencyContacted,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'bpm': bpm,
    'alertType': alertType,
    'emergencyContacted': emergencyContacted,
  };

  factory HeartRateAlert.fromJson(Map<String, dynamic> json) =>
      HeartRateAlert(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        bpm: json['bpm'],
        alertType: json['alertType'],
        emergencyContacted: json['emergencyContacted'],
      );
}

class FitnessWearableService {
  static final FitnessWearableService _instance =
  FitnessWearableService._internal();
  factory FitnessWearableService() => _instance;
  FitnessWearableService._internal();

  static const String _devicesKey = 'fitness_devices';
  static const String _heartRateKey = 'heart_rate_history';
  static const String _activityKey = 'activity_data';
  static const String _alertsKey = 'heart_rate_alerts';
  static const String _settingsKey = 'fitness_wearable_settings';

  List<FitnessDevice> _devices = [];
  List<HeartRateReading> _heartRateHistory = [];
  List<ActivityData> _activityHistory = [];
  List<HeartRateAlert> _alerts = [];

  // Settings
  bool _heartRateMonitoringEnabled = true;
  int _highHeartRateThreshold = 140;
  int _lowHeartRateThreshold = 45;
  bool _activityTrackingEnabled = true;
  bool _sleepMonitoringEnabled = true;
  int _dailyStepGoal = 10000;

  Timer? _syncTimer;

  /// Initialize service
  Future<void> initialize() async {
    await _loadSettings();
    await _loadDevices();
    await _loadHeartRateHistory();
    await _loadActivityData();
    await _loadAlerts();
    _startPeriodicSync();
    debugPrint(' Fitness Wearable Service initialized');
  }

  /// Get connected devices
  List<FitnessDevice> getDevices() => _devices;

  /// Get primary device
  FitnessDevice? getPrimaryDevice() {
    if (_devices.isEmpty) return null;
    return _devices.firstWhere(
          (d) => d.isConnected,
      orElse: () => _devices.first,
    );
  }

  /// Connect device
  Future<void> connectDevice(FitnessBrand brand) async {
    String name;
    switch (brand) {
      case FitnessBrand.fitbit:
        name = 'Fitbit Charge 6';
        break;
      case FitnessBrand.garmin:
        name = 'Garmin Venu 3';
        break;
      case FitnessBrand.whoop:
        name = 'Whoop 4.0';
        break;
      case FitnessBrand.polar:
        name = 'Polar H10';
        break;
      case FitnessBrand.suunto:
        name = 'Suunto 9 Peak';
        break;
      default:
        name = 'Unknown Device';
    }

    final device = FitnessDevice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      brand: brand,
      isConnected: true,
      lastSync: DateTime.now(),
      batteryLevel: 85,
    );

    _devices.add(device);
    await _saveDevices();
    debugPrint(' Device connected: $name');
  }

  /// Disconnect device
  Future<void> disconnectDevice(String deviceId) async {
    _devices.removeWhere((d) => d.id == deviceId);
    await _saveDevices();
    debugPrint(' Device disconnected');
  }

  /// Get current heart rate
  int getCurrentHeartRate() {
    if (_heartRateHistory.isEmpty) return 72;
    return _heartRateHistory.last.bpm;
  }

  /// Add heart rate reading
  Future<void> addHeartRateReading(int bpm) async {
    final zone = _getHeartRateZone(bpm);
    final reading = HeartRateReading(
      timestamp: DateTime.now(),
      bpm: bpm,
      zone: zone,
    );

    _heartRateHistory.add(reading);

    // Keep only last 1000 readings
    if (_heartRateHistory.length > 1000) {
      _heartRateHistory = _heartRateHistory.sublist(_heartRateHistory.length - 1000);
    }

    await _saveHeartRateHistory();

    // Check for anomalies
    await _checkHeartRateAnomaly(bpm);
  }

  /// Check for heart rate anomalies
  Future<void> _checkHeartRateAnomaly(int bpm) async {
    if (!_heartRateMonitoringEnabled) return;

    String? alertType;
    if (bpm > _highHeartRateThreshold) {
      alertType = 'high';
    } else if (bpm < _lowHeartRateThreshold) {
      alertType = 'low';
    }

    if (alertType != null) {
      final alert = HeartRateAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        bpm: bpm,
        alertType: alertType,
        emergencyContacted: true,
      );

      _alerts.add(alert);
      await _saveAlerts();

      debugPrint(' HEART RATE ALERT: $alertType - $bpm BPM');
    }
  }

  /// Get heart rate history
  List<HeartRateReading> getHeartRateHistory({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _heartRateHistory.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  /// Get today's activity
  ActivityData? getTodayActivity() {
    final today = DateTime.now();
    try {
      return _activityHistory.firstWhere(
            (a) =>
        a.date.year == today.year &&
            a.date.month == today.month &&
            a.date.day == today.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// Add activity data
  Future<void> addActivityData(ActivityData data) async {
    // Remove existing data for the same date
    _activityHistory.removeWhere(
          (a) =>
      a.date.year == data.date.year &&
          a.date.month == data.date.month &&
          a.date.day == data.date.day,
    );

    _activityHistory.add(data);
    await _saveActivityData();
  }

  /// Get activity history
  List<ActivityData> getActivityHistory({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _activityHistory
        .where((a) => a.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get heart rate alerts
  List<HeartRateAlert> getAlerts() => _alerts;

  /// Clear alerts
  Future<void> clearAlerts() async {
    _alerts.clear();
    await _saveAlerts();
  }

  /// Sync with device (mock)
  Future<void> syncWithDevice() async {
    if (_devices.isEmpty) return;

    debugPrint(' Syncing with fitness device...');

    // Mock data - generate realistic readings
    final random = DateTime.now().millisecond;
    final hr = 60 + (random % 40); // 60-100 BPM
    await addHeartRateReading(hr);

    // Mock today's activity
    final todayActivity = ActivityData(
      date: DateTime.now(),
      steps: 5000 + (random % 5000),
      distance: (5.0 + (random % 5)).toDouble(),
      caloriesBurned: 1500 + (random % 1000),
      activeMinutes: 30 + (random % 60),
      restingHeartRate: 60 + (random % 20),
    );
    await addActivityData(todayActivity);

    // Update device sync time
    for (int i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      _devices[i] = FitnessDevice(
        id: device.id,
        name: device.name,
        brand: device.brand,
        isConnected: device.isConnected,
        lastSync: DateTime.now(),
        batteryLevel: (device.batteryLevel - 1).clamp(0, 100),
      );
    }

    await _saveDevices();
    debugPrint(' Sync complete');
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final todayActivity = getTodayActivity();
    final recentHR = getHeartRateHistory(hours: 1);
    final avgHR = recentHR.isNotEmpty
        ? recentHR.fold<int>(0, (sum, r) => sum + r.bpm) / recentHR.length
        : 0;

    return {
      'connectedDevices': _devices.length,
      'currentHeartRate': getCurrentHeartRate(),
      'averageHeartRate': avgHR.round(),
      'todaySteps': todayActivity?.steps ?? 0,
      'todayDistance': todayActivity?.distance ?? 0.0,
      'todayCalories': todayActivity?.caloriesBurned ?? 0,
      'totalAlerts': _alerts.length,
      'recentAlerts': _alerts
          .where((a) => DateTime.now().difference(a.timestamp).inDays < 7)
          .length,
    };
  }

  /// Settings
  bool isHeartRateMonitoringEnabled() => _heartRateMonitoringEnabled;
  int getHighHeartRateThreshold() => _highHeartRateThreshold;
  int getLowHeartRateThreshold() => _lowHeartRateThreshold;
  bool isActivityTrackingEnabled() => _activityTrackingEnabled;
  int getDailyStepGoal() => _dailyStepGoal;

  Future<void> updateSettings({
    bool? heartRateMonitoring,
    int? highThreshold,
    int? lowThreshold,
    bool? activityTracking,
    int? stepGoal,
  }) async {
    if (heartRateMonitoring != null) {
      _heartRateMonitoringEnabled = heartRateMonitoring;
    }
    if (highThreshold != null) _highHeartRateThreshold = highThreshold;
    if (lowThreshold != null) _lowHeartRateThreshold = lowThreshold;
    if (activityTracking != null) _activityTrackingEnabled = activityTracking;
    if (stepGoal != null) _dailyStepGoal = stepGoal;
    await _saveSettings();
  }

  /// Get brand icon
  IconData getBrandIcon(FitnessBrand brand) {
    switch (brand) {
      case FitnessBrand.fitbit:
        return Icons.watch;
      case FitnessBrand.garmin:
        return Icons.directions_run;
      case FitnessBrand.whoop:
        return Icons.favorite;
      case FitnessBrand.polar:
        return Icons.monitor_heart;
      case FitnessBrand.suunto:
        return Icons.explore;
      default:
        return Icons.fitness_center;
    }
  }

  /// Get brand color
  Color getBrandColor(FitnessBrand brand) {
    switch (brand) {
      case FitnessBrand.fitbit:
        return const Color(0xFF00B0B9);
      case FitnessBrand.garmin:
        return const Color(0xFF007CC3);
      case FitnessBrand.whoop:
        return const Color(0xFFFF0000);
      case FitnessBrand.polar:
        return const Color(0xFFE63946);
      case FitnessBrand.suunto:
        return const Color(0xFFFF6B00);
      default:
        return Colors.grey;
    }
  }

  /// Private methods
  String _getHeartRateZone(int bpm) {
    if (bpm < 100) return 'resting';
    if (bpm < 120) return 'fat-burn';
    if (bpm < 150) return 'cardio';
    return 'peak';
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncWithDevice();
    });
  }

  /// Storage methods
  Future<void> _loadDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = prefs.getStringList(_devicesKey);
      if (devicesJson != null) {
        _devices = devicesJson
            .map((str) => FitnessDevice.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load devices error: $e');
    }
  }

  Future<void> _saveDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = _devices.map((d) => json.encode(d.toJson())).toList();
      await prefs.setStringList(_devicesKey, devicesJson);
    } catch (e) {
      debugPrint(' Save devices error: $e');
    }
  }

  Future<void> _loadHeartRateHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_heartRateKey);
      if (historyJson != null) {
        _heartRateHistory = historyJson
            .map((str) => HeartRateReading.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load heart rate history error: $e');
    }
  }

  Future<void> _saveHeartRateHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
      _heartRateHistory.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_heartRateKey, historyJson);
    } catch (e) {
      debugPrint(' Save heart rate history error: $e');
    }
  }

  Future<void> _loadActivityData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activityJson = prefs.getStringList(_activityKey);
      if (activityJson != null) {
        _activityHistory = activityJson
            .map((str) => ActivityData.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load activity data error: $e');
    }
  }

  Future<void> _saveActivityData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activityJson =
      _activityHistory.map((a) => json.encode(a.toJson())).toList();
      await prefs.setStringList(_activityKey, activityJson);
    } catch (e) {
      debugPrint(' Save activity data error: $e');
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getStringList(_alertsKey);
      if (alertsJson != null) {
        _alerts = alertsJson
            .map((str) => HeartRateAlert.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load alerts error: $e');
    }
  }

  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = _alerts.map((a) => json.encode(a.toJson())).toList();
      await prefs.setStringList(_alertsKey, alertsJson);
    } catch (e) {
      debugPrint(' Save alerts error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = json.decode(settingsJson);
        _heartRateMonitoringEnabled =
            settings['heartRateMonitoringEnabled'] ?? true;
        _highHeartRateThreshold = settings['highHeartRateThreshold'] ?? 140;
        _lowHeartRateThreshold = settings['lowHeartRateThreshold'] ?? 45;
        _activityTrackingEnabled = settings['activityTrackingEnabled'] ?? true;
        _sleepMonitoringEnabled = settings['sleepMonitoringEnabled'] ?? true;
        _dailyStepGoal = settings['dailyStepGoal'] ?? 10000;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'heartRateMonitoringEnabled': _heartRateMonitoringEnabled,
        'highHeartRateThreshold': _highHeartRateThreshold,
        'lowHeartRateThreshold': _lowHeartRateThreshold,
        'activityTrackingEnabled': _activityTrackingEnabled,
        'sleepMonitoringEnabled': _sleepMonitoringEnabled,
        'dailyStepGoal': _dailyStepGoal,
      };
      await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint(' Save settings error: $e');
    }
  }

  /// Dispose
  void dispose() {
    _syncTimer?.cancel();
  }
}