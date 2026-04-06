import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class CommunityAlert {
  final String id;
  final String type; // 'crime', 'accident', 'hazard', 'suspicious', 'other'
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String reportedBy;
  final int confirmations;
  final String severity; // 'low', 'medium', 'high'
  final bool isVerified;
  final List<String> tags;

  CommunityAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.reportedBy,
    this.confirmations = 0,
    this.severity = 'medium',
    this.isVerified = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'reportedBy': reportedBy,
    'confirmations': confirmations,
    'severity': severity,
    'isVerified': isVerified,
    'tags': tags,
  };

  factory CommunityAlert.fromJson(Map<String, dynamic> json) =>
      CommunityAlert(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        reportedBy: json['reportedBy'] as String,
        confirmations: json['confirmations'] as int? ?? 0,
        severity: json['severity'] as String? ?? 'medium',
        isVerified: json['isVerified'] as bool? ?? false,
        tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      );

  CommunityAlert copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? reportedBy,
    int? confirmations,
    String? severity,
    bool? isVerified,
    List<String>? tags,
  }) {
    return CommunityAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      reportedBy: reportedBy ?? this.reportedBy,
      confirmations: confirmations ?? this.confirmations,
      severity: severity ?? this.severity,
      isVerified: isVerified ?? this.isVerified,
      tags: tags ?? this.tags,
    );
  }
}

class CommunityAlertMapService {
  static final CommunityAlertMapService _instance =
  CommunityAlertMapService._internal();
  factory CommunityAlertMapService() => _instance;
  CommunityAlertMapService._internal();

  static const String _alertsKey = 'community_alerts';

  List<CommunityAlert> _alerts = [];

  /// Get all community alerts
  Future<List<CommunityAlert>> getAllAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getStringList(_alertsKey) ?? [];

      _alerts = alertsJson.map((jsonStr) {
        try {
          final Map<String, dynamic> data = json.decode(jsonStr);
          return CommunityAlert.fromJson(data);
        } catch (e) {
          debugPrint(' Error parsing alert: $e');
          return null;
        }
      }).whereType<CommunityAlert>().toList();

      // Filter out old alerts (older than 48 hours)
      final now = DateTime.now();
      _alerts = _alerts.where((alert) {
        return now.difference(alert.timestamp).inHours < 48;
      }).toList();

      debugPrint(' Loaded ${_alerts.length} community alerts');
      return _alerts;
    } catch (e) {
      debugPrint(' Get community alerts error: $e');
      return [];
    }
  }

  /// Add new community alert
  Future<void> addAlert(CommunityAlert alert) async {
    try {
      _alerts.add(alert);
      await _saveAlerts();
      debugPrint(' Community alert added: ${alert.title}');
    } catch (e) {
      debugPrint(' Add community alert error: $e');
      rethrow;
    }
  }

  /// Update alert
  Future<void> updateAlert(CommunityAlert alert) async {
    try {
      final index = _alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        _alerts[index] = alert;
        await _saveAlerts();
        debugPrint(' Community alert updated: ${alert.title}');
      }
    } catch (e) {
      debugPrint(' Update community alert error: $e');
      rethrow;
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      _alerts.removeWhere((a) => a.id == alertId);
      await _saveAlerts();
      debugPrint(' Community alert deleted');
    } catch (e) {
      debugPrint(' Delete community alert error: $e');
      rethrow;
    }
  }

  /// Confirm alert (increase confirmation count)
  Future<void> confirmAlert(String alertId) async {
    try {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(
          confirmations: _alerts[index].confirmations + 1,
        );
        await _saveAlerts();
        debugPrint(' Alert confirmed');
      }
    } catch (e) {
      debugPrint(' Confirm alert error: $e');
      rethrow;
    }
  }

  /// Verify alert
  Future<void> verifyAlert(String alertId) async {
    try {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isVerified: true);
        await _saveAlerts();
        debugPrint(' Alert verified');
      }
    } catch (e) {
      debugPrint(' Verify alert error: $e');
      rethrow;
    }
  }

  /// Get alerts by type
  List<CommunityAlert> getAlertsByType(String type) {
    return _alerts.where((a) => a.type == type).toList();
  }

  /// Get alerts by severity
  List<CommunityAlert> getAlertsBySeverity(String severity) {
    return _alerts.where((a) => a.severity == severity).toList();
  }

  /// Get verified alerts only
  List<CommunityAlert> getVerifiedAlerts() {
    return _alerts.where((a) => a.isVerified).toList();
  }

  /// Get alerts near position
  List<CommunityAlert> getAlertsNearPosition(
      Position position,
      double radiusInMeters,
      ) {
    return _alerts.where((alert) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        alert.latitude,
        alert.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  /// Get alerts by tag
  List<CommunityAlert> getAlertsByTag(String tag) {
    return _alerts.where((a) => a.tags.contains(tag)).toList();
  }

  /// Save alerts
  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson =
      _alerts.map((alert) => json.encode(alert.toJson())).toList();
      await prefs.setStringList(_alertsKey, alertsJson);
      debugPrint(' Saved ${_alerts.length} alerts to storage');
    } catch (e) {
      debugPrint(' Save community alerts error: $e');
      rethrow;
    }
  }

  /// Clear old alerts (older than 48 hours)
  Future<void> clearOldAlerts() async {
    try {
      final now = DateTime.now();
      final before = _alerts.length;

      _alerts = _alerts.where((alert) {
        return now.difference(alert.timestamp).inHours < 48;
      }).toList();

      await _saveAlerts();
      final removed = before - _alerts.length;
      debugPrint(' Cleared $removed old alerts');
    } catch (e) {
      debugPrint(' Clear old alerts error: $e');
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalAlerts': _alerts.length,
      'crimeAlerts': _alerts.where((a) => a.type == 'crime').length,
      'accidentAlerts': _alerts.where((a) => a.type == 'accident').length,
      'hazardAlerts': _alerts.where((a) => a.type == 'hazard').length,
      'verifiedAlerts': _alerts.where((a) => a.isVerified).length,
      'highSeverity': _alerts.where((a) => a.severity == 'high').length,
      'totalConfirmations':
      _alerts.fold<int>(0, (sum, a) => sum + a.confirmations),
    };
  }

  /// Get alert types
  static const List<Map<String, dynamic>> alertTypes = [
    {
      'value': 'crime',
      'name': 'Crime',
      'icon': ' ',
      'color': 0xFFD32F2F,
    },
    {
      'value': 'accident',
      'name': 'Accident',
      'icon': ' ',
      'color': 0xFFFF6F00,
    },
    {
      'value': 'hazard',
      'name': 'Hazard',
      'icon': ' ',
      'color': 0xFFFBC02D,
    },
    {
      'value': 'suspicious',
      'name': 'Suspicious Activity',
      'icon': ' ',
      'color': 0xFF7B1FA2,
    },
    {
      'value': 'other',
      'name': 'Other',
      'icon': ' ',
      'color': 0xFF455A64,
    },
  ];

  /// Get severity levels
  static const List<Map<String, dynamic>> severityLevels = [
    {
      'value': 'low',
      'name': 'Low',
      'color': 0xFF66BB6A,
    },
    {
      'value': 'medium',
      'name': 'Medium',
      'color': 0xFFFFA726,
    },
    {
      'value': 'high',
      'name': 'High',
      'color': 0xFFEF5350,
    },
  ];

  /// Clear all alerts
  Future<void> clearAllAlerts() async {
    try {
      _alerts.clear();
      await _saveAlerts();
      debugPrint(' All community alerts cleared');
    } catch (e) {
      debugPrint(' Clear all alerts error: $e');
      rethrow;
    }
  }

  /// Get alert by ID
  CommunityAlert? getAlertById(String alertId) {
    try {
      return _alerts.firstWhere((a) => a.id == alertId);
    } catch (e) {
      return null;
    }
  }

  /// Calculate time elapsed since alert
  String getTimeElapsed(CommunityAlert alert) {
    final now = DateTime.now();
    final difference = now.difference(alert.timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Format distance
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()}m away';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km away';
    }
  }

  /// Initialize sample data
  Future<void> initializeSampleData(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_alertsKey);

      if (existing == null || existing.isEmpty) {
        // Add sample alerts around user's location
        final sampleAlerts = [
          CommunityAlert(
            id: '1',
            type: 'crime',
            title: 'Theft Reported',
            description: 'Car break-in reported in parking lot',
            latitude: position.latitude + 0.01,
            longitude: position.longitude + 0.01,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            reportedBy: 'Community Member',
            confirmations: 5,
            severity: 'high',
            isVerified: true,
            tags: ['theft', 'vehicle'],
          ),
          CommunityAlert(
            id: '2',
            type: 'accident',
            title: 'Traffic Accident',
            description: 'Minor collision, traffic slow',
            latitude: position.latitude - 0.01,
            longitude: position.longitude + 0.01,
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            reportedBy: 'Anonymous',
            confirmations: 3,
            severity: 'medium',
            tags: ['traffic', 'accident'],
          ),
          CommunityAlert(
            id: '3',
            type: 'hazard',
            title: 'Road Hazard',
            description: 'Large pothole on main street',
            latitude: position.latitude + 0.02,
            longitude: position.longitude - 0.01,
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            reportedBy: 'Local Resident',
            confirmations: 8,
            severity: 'low',
            isVerified: true,
            tags: ['road', 'hazard'],
          ),
          CommunityAlert(
            id: '4',
            type: 'suspicious',
            title: 'Suspicious Activity',
            description: 'Unfamiliar vehicle circling neighborhood',
            latitude: position.latitude - 0.015,
            longitude: position.longitude - 0.02,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            reportedBy: 'Neighborhood Watch',
            confirmations: 2,
            severity: 'medium',
            tags: ['suspicious', 'vehicle'],
          ),
        ];

        for (final alert in sampleAlerts) {
          await addAlert(alert);
        }

        debugPrint(' Sample community alerts initialized');
      }
    } catch (e) {
      debugPrint(' Initialize sample data error: $e');
    }
  }
}