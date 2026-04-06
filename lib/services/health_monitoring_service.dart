import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class HealthMetric {
  final String id;
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String status; // normal, warning, critical
  final String category; // vital, fitness, wellness

  HealthMetric({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.status,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'category': category,
  };

  factory HealthMetric.fromJson(Map<String, dynamic> json) => HealthMetric(
    id: json['id'],
    name: json['name'],
    value: json['value'],
    unit: json['unit'],
    timestamp: DateTime.parse(json['timestamp']),
    status: json['status'],
    category: json['category'],
  );
}

class HealthAlert {
  final String id;
  final DateTime timestamp;
  final String metricName;
  final String severity; // info, warning, critical
  final String message;
  final bool acknowledged;

  HealthAlert({
    required this.id,
    required this.timestamp,
    required this.metricName,
    required this.severity,
    required this.message,
    this.acknowledged = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'metricName': metricName,
    'severity': severity,
    'message': message,
    'acknowledged': acknowledged,
  };

  factory HealthAlert.fromJson(Map<String, dynamic> json) => HealthAlert(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    metricName: json['metricName'],
    severity: json['severity'],
    message: json['message'],
    acknowledged: json['acknowledged'] ?? false,
  );
}

class HealthReport {
  final DateTime generatedAt;
  final Map<String, dynamic> summary;
  final List<String> recommendations;
  final double overallScore; // 0-100

  HealthReport({
    required this.generatedAt,
    required this.summary,
    required this.recommendations,
    required this.overallScore,
  });
}

class HealthMonitoringService {
  static final HealthMonitoringService _instance =
  HealthMonitoringService._internal();
  factory HealthMonitoringService() => _instance;
  HealthMonitoringService._internal();

  static const String _metricsKey = 'health_metrics';
  static const String _alertsKey = 'health_alerts';
  static const String _settingsKey = 'health_monitoring_settings';

  List<HealthMetric> _metrics = [];
  List<HealthAlert> _alerts = [];

  // Settings
  bool _continuousMonitoringEnabled = true;
  bool _alertNotificationsEnabled = true;
  bool _dailyReportEnabled = true;
  int _checkIntervalMinutes = 30;

  Timer? _monitoringTimer;

  /// Initialize service
  Future<void> initialize() async {
    await _loadSettings();
    await _loadMetrics();
    await _loadAlerts();
    _startContinuousMonitoring();
    debugPrint(' Health Monitoring Service initialized');
  }

  /// Add metric
  Future<void> addMetric(HealthMetric metric) async {
    _metrics.add(metric);

    // Keep only last 1000 metrics
    if (_metrics.length > 1000) {
      _metrics = _metrics.sublist(_metrics.length - 1000);
    }

    await _saveMetrics();

    // Check for alerts
    await _checkForAlerts(metric);
  }

  /// Get all metrics
  List<HealthMetric> getAllMetrics() => _metrics;

  /// Get metrics by category
  List<HealthMetric> getMetricsByCategory(String category) {
    return _metrics.where((m) => m.category == category).toList();
  }

  /// Get latest metric by name
  HealthMetric? getLatestMetric(String name) {
    try {
      return _metrics.reversed.firstWhere((m) => m.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get current vital signs
  Map<String, dynamic> getCurrentVitals() {
    return {
      'heartRate': getLatestMetric('Heart Rate')?.value ?? 72,
      'bloodPressureSystolic': getLatestMetric('BP Systolic')?.value ?? 120,
      'bloodPressureDiastolic': getLatestMetric('BP Diastolic')?.value ?? 80,
      'temperature': getLatestMetric('Temperature')?.value ?? 36.5,
      'spO2': getLatestMetric('SpO2')?.value ?? 98,
      'respiratoryRate': getLatestMetric('Respiratory Rate')?.value ?? 16,
    };
  }

  /// Get fitness metrics
  Map<String, dynamic> getFitnessMetrics() {
    return {
      'steps': getLatestMetric('Steps')?.value ?? 5000,
      'calories': getLatestMetric('Calories')?.value ?? 1800,
      'activeMinutes': getLatestMetric('Active Minutes')?.value ?? 45,
      'distance': getLatestMetric('Distance')?.value ?? 3.5,
      'floors': getLatestMetric('Floors')?.value ?? 8,
    };
  }

  /// Get wellness metrics
  Map<String, dynamic> getWellnessMetrics() {
    return {
      'sleepScore': getLatestMetric('Sleep Score')?.value ?? 75,
      'stressLevel': getLatestMetric('Stress Level')?.value ?? 35,
      'hrvScore': getLatestMetric('HRV Score')?.value ?? 65,
      'hydrationLevel': getLatestMetric('Hydration')?.value ?? 70,
      'nutritionScore': getLatestMetric('Nutrition')?.value ?? 80,
    };
  }

  /// Generate health report
  HealthReport generateHealthReport() {
    final vitals = getCurrentVitals();
    final fitness = getFitnessMetrics();
    final wellness = getWellnessMetrics();

    // Calculate overall health score
    double vitalScore = _calculateVitalScore(vitals);
    double fitnessScore = _calculateFitnessScore(fitness);
    double wellnessScore = _calculateWellnessScore(wellness);

    double overallScore = (vitalScore + fitnessScore + wellnessScore) / 3;

    // Generate recommendations
    List<String> recommendations = [];
    if (fitness['steps'] < 8000) {
      recommendations.add('Increase daily steps to at least 8,000');
    }
    if (wellness['sleepScore'] < 70) {
      recommendations.add('Improve sleep quality - aim for 7-9 hours');
    }
    if (wellness['stressLevel'] > 60) {
      recommendations.add('Practice stress management techniques');
    }
    if (fitness['activeMinutes'] < 30) {
      recommendations.add('Get 30+ minutes of moderate activity daily');
    }
    if (wellness['hydrationLevel'] < 60) {
      recommendations.add('Drink more water throughout the day');
    }

    return HealthReport(
      generatedAt: DateTime.now(),
      summary: {
        'vitals': vitals,
        'fitness': fitness,
        'wellness': wellness,
        'vitalScore': vitalScore,
        'fitnessScore': fitnessScore,
        'wellnessScore': wellnessScore,
      },
      recommendations: recommendations,
      overallScore: overallScore,
    );
  }

  /// Get health alerts
  List<HealthAlert> getAlerts({bool includeAcknowledged = false}) {
    if (includeAcknowledged) return _alerts;
    return _alerts.where((a) => !a.acknowledged).toList();
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = HealthAlert(
        id: _alerts[index].id,
        timestamp: _alerts[index].timestamp,
        metricName: _alerts[index].metricName,
        severity: _alerts[index].severity,
        message: _alerts[index].message,
        acknowledged: true,
      );
      await _saveAlerts();
    }
  }

  /// Get health trends
  Map<String, List<double>> getHealthTrends({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentMetrics = _metrics.where((m) => m.timestamp.isAfter(cutoff));

    Map<String, List<double>> trends = {};

    for (var metric in recentMetrics) {
      if (!trends.containsKey(metric.name)) {
        trends[metric.name] = [];
      }
      trends[metric.name]!.add(metric.value);
    }

    return trends;
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalMetrics': _metrics.length,
      'vitalsCount': getMetricsByCategory('vital').length,
      'fitnessCount': getMetricsByCategory('fitness').length,
      'wellnessCount': getMetricsByCategory('wellness').length,
      'activeAlerts': getAlerts().length,
      'totalAlerts': _alerts.length,
      'overallHealthScore': generateHealthReport().overallScore,
    };
  }

  /// Settings
  bool isContinuousMonitoringEnabled() => _continuousMonitoringEnabled;
  bool isAlertNotificationsEnabled() => _alertNotificationsEnabled;
  bool isDailyReportEnabled() => _dailyReportEnabled;
  int getCheckInterval() => _checkIntervalMinutes;

  Future<void> updateSettings({
    bool? continuousMonitoring,
    bool? alertNotifications,
    bool? dailyReport,
    int? checkInterval,
  }) async {
    if (continuousMonitoring != null) {
      _continuousMonitoringEnabled = continuousMonitoring;
    }
    if (alertNotifications != null) {
      _alertNotificationsEnabled = alertNotifications;
    }
    if (dailyReport != null) _dailyReportEnabled = dailyReport;
    if (checkInterval != null) _checkIntervalMinutes = checkInterval;

    await _saveSettings();

    // Restart monitoring with new interval
    _startContinuousMonitoring();
  }

  /// Private methods
  Future<void> _checkForAlerts(HealthMetric metric) async {
    if (metric.status == 'critical') {
      final alert = HealthAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        metricName: metric.name,
        severity: 'critical',
        message:
        '${metric.name} is at critical level: ${metric.value} ${metric.unit}',
      );
      _alerts.add(alert);
      await _saveAlerts();
      debugPrint(' CRITICAL ALERT: ${alert.message}');
    } else if (metric.status == 'warning') {
      final alert = HealthAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        metricName: metric.name,
        severity: 'warning',
        message:
        '${metric.name} is outside normal range: ${metric.value} ${metric.unit}',
      );
      _alerts.add(alert);
      await _saveAlerts();
      debugPrint(' WARNING: ${alert.message}');
    }
  }

  void _startContinuousMonitoring() {
    if (!_continuousMonitoringEnabled) return;

    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      Duration(minutes: _checkIntervalMinutes),
          (timer) async {
        // Mock continuous monitoring - would integrate with actual sensors
        await _updateMockMetrics();
      },
    );
  }

  Future<void> _updateMockMetrics() async {
    final random = DateTime.now().millisecond;

    // Mock vital signs
    await addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Heart Rate',
      value: (60 + (random % 40)).toDouble(),
      unit: 'BPM',
      timestamp: DateTime.now(),
      status: 'normal',
      category: 'vital',
    ));

    await addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'SpO2',
      value: (95 + (random % 5)).toDouble(),
      unit: '%',
      timestamp: DateTime.now(),
      status: 'normal',
      category: 'vital',
    ));
  }

  double _calculateVitalScore(Map<String, dynamic> vitals) {
    double score = 100.0;

    // Heart rate
    final hr = vitals['heartRate'];
    if (hr < 60 || hr > 100) score -= 10;

    // Blood pressure
    final systolic = vitals['bloodPressureSystolic'];
    final diastolic = vitals['bloodPressureDiastolic'];
    if (systolic > 140 || diastolic > 90) score -= 15;

    // SpO2
    final spo2 = vitals['spO2'];
    if (spo2 < 95) score -= 20;

    // Temperature
    final temp = vitals['temperature'];
    if (temp < 36.0 || temp > 37.5) score -= 10;

    return score.clamp(0, 100);
  }

  double _calculateFitnessScore(Map<String, dynamic> fitness) {
    double score = 0.0;

    // Steps (40 points max)
    final steps = fitness['steps'];
    score += (steps / 10000 * 40).clamp(0, 40);

    // Active minutes (30 points max)
    final activeMinutes = fitness['activeMinutes'];
    score += (activeMinutes / 60 * 30).clamp(0, 30);

    // Distance (20 points max)
    final distance = fitness['distance'];
    score += (distance / 5 * 20).clamp(0, 20);

    // Floors (10 points max)
    final floors = fitness['floors'];
    score += (floors / 10 * 10).clamp(0, 10);

    return score.clamp(0, 100);
  }

  double _calculateWellnessScore(Map<String, dynamic> wellness) {
    double score = 0.0;

    score += wellness['sleepScore'] * 0.3;
    score += (100 - wellness['stressLevel']) * 0.25;
    score += wellness['hrvScore'] * 0.2;
    score += wellness['hydrationLevel'] * 0.15;
    score += wellness['nutritionScore'] * 0.1;

    return score.clamp(0, 100);
  }

  /// Storage methods
  Future<void> _loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = prefs.getStringList(_metricsKey);
      if (metricsJson != null) {
        _metrics = metricsJson
            .map((str) => HealthMetric.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load metrics error: $e');
    }
  }

  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = _metrics.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_metricsKey, metricsJson);
    } catch (e) {
      debugPrint(' Save metrics error: $e');
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getStringList(_alertsKey);
      if (alertsJson != null) {
        _alerts = alertsJson
            .map((str) => HealthAlert.fromJson(json.decode(str)))
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
        _continuousMonitoringEnabled =
            settings['continuousMonitoringEnabled'] ?? true;
        _alertNotificationsEnabled =
            settings['alertNotificationsEnabled'] ?? true;
        _dailyReportEnabled = settings['dailyReportEnabled'] ?? true;
        _checkIntervalMinutes = settings['checkIntervalMinutes'] ?? 30;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'continuousMonitoringEnabled': _continuousMonitoringEnabled,
        'alertNotificationsEnabled': _alertNotificationsEnabled,
        'dailyReportEnabled': _dailyReportEnabled,
        'checkIntervalMinutes': _checkIntervalMinutes,
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