import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class WeatherAlertService {
  static final WeatherAlertService _instance = WeatherAlertService._internal();
  factory WeatherAlertService() => _instance;
  WeatherAlertService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _checkTimer;
  bool _isMonitoring = false;

// Alert severity levels
  static const Map<String, Map<String, dynamic>> severityLevels = {
    'advisory': {
      'level': 0,
      'name': 'Advisory',
      'color': 0xFF2196F3, // Blue
      'icon': Icons.info,
      'description': 'Weather conditions may cause inconvenience',
    },
    'watch': {
      'level': 1,
      'name': 'Watch',
      'color': 0xFFFF9800, // Orange
      'icon': Icons.visibility,
      'description': 'Conditions are favorable for severe weather',
    },
    'warning': {
      'level': 2,
      'name': 'Warning',
      'color': 0xFFF44336, // Red
      'icon': Icons.warning,
      'description': 'Severe weather is occurring or imminent',
    },
    'emergency': {
      'level': 3,
      'name': 'Emergency',
      'color': 0xFF9C27B0, // Purple
      'icon': Icons.emergency,
      'description': 'Immediate threat to life and property',
    },
  };

// Weather alert types
  static const Map<String, Map<String, dynamic>> alertTypes = {
    'tornado': {
      'name': 'Tornado',
      'icon': '🌪️',
      'color': 0xFFF44336,
      'safetyTips': [
        'Go to a basement or interior room on the lowest floor',
        'Stay away from windows',
        'Get under sturdy furniture',
        'Cover yourself with blankets or mattress',
        'If outside, lie flat in a ditch or low area',
      ],
    },
    'hurricane': {
      'name': 'Hurricane',
      'icon': '🌀',
      'color': 0xFFE91E63,
      'safetyTips': [
        'Evacuate if ordered by authorities',
        'Board up windows',
        'Stock emergency supplies',
        'Stay indoors away from windows',
        'Have a battery-powered radio',
      ],
    },
    'thunderstorm': {
      'name': 'Severe Thunderstorm',
      'icon': '⛈️',
      'color': 0xFF9C27B0,
      'safetyTips': [
        'Go indoors immediately',
        'Avoid windows',
        'Unplug electronics',
        'Stay away from water',
        'Do not use corded phones',
      ],
    },
    'flood': {
      'name': 'Flood',
      'icon': '🌊',
      'color': 0xFF2196F3,
      'safetyTips': [
        'Move to higher ground',
        'Never walk through flood waters',
        'Do not drive through flooded areas',
        'Evacuate if told to do so',
        'Turn off utilities if flooding is imminent',
      ],
    },
    'winter_storm': {
      'name': 'Winter Storm',
      'icon': '❄️',
      'color': 0xFF00BCD4,
      'safetyTips': [
        'Stay indoors if possible',
        'Dress in layers if you must go out',
        'Keep emergency supplies ready',
        'Avoid overexertion when shoveling',
        'Check on elderly neighbors',
      ],
    },
    'heat': {
      'name': 'Extreme Heat',
      'icon': '🌡️',
      'color': 0xFFFF5722,
      'safetyTips': [
        'Stay hydrated',
        'Stay in air-conditioned areas',
        'Avoid strenuous activities',
        'Never leave people or pets in vehicles',
        'Check on vulnerable individuals',
      ],
    },
    'wind': {
      'name': 'High Wind',
      'icon': '💨',
      'color': 0xFF607D8B,
      'safetyTips': [
        'Secure outdoor objects',
        'Avoid being outside in forested areas',
        'Stay away from power lines',
        'Be cautious when driving',
        'Close windows and doors',
      ],
    },
    'fog': {
      'name': 'Dense Fog',
      'icon': '🌫️',
      'color': 0xFF9E9E9E,
      'safetyTips': [
        'Slow down when driving',
        'Use low beam headlights',
        'Increase following distance',
        'Use fog lights if available',
        'Avoid unnecessary travel',
      ],
    },
  };

  /// Start monitoring weather alerts
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('⚠️ Weather monitoring already active');
      return;
    }

    _isMonitoring = true;

// Check immediately
    await _checkForAlerts();

// Then check every 15 minutes
    _checkTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkForAlerts();
    });

    debugPrint('✅ Weather monitoring started');
  }

  /// Stop monitoring weather alerts
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isMonitoring = false;

    debugPrint('⏹️ Weather monitoring stopped');
  }

  /// Check for weather alerts
  Future<List<Map<String, dynamic>>> _checkForAlerts() async {
    try {
      debugPrint('🌤️ Checking for weather alerts...');

// In production, this would call a real weather API like:
// - National Weather Service API
// - OpenWeatherMap API
// - Weather.gov API

// For now, simulate with occasional mock alerts
      await Future.delayed(const Duration(seconds: 1));

// Generate mock alerts occasionally (10% chance)
      if (DateTime.now().second % 10 == 0) {
        final mockAlert = _generateMockAlert();
        await _saveAlert(mockAlert);
        return [mockAlert];
      }

      return [];
    } catch (e) {
      debugPrint('❌ Check alerts error: $e');
      return [];
    }
  }

  /// Generate mock alert for testing
  Map<String, dynamic> _generateMockAlert() {
    final types = alertTypes.keys.toList();
    final severities = severityLevels.keys.toList();

    final randomType = types[DateTime.now().millisecond % types.length];
    final randomSeverity = severities[DateTime.now().second % severities.length];

    return {
      'id': 'alert_${DateTime.now().millisecondsSinceEpoch}',
      'type': randomType,
      'severity': randomSeverity,
      'headline': '${severityLevels[randomSeverity]!['name']} - ${alertTypes[randomType]!['name']}',
      'description': 'Weather conditions warrant attention. ${severityLevels[randomSeverity]!['description']}',
      'area': 'Your Area',
      'effectiveTime': DateTime.now().toIso8601String(),
      'expiresTime': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
      'isActive': true,
    };
  }

  /// Save alert to Firestore
  Future<void> _saveAlert(Map<String, dynamic> alert) async {
    try {
      await _firestore.collection('weather_alerts').add({
        ...alert,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Weather alert saved: ${alert['headline']}');
    } catch (e) {
      debugPrint('❌ Save alert error: $e');
    }
  }

  /// Get active alerts
  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('weather_alerts')
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final alerts = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

// Check if alert has expired
        try {
          final expiresTime = DateTime.parse(data['expiresTime'] as String);
          if (expiresTime.isAfter(now)) {
            alerts.add({
              'id': doc.id,
              ...data,
            });
          } else {
// Mark as inactive
            await doc.reference.update({'isActive': false});
          }
        } catch (e) {
          debugPrint('Error parsing expiry time: $e');
        }
      }

      debugPrint('✅ Found ${alerts.length} active weather alerts');
      return alerts;
    } catch (e) {
      debugPrint('❌ Get active alerts error: $e');
      return [];
    }
  }

  /// Get alert history
  Future<List<Map<String, dynamic>>> getAlertHistory({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('weather_alerts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Get alert history error: $e');
      return [];
    }
  }

  /// Dismiss alert
  Future<void> dismissAlert(String alertId) async {
    try {
      await _firestore.collection('weather_alerts').doc(alertId).update({
        'isActive': false,
        'dismissedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Alert dismissed: $alertId');
    } catch (e) {
      debugPrint('❌ Dismiss alert error: $e');
    }
  }

  /// Check if monitoring is enabled in settings
  Future<bool> isMonitoringEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('weather_monitoring_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable/disable monitoring in settings
  Future<void> setMonitoringEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('weather_monitoring_enabled', enabled);

      if (enabled) {
        await startMonitoring();
      } else {
        stopMonitoring();
      }
    } catch (e) {
      debugPrint('❌ Set monitoring enabled error: $e');
    }
  }

  /// Get alert type data
  static Map<String, dynamic> getAlertTypeData(String type) {
    return alertTypes[type] ?? {
      'name': 'Weather Alert',
      'icon': '⚠️',
      'color': 0xFF9E9E9E,
      'safetyTips': ['Stay informed', 'Follow official guidance'],
    };
  }

  /// Get severity level data
  static Map<String, dynamic> getSeverityLevelData(String severity) {
    return severityLevels[severity] ?? severityLevels['advisory']!;
  }

  /// Get severity color
  static Color getSeverityColor(String severity) {
    final data = getSeverityLevelData(severity);
    return Color(data['color'] as int);
  }

  /// Get severity icon
  static IconData getSeverityIcon(String severity) {
    final data = getSeverityLevelData(severity);
    return data['icon'] as IconData;
  }

  /// Format time remaining
  static String formatTimeRemaining(String expiresTimeStr) {
    try {
      final expiresTime = DateTime.parse(expiresTimeStr);
      final difference = expiresTime.difference(DateTime.now());

      if (difference.isNegative) {
        return 'Expired';
      }

      if (difference.inHours > 24) {
        return '${difference.inDays} days';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else {
        return '${difference.inMinutes}m';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get monitoring status
  bool get isMonitoring => _isMonitoring;

  /// Dispose
  void dispose() {
    stopMonitoring();
  }
}