import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class SafetyEvent {
  final String id;
  final DateTime timestamp;
  final String eventType; // panic, alert, check-in, location-update, etc.
  final String severity; // low, medium, high, critical
  final bool resolved;
  final int responseTimeSeconds;

  SafetyEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.severity,
    this.resolved = false,
    this.responseTimeSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'eventType': eventType,
    'severity': severity,
    'resolved': resolved,
    'responseTimeSeconds': responseTimeSeconds,
  };

  factory SafetyEvent.fromJson(Map<String, dynamic> json) => SafetyEvent(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    eventType: json['eventType'],
    severity: json['severity'],
    resolved: json['resolved'] ?? false,
    responseTimeSeconds: json['responseTimeSeconds'] ?? 0,
  );
}

class LocationHistory {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String locationType; // home, work, safe-zone, unknown

  LocationHistory({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.locationType,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'locationType': locationType,
  };

  factory LocationHistory.fromJson(Map<String, dynamic> json) =>
      LocationHistory(
        timestamp: DateTime.parse(json['timestamp']),
        latitude: json['latitude'],
        longitude: json['longitude'],
        locationType: json['locationType'],
      );
}

class UsagePattern {
  final String featureName;
  final int usageCount;
  final DateTime lastUsed;
  final double averageSessionMinutes;

  UsagePattern({
    required this.featureName,
    required this.usageCount,
    required this.lastUsed,
    required this.averageSessionMinutes,
  });

  Map<String, dynamic> toJson() => {
    'featureName': featureName,
    'usageCount': usageCount,
    'lastUsed': lastUsed.toIso8601String(),
    'averageSessionMinutes': averageSessionMinutes,
  };

  factory UsagePattern.fromJson(Map<String, dynamic> json) => UsagePattern(
    featureName: json['featureName'],
    usageCount: json['usageCount'],
    lastUsed: DateTime.parse(json['lastUsed']),
    averageSessionMinutes: json['averageSessionMinutes'],
  );
}

class SafetyAnalyticsService {
  static final SafetyAnalyticsService _instance =
  SafetyAnalyticsService._internal();
  factory SafetyAnalyticsService() => _instance;
  SafetyAnalyticsService._internal();

  static const String _eventsKey = 'safety_events';
  static const String _locationsKey = 'location_history';
  static const String _usageKey = 'usage_patterns';
  static const String _settingsKey = 'analytics_settings';

  List<SafetyEvent> _events = [];
  List<LocationHistory> _locationHistory = [];
  List<UsagePattern> _usagePatterns = [];

  // Settings
  bool _analyticsEnabled = true;
  bool _locationTrackingEnabled = true;
  int _dataRetentionDays = 90;

  /// Initialize service
  Future<void> initialize() async {
    await _loadSettings();
    await _loadEvents();
    await _loadLocationHistory();
    await _loadUsagePatterns();
    _generateMockData();
    debugPrint(' Safety Analytics Service initialized');
  }

  /// Log safety event
  Future<void> logEvent(SafetyEvent event) async {
    if (!_analyticsEnabled) return;

    _events.add(event);
    await _saveEvents();
    debugPrint(' Event logged: ${event.eventType}');
  }

  /// Log location
  Future<void> logLocation(LocationHistory location) async {
    if (!_locationTrackingEnabled) return;

    _locationHistory.add(location);
    if (_locationHistory.length > 10000) {
      _locationHistory = _locationHistory.sublist(_locationHistory.length - 10000);
    }
    await _saveLocationHistory();
  }

  /// Log feature usage
  Future<void> logFeatureUsage(String featureName, double sessionMinutes) async {
    final existingIndex =
    _usagePatterns.indexWhere((p) => p.featureName == featureName);

    if (existingIndex != -1) {
      final existing = _usagePatterns[existingIndex];
      _usagePatterns[existingIndex] = UsagePattern(
        featureName: featureName,
        usageCount: existing.usageCount + 1,
        lastUsed: DateTime.now(),
        averageSessionMinutes:
        (existing.averageSessionMinutes * existing.usageCount +
            sessionMinutes) /
            (existing.usageCount + 1),
      );
    } else {
      _usagePatterns.add(UsagePattern(
        featureName: featureName,
        usageCount: 1,
        lastUsed: DateTime.now(),
        averageSessionMinutes: sessionMinutes,
      ));
    }

    await _saveUsagePatterns();
  }

  /// Get comprehensive statistics
  Map<String, dynamic> getComprehensiveStats() {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    final last7Days = now.subtract(const Duration(days: 7));

    final events30Days = _events.where((e) => e.timestamp.isAfter(last30Days));
    final events7Days = _events.where((e) => e.timestamp.isAfter(last7Days));

    return {
      'totalEvents': _events.length,
      'events30Days': events30Days.length,
      'events7Days': events7Days.length,
      'panicButtonUsed': _events.where((e) => e.eventType == 'panic').length,
      'alertsSent': _events.where((e) => e.eventType == 'alert').length,
      'checkInsCompleted': _events.where((e) => e.eventType == 'check-in').length,
      'averageResponseTime': _calculateAverageResponseTime(),
      'safetyScore': _calculateSafetyScore(),
      'locationUpdates': _locationHistory.length,
      'featuresUsed': _usagePatterns.length,
      'mostUsedFeature': _getMostUsedFeature(),
    };
  }

  /// Get events by time period
  List<SafetyEvent> getEventsByPeriod({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _events.where((e) => e.timestamp.isAfter(cutoff)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get events by type
  Map<String, int> getEventsByType({int days = 30}) {
    final events = getEventsByPeriod(days: days);
    Map<String, int> counts = {};

    for (var event in events) {
      counts[event.eventType] = (counts[event.eventType] ?? 0) + 1;
    }

    return counts;
  }

  /// Get events by severity
  Map<String, int> getEventsBySeverity({int days = 30}) {
    final events = getEventsByPeriod(days: days);
    Map<String, int> counts = {};

    for (var event in events) {
      counts[event.severity] = (counts[event.severity] ?? 0) + 1;
    }

    return counts;
  }

  /// Get hourly distribution
  Map<int, int> getHourlyDistribution({int days = 30}) {
    final events = getEventsByPeriod(days: days);
    Map<int, int> distribution = {};

    for (var event in events) {
      final hour = event.timestamp.hour;
      distribution[hour] = (distribution[hour] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get daily trend
  Map<String, int> getDailyTrend({int days = 7}) {
    final events = getEventsByPeriod(days: days);
    Map<String, int> trend = {};

    for (var event in events) {
      final dateKey = '${event.timestamp.month}/${event.timestamp.day}';
      trend[dateKey] = (trend[dateKey] ?? 0) + 1;
    }

    return trend;
  }

  /// Get location patterns
  Map<String, int> getLocationPatterns() {
    Map<String, int> patterns = {};

    for (var location in _locationHistory) {
      patterns[location.locationType] =
          (patterns[location.locationType] ?? 0) + 1;
    }

    return patterns;
  }

  /// Get most visited locations
  List<Map<String, dynamic>> getMostVisitedLocations({int limit = 5}) {
    // In real app, would cluster nearby coordinates
    return [
      {'name': 'Home', 'visits': 450, 'safetyRating': 5},
      {'name': 'Work', 'visits': 220, 'safetyRating': 4},
      {'name': 'Gym', 'visits': 60, 'safetyRating': 5},
      {'name': 'Shopping Center', 'visits': 45, 'safetyRating': 4},
      {'name': 'Park', 'visits': 30, 'safetyRating': 5},
    ];
  }

  /// Get usage patterns
  List<UsagePattern> getUsagePatterns() {
    return _usagePatterns
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  /// Get response time analytics
  Map<String, dynamic> getResponseTimeAnalytics() {
    final eventsWithResponse =
    _events.where((e) => e.responseTimeSeconds > 0).toList();

    if (eventsWithResponse.isEmpty) {
      return {
        'average': 0,
        'fastest': 0,
        'slowest': 0,
        'median': 0,
      };
    }

    final responseTimes =
    eventsWithResponse.map((e) => e.responseTimeSeconds).toList()..sort();

    return {
      'average': responseTimes.reduce((a, b) => a + b) / responseTimes.length,
      'fastest': responseTimes.first,
      'slowest': responseTimes.last,
      'median': responseTimes[responseTimes.length ~/ 2],
    };
  }

  /// Calculate safety score (0-100)
  double _calculateSafetyScore() {
    double score = 100.0;

    // Deduct for critical events
    final criticalEvents =
        _events.where((e) => e.severity == 'critical').length;
    score -= criticalEvents * 5;

    // Deduct for unresolved events
    final unresolvedEvents = _events.where((e) => !e.resolved).length;
    score -= unresolvedEvents * 2;

    // Bonus for consistent check-ins
    final checkIns = _events.where((e) => e.eventType == 'check-in').length;
    score += (checkIns / 10).clamp(0, 10);

    // Bonus for safety features usage
    score += (_usagePatterns.length / 5).clamp(0, 10);

    return score.clamp(0, 100);
  }

  double _calculateAverageResponseTime() {
    final eventsWithResponse =
    _events.where((e) => e.responseTimeSeconds > 0);
    if (eventsWithResponse.isEmpty) return 0;

    final sum =
    eventsWithResponse.fold<int>(0, (sum, e) => sum + e.responseTimeSeconds);
    return sum / eventsWithResponse.length;
  }

  String _getMostUsedFeature() {
    if (_usagePatterns.isEmpty) return 'None';
    _usagePatterns.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return _usagePatterns.first.featureName;
  }

  /// Generate insights
  List<String> generateInsights() {
    List<String> insights = [];

    final stats = getComprehensiveStats();
    final eventsByType = getEventsByType(days: 30);
    final hourlyDist = getHourlyDistribution(days: 30);

    // Safety score insight
    final safetyScore = stats['safetyScore'];
    if (safetyScore > 90) {
      insights.add('Excellent safety practices! Your safety score is ${safetyScore.round()}/100.');
    } else if (safetyScore < 60) {
      insights.add('Consider improving your safety habits. Current score: ${safetyScore.round()}/100.');
    }

    // Usage insights
    if (stats['events7Days'] > stats['events30Days'] / 4) {
      insights.add('Your safety activity has increased this week.');
    }

    // Peak hours
    if (hourlyDist.isNotEmpty) {
      final peakHour = hourlyDist.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      insights.add('Most safety events occur around ${peakHour}:00. Stay extra alert during this time.');
    }

    // Feature recommendations
    if (eventsByType['panic'] != null && eventsByType['panic']! > 3) {
      insights.add('Consider setting up more emergency contacts for faster response.');
    }

    if (_usagePatterns.length < 5) {
      insights.add('Explore more safety features to enhance your protection.');
    }

    return insights;
  }

  /// Settings
  bool isAnalyticsEnabled() => _analyticsEnabled;
  bool isLocationTrackingEnabled() => _locationTrackingEnabled;
  int getDataRetentionDays() => _dataRetentionDays;

  Future<void> updateSettings({
    bool? analytics,
    bool? locationTracking,
    int? dataRetention,
  }) async {
    if (analytics != null) _analyticsEnabled = analytics;
    if (locationTracking != null) _locationTrackingEnabled = locationTracking;
    if (dataRetention != null) _dataRetentionDays = dataRetention;
    await _saveSettings();
  }

  /// Clear old data
  Future<void> clearOldData() async {
    final cutoff =
    DateTime.now().subtract(Duration(days: _dataRetentionDays));
    _events.removeWhere((e) => e.timestamp.isBefore(cutoff));
    _locationHistory.removeWhere((l) => l.timestamp.isBefore(cutoff));
    await _saveEvents();
    await _saveLocationHistory();
    debugPrint(' Old data cleared');
  }

  /// Generate mock data for demonstration
  void _generateMockData() {
    if (_events.isNotEmpty) return; // Already has data

    final now = DateTime.now();

    // Generate events for last 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));

      // 2-5 events per day
      final eventsPerDay = 2 + (i % 4);
      for (int j = 0; j < eventsPerDay; j++) {
        final eventTypes = ['check-in', 'alert', 'location-update', 'panic'];
        final severities = ['low', 'medium', 'high', 'critical'];

        _events.add(SafetyEvent(
          id: '${date.millisecondsSinceEpoch}_$j',
          timestamp: date.add(Duration(hours: 8 + j * 3)),
          eventType: eventTypes[j % eventTypes.length],
          severity: severities[j % severities.length],
          resolved: j % 3 != 0,
          responseTimeSeconds: (30 + j * 15),
        ));
      }
    }

    // Generate usage patterns
    final features = [
      'Panic Button',
      'Emergency Contacts',
      'Location Tracking',
      'Check-Ins',
      'Safe Zones',
      'Medical ID',
    ];

    for (var feature in features) {
      _usagePatterns.add(UsagePattern(
        featureName: feature,
        usageCount: 10 + (features.indexOf(feature) * 5),
        lastUsed: now.subtract(Duration(days: features.indexOf(feature))),
        averageSessionMinutes: 3.0 + features.indexOf(feature),
      ));
    }

    debugPrint(' Mock analytics data generated');
  }

  /// Storage methods
  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_eventsKey);
      if (eventsJson != null) {
        _events = eventsJson
            .map((str) => SafetyEvent.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load events error: $e');
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = _events.map((e) => json.encode(e.toJson())).toList();
      await prefs.setStringList(_eventsKey, eventsJson);
    } catch (e) {
      debugPrint(' Save events error: $e');
    }
  }

  Future<void> _loadLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList(_locationsKey);
      if (locationsJson != null) {
        _locationHistory = locationsJson
            .map((str) => LocationHistory.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load location history error: $e');
    }
  }

  Future<void> _saveLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson =
      _locationHistory.map((l) => json.encode(l.toJson())).toList();
      await prefs.setStringList(_locationsKey, locationsJson);
    } catch (e) {
      debugPrint(' Save location history error: $e');
    }
  }

  Future<void> _loadUsagePatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usageJson = prefs.getStringList(_usageKey);
      if (usageJson != null) {
        _usagePatterns = usageJson
            .map((str) => UsagePattern.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load usage patterns error: $e');
    }
  }

  Future<void> _saveUsagePatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usageJson =
      _usagePatterns.map((u) => json.encode(u.toJson())).toList();
      await prefs.setStringList(_usageKey, usageJson);
    } catch (e) {
      debugPrint(' Save usage patterns error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = json.decode(settingsJson);
        _analyticsEnabled = settings['analyticsEnabled'] ?? true;
        _locationTrackingEnabled = settings['locationTrackingEnabled'] ?? true;
        _dataRetentionDays = settings['dataRetentionDays'] ?? 90;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'analyticsEnabled': _analyticsEnabled,
        'locationTrackingEnabled': _locationTrackingEnabled,
        'dataRetentionDays': _dataRetentionDays,
      };
      await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint(' Save settings error: $e');
    }
  }
}