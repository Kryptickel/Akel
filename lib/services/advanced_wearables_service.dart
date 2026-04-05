import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class ECGReading {
  final String id;
  final DateTime timestamp;
  final List<double> waveform; // ECG data points
  final String rhythm; // normal, afib, irregular
  final int heartRate;

  ECGReading({
    required this.id,
    required this.timestamp,
    required this.waveform,
    required this.rhythm,
    required this.heartRate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'waveform': waveform,
    'rhythm': rhythm,
    'heartRate': heartRate,
  };

  factory ECGReading.fromJson(Map<String, dynamic> json) => ECGReading(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    waveform: List<double>.from(json['waveform']),
    rhythm: json['rhythm'],
    heartRate: json['heartRate'],
  );
}

class SpO2Reading {
  final DateTime timestamp;
  final int oxygenSaturation; // percentage
  final String status; // normal, low, critical

  SpO2Reading({
    required this.timestamp,
    required this.oxygenSaturation,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'oxygenSaturation': oxygenSaturation,
    'status': status,
  };

  factory SpO2Reading.fromJson(Map<String, dynamic> json) => SpO2Reading(
    timestamp: DateTime.parse(json['timestamp']),
    oxygenSaturation: json['oxygenSaturation'],
    status: json['status'],
  );
}

class BodyTemperature {
  final DateTime timestamp;
  final double temperature; // Celsius
  final String location; // wrist, forehead, core
  final bool isFever;

  BodyTemperature({
    required this.timestamp,
    required this.temperature,
    required this.location,
    required this.isFever,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'temperature': temperature,
    'location': location,
    'isFever': isFever,
  };

  factory BodyTemperature.fromJson(Map<String, dynamic> json) =>
      BodyTemperature(
        timestamp: DateTime.parse(json['timestamp']),
        temperature: json['temperature'],
        location: json['location'],
        isFever: json['isFever'],
      );
}

class StressLevel {
  final DateTime timestamp;
  final int level; // 0-100
  final String category; // low, medium, high
  final int heartRateVariability;

  StressLevel({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.heartRateVariability,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level,
    'category': category,
    'heartRateVariability': heartRateVariability,
  };

  factory StressLevel.fromJson(Map<String, dynamic> json) => StressLevel(
    timestamp: DateTime.parse(json['timestamp']),
    level: json['level'],
    category: json['category'],
    heartRateVariability: json['heartRateVariability'],
  );
}

class SleepData {
  final DateTime date;
  final int totalMinutes;
  final int deepSleepMinutes;
  final int remSleepMinutes;
  final int lightSleepMinutes;
  final int awakeMinutes;
  final double sleepScore; // 0-100

  SleepData({
    required this.date,
    required this.totalMinutes,
    required this.deepSleepMinutes,
    required this.remSleepMinutes,
    required this.lightSleepMinutes,
    required this.awakeMinutes,
    required this.sleepScore,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'totalMinutes': totalMinutes,
    'deepSleepMinutes': deepSleepMinutes,
    'remSleepMinutes': remSleepMinutes,
    'lightSleepMinutes': lightSleepMinutes,
    'awakeMinutes': awakeMinutes,
    'sleepScore': sleepScore,
  };

  factory SleepData.fromJson(Map<String, dynamic> json) => SleepData(
    date: DateTime.parse(json['date']),
    totalMinutes: json['totalMinutes'],
    deepSleepMinutes: json['deepSleepMinutes'],
    remSleepMinutes: json['remSleepMinutes'],
    lightSleepMinutes: json['lightSleepMinutes'],
    awakeMinutes: json['awakeMinutes'],
    sleepScore: json['sleepScore'],
  );
}

class AdvancedWearablesService {
  static final AdvancedWearablesService _instance =
  AdvancedWearablesService._internal();
  factory AdvancedWearablesService() => _instance;
  AdvancedWearablesService._internal();

  static const String _ecgKey = 'ecg_readings';
  static const String _spo2Key = 'spo2_readings';
  static const String _tempKey = 'temperature_readings';
  static const String _stressKey = 'stress_readings';
  static const String _sleepKey = 'sleep_data';
  static const String _settingsKey = 'advanced_wearables_settings';

  List<ECGReading> _ecgReadings = [];
  List<SpO2Reading> _spo2Readings = [];
  List<BodyTemperature> _temperatureReadings = [];
  List<StressLevel> _stressReadings = [];
  List<SleepData> _sleepData = [];

  // Settings
  bool _ecgMonitoringEnabled = true;
  bool _spo2MonitoringEnabled = true;
  bool _temperatureMonitoringEnabled = true;
  bool _stressMonitoringEnabled = true;
  bool _sleepTrackingEnabled = true;
  int _lowSpO2Threshold = 90;
  double _feverThreshold = 37.8;

  Timer? _monitoringTimer;

  /// Initialize service
  Future<void> initialize() async {
    await _loadSettings();
    await _loadECGReadings();
    await _loadSpO2Readings();
    await _loadTemperatureReadings();
    await _loadStressReadings();
    await _loadSleepData();
    _startMonitoring();
    debugPrint(' Advanced Wearables Service initialized');
  }

  /// ECG Methods
  Future<void> takeECGReading() async {
    if (!_ecgMonitoringEnabled) return;

    debugPrint(' Taking ECG reading...');

    // Mock ECG waveform (normally would come from device)
    final waveform = List.generate(100, (i) {
      final base = 0.5;
      final qrs = i > 40 && i < 60 ? (i - 50).abs() / 10 : 0.0;
      return base + qrs + (DateTime.now().millisecond % 10) / 100;
    });

    final reading = ECGReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      waveform: waveform,
      rhythm: 'normal', // Would be analyzed in real app
      heartRate: 72,
    );

    _ecgReadings.add(reading);
    if (_ecgReadings.length > 50) {
      _ecgReadings = _ecgReadings.sublist(_ecgReadings.length - 50);
    }

    await _saveECGReadings();
    debugPrint(' ECG reading complete: ${reading.rhythm}');
  }

  List<ECGReading> getECGReadings() => _ecgReadings;

  ECGReading? getLatestECG() {
    if (_ecgReadings.isEmpty) return null;
    return _ecgReadings.last;
  }

  /// SpO2 Methods
  Future<void> updateSpO2(int percentage) async {
    if (!_spo2MonitoringEnabled) return;

    String status;
    if (percentage >= 95) {
      status = 'normal';
    } else if (percentage >= _lowSpO2Threshold) {
      status = 'low';
    } else {
      status = 'critical';
      debugPrint(' CRITICAL: Low SpO2 - $percentage%');
    }

    final reading = SpO2Reading(
      timestamp: DateTime.now(),
      oxygenSaturation: percentage,
      status: status,
    );

    _spo2Readings.add(reading);
    if (_spo2Readings.length > 1000) {
      _spo2Readings = _spo2Readings.sublist(_spo2Readings.length - 1000);
    }

    await _saveSpO2Readings();
  }

  int getCurrentSpO2() {
    if (_spo2Readings.isEmpty) return 98;
    return _spo2Readings.last.oxygenSaturation;
  }

  List<SpO2Reading> getSpO2History({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _spo2Readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  /// Temperature Methods
  Future<void> updateTemperature(double temp) async {
    if (!_temperatureMonitoringEnabled) return;

    final isFever = temp >= _feverThreshold;

    final reading = BodyTemperature(
      timestamp: DateTime.now(),
      temperature: temp,
      location: 'wrist',
      isFever: isFever,
    );

    _temperatureReadings.add(reading);
    if (_temperatureReadings.length > 1000) {
      _temperatureReadings =
          _temperatureReadings.sublist(_temperatureReadings.length - 1000);
    }

    await _saveTemperatureReadings();

    if (isFever) {
      debugPrint(' FEVER DETECTED: ${temp.toStringAsFixed(1)}°C');
    }
  }

  double getCurrentTemperature() {
    if (_temperatureReadings.isEmpty) return 36.5;
    return _temperatureReadings.last.temperature;
  }

  List<BodyTemperature> getTemperatureHistory({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _temperatureReadings
        .where((r) => r.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Stress Methods
  Future<void> updateStress(int level) async {
    if (!_stressMonitoringEnabled) return;

    String category;
    if (level < 30) {
      category = 'low';
    } else if (level < 70) {
      category = 'medium';
    } else {
      category = 'high';
    }

    final reading = StressLevel(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      heartRateVariability: 50 + (100 - level), // Mock HRV
    );

    _stressReadings.add(reading);
    if (_stressReadings.length > 1000) {
      _stressReadings = _stressReadings.sublist(_stressReadings.length - 1000);
    }

    await _saveStressReadings();
  }

  int getCurrentStressLevel() {
    if (_stressReadings.isEmpty) return 30;
    return _stressReadings.last.level;
  }

  List<StressLevel> getStressHistory({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _stressReadings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  /// Sleep Methods
  Future<void> addSleepData(SleepData data) async {
    if (!_sleepTrackingEnabled) return;

    // Remove existing data for the same date
    _sleepData.removeWhere(
          (s) =>
      s.date.year == data.date.year &&
          s.date.month == data.date.month &&
          s.date.day == data.date.day,
    );

    _sleepData.add(data);
    await _saveSleepData();
  }

  SleepData? getLastNightSleep() {
    if (_sleepData.isEmpty) return null;
    return _sleepData.last;
  }

  List<SleepData> getSleepHistory({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _sleepData.where((s) => s.date.isAfter(cutoff)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get comprehensive statistics
  Map<String, dynamic> getStatistics() {
    final spo2History = getSpO2History(hours: 24);
    final avgSpO2 = spo2History.isNotEmpty
        ? spo2History.fold<int>(0, (sum, r) => sum + r.oxygenSaturation) /
        spo2History.length
        : 0;

    final tempHistory = getTemperatureHistory(hours: 24);
    final avgTemp = tempHistory.isNotEmpty
        ? tempHistory.fold<double>(0, (sum, r) => sum + r.temperature) /
        tempHistory.length
        : 0;

    final stressHistory = getStressHistory(hours: 24);
    final avgStress = stressHistory.isNotEmpty
        ? stressHistory.fold<int>(0, (sum, r) => sum + r.level) /
        stressHistory.length
        : 0;

    return {
      'totalECGReadings': _ecgReadings.length,
      'currentSpO2': getCurrentSpO2(),
      'averageSpO2': avgSpO2.round(),
      'currentTemp': getCurrentTemperature(),
      'averageTemp': avgTemp,
      'currentStress': getCurrentStressLevel(),
      'averageStress': avgStress.round(),
      'sleepRecords': _sleepData.length,
      'lastSleepScore': getLastNightSleep()?.sleepScore ?? 0,
    };
  }

  /// Settings
  bool isECGMonitoringEnabled() => _ecgMonitoringEnabled;
  bool isSpO2MonitoringEnabled() => _spo2MonitoringEnabled;
  bool isTemperatureMonitoringEnabled() => _temperatureMonitoringEnabled;
  bool isStressMonitoringEnabled() => _stressMonitoringEnabled;
  bool isSleepTrackingEnabled() => _sleepTrackingEnabled;
  int getLowSpO2Threshold() => _lowSpO2Threshold;
  double getFeverThreshold() => _feverThreshold;

  Future<void> updateSettings({
    bool? ecgMonitoring,
    bool? spo2Monitoring,
    bool? temperatureMonitoring,
    bool? stressMonitoring,
    bool? sleepTracking,
    int? lowSpO2Threshold,
    double? feverThreshold,
  }) async {
    if (ecgMonitoring != null) _ecgMonitoringEnabled = ecgMonitoring;
    if (spo2Monitoring != null) _spo2MonitoringEnabled = spo2Monitoring;
    if (temperatureMonitoring != null) {
      _temperatureMonitoringEnabled = temperatureMonitoring;
    }
    if (stressMonitoring != null) _stressMonitoringEnabled = stressMonitoring;
    if (sleepTracking != null) _sleepTrackingEnabled = sleepTracking;
    if (lowSpO2Threshold != null) _lowSpO2Threshold = lowSpO2Threshold;
    if (feverThreshold != null) _feverThreshold = feverThreshold;
    await _saveSettings();
  }

  /// Private methods
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      // Mock continuous monitoring
      final random = DateTime.now().millisecond;
      updateSpO2(95 + (random % 5));
      updateTemperature(36.0 + (random % 20) / 10);
      updateStress(20 + (random % 60));
    });
  }

  /// Storage methods
  Future<void> _loadECGReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson = prefs.getStringList(_ecgKey);
      if (readingsJson != null) {
        _ecgReadings = readingsJson
            .map((str) => ECGReading.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load ECG readings error: $e');
    }
  }

  Future<void> _saveECGReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson =
      _ecgReadings.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_ecgKey, readingsJson);
    } catch (e) {
      debugPrint(' Save ECG readings error: $e');
    }
  }

  Future<void> _loadSpO2Readings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson = prefs.getStringList(_spo2Key);
      if (readingsJson != null) {
        _spo2Readings = readingsJson
            .map((str) => SpO2Reading.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load SpO2 readings error: $e');
    }
  }

  Future<void> _saveSpO2Readings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson =
      _spo2Readings.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_spo2Key, readingsJson);
    } catch (e) {
      debugPrint(' Save SpO2 readings error: $e');
    }
  }

  Future<void> _loadTemperatureReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson = prefs.getStringList(_tempKey);
      if (readingsJson != null) {
        _temperatureReadings = readingsJson
            .map((str) => BodyTemperature.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load temperature readings error: $e');
    }
  }

  Future<void> _saveTemperatureReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson =
      _temperatureReadings.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_tempKey, readingsJson);
    } catch (e) {
      debugPrint(' Save temperature readings error: $e');
    }
  }

  Future<void> _loadStressReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson = prefs.getStringList(_stressKey);
      if (readingsJson != null) {
        _stressReadings = readingsJson
            .map((str) => StressLevel.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load stress readings error: $e');
    }
  }

  Future<void> _saveStressReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson =
      _stressReadings.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_stressKey, readingsJson);
    } catch (e) {
      debugPrint(' Save stress readings error: $e');
    }
  }

  Future<void> _loadSleepData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getStringList(_sleepKey);
      if (dataJson != null) {
        _sleepData = dataJson
            .map((str) => SleepData.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load sleep data error: $e');
    }
  }

  Future<void> _saveSleepData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = _sleepData.map((s) => json.encode(s.toJson())).toList();
      await prefs.setStringList(_sleepKey, dataJson);
    } catch (e) {
      debugPrint(' Save sleep data error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = json.decode(settingsJson);
        _ecgMonitoringEnabled = settings['ecgMonitoringEnabled'] ?? true;
        _spo2MonitoringEnabled = settings['spo2MonitoringEnabled'] ?? true;
        _temperatureMonitoringEnabled =
            settings['temperatureMonitoringEnabled'] ?? true;
        _stressMonitoringEnabled = settings['stressMonitoringEnabled'] ?? true;
        _sleepTrackingEnabled = settings['sleepTrackingEnabled'] ?? true;
        _lowSpO2Threshold = settings['lowSpO2Threshold'] ?? 90;
        _feverThreshold = settings['feverThreshold'] ?? 37.8;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'ecgMonitoringEnabled': _ecgMonitoringEnabled,
        'spo2MonitoringEnabled': _spo2MonitoringEnabled,
        'temperatureMonitoringEnabled': _temperatureMonitoringEnabled,
        'stressMonitoringEnabled': _stressMonitoringEnabled,
        'sleepTrackingEnabled': _sleepTrackingEnabled,
        'lowSpO2Threshold': _lowSpO2Threshold,
        'feverThreshold': _feverThreshold,
      };
      await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint(' Save settings error: $e');
    }
  }

  /// Dispose
  void dispose() {
    _monitoringTimer?.cancel();
  }
}