import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class EmergencyMarker {
  final String id;
  final String type; // 'medical', 'security', 'fire', 'general'
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String userId;
  final String? userName;
  final int responderCount;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final bool isActive;

  EmergencyMarker({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.userId,
    this.userName,
    this.responderCount = 0,
    this.severity = 'medium',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'userName': userName,
    'responderCount': responderCount,
    'severity': severity,
    'isActive': isActive,
  };

  factory EmergencyMarker.fromJson(Map<String, dynamic> json) =>
      EmergencyMarker(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        userId: json['userId'] as String,
        userName: json['userName'] as String?,
        responderCount: json['responderCount'] as int? ?? 0,
        severity: json['severity'] as String? ?? 'medium',
        isActive: json['isActive'] as bool? ?? true,
      );

  EmergencyMarker copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? userId,
    String? userName,
    int? responderCount,
    String? severity,
    bool? isActive,
  }) {
    return EmergencyMarker(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      responderCount: responderCount ?? this.responderCount,
      severity: severity ?? this.severity,
      isActive: isActive ?? this.isActive,
    );
  }
}

class EmergencyMapService {
  static final EmergencyMapService _instance =
  EmergencyMapService._internal();
  factory EmergencyMapService() => _instance;
  EmergencyMapService._internal();

  static const String _markersKey = 'emergency_markers';
  static const String _userIdKey = 'user_id';

  List<EmergencyMarker> _markers = [];

  /// Get all emergency markers
  Future<List<EmergencyMarker>> getAllMarkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final markersJson = prefs.getStringList(_markersKey) ?? [];

      _markers = markersJson.map((jsonStr) {
        try {
          final Map<String, dynamic> data = json.decode(jsonStr);
          return EmergencyMarker.fromJson(data);
        } catch (e) {
          debugPrint(' Error parsing marker: $e');
          return null;
        }
      }).whereType<EmergencyMarker>().toList();

      // Filter out old inactive markers (older than 24 hours)
      final now = DateTime.now();
      _markers = _markers.where((marker) {
        if (!marker.isActive) {
          return now.difference(marker.timestamp).inHours < 24;
        }
        return true;
      }).toList();

      debugPrint(' Loaded ${_markers.length} emergency markers');
      return _markers;
    } catch (e) {
      debugPrint(' Get emergency markers error: $e');
      return [];
    }
  }

  /// Add new emergency marker
  Future<void> addMarker(EmergencyMarker marker) async {
    try {
      _markers.add(marker);
      await _saveMarkers();
      debugPrint(' Emergency marker added: ${marker.title}');
    } catch (e) {
      debugPrint(' Add emergency marker error: $e');
      rethrow;
    }
  }

  /// Update marker
  Future<void> updateMarker(EmergencyMarker marker) async {
    try {
      final index = _markers.indexWhere((m) => m.id == marker.id);
      if (index != -1) {
        _markers[index] = marker;
        await _saveMarkers();
        debugPrint(' Emergency marker updated: ${marker.title}');
      }
    } catch (e) {
      debugPrint(' Update emergency marker error: $e');
      rethrow;
    }
  }

  /// Delete marker
  Future<void> deleteMarker(String markerId) async {
    try {
      _markers.removeWhere((m) => m.id == markerId);
      await _saveMarkers();
      debugPrint(' Emergency marker deleted');
    } catch (e) {
      debugPrint(' Delete emergency marker error: $e');
      rethrow;
    }
  }

  /// Deactivate marker
  Future<void> deactivateMarker(String markerId) async {
    try {
      final index = _markers.indexWhere((m) => m.id == markerId);
      if (index != -1) {
        _markers[index] = _markers[index].copyWith(isActive: false);
        await _saveMarkers();
        debugPrint(' Emergency marker deactivated');
      }
    } catch (e) {
      debugPrint(' Deactivate marker error: $e');
      rethrow;
    }
  }

  /// Increment responder count
  Future<void> addResponder(String markerId) async {
    try {
      final index = _markers.indexWhere((m) => m.id == markerId);
      if (index != -1) {
        _markers[index] = _markers[index].copyWith(
          responderCount: _markers[index].responderCount + 1,
        );
        await _saveMarkers();
        debugPrint(' Responder added to marker');
      }
    } catch (e) {
      debugPrint(' Add responder error: $e');
      rethrow;
    }
  }

  /// Get markers by type
  List<EmergencyMarker> getMarkersByType(String type) {
    return _markers.where((m) => m.type == type && m.isActive).toList();
  }

  /// Get markers by severity
  List<EmergencyMarker> getMarkersBySeverity(String severity) {
    return _markers.where((m) => m.severity == severity && m.isActive).toList();
  }

  /// Get active markers only
  List<EmergencyMarker> getActiveMarkers() {
    return _markers.where((m) => m.isActive).toList();
  }

  /// Get markers near position
  List<EmergencyMarker> getMarkersNearPosition(
      Position position,
      double radiusInMeters,
      ) {
    return _markers.where((marker) {
      if (!marker.isActive) return false;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        marker.latitude,
        marker.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  /// Get nearest emergency
  Map<String, dynamic>? getNearestEmergency(Position position) {
    if (_markers.isEmpty) return null;

    final activeMarkers = getActiveMarkers();
    if (activeMarkers.isEmpty) return null;

    EmergencyMarker? nearestMarker;
    double? minDistance;

    for (final marker in activeMarkers) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        marker.latitude,
        marker.longitude,
      );

      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
        nearestMarker = marker;
      }
    }

    if (nearestMarker == null) return null;

    return {
      'marker': nearestMarker,
      'distance': minDistance,
    };
  }

  /// Get user ID
  Future<String> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(_userIdKey);

      if (userId == null) {
        userId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString(_userIdKey, userId);
      }

      return userId;
    } catch (e) {
      debugPrint(' Get user ID error: $e');
      return 'anonymous';
    }
  }

  /// Save markers
  Future<void> _saveMarkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final markersJson =
      _markers.map((marker) => json.encode(marker.toJson())).toList();
      await prefs.setStringList(_markersKey, markersJson);
      debugPrint(' Saved ${_markers.length} markers to storage');
    } catch (e) {
      debugPrint(' Save emergency markers error: $e');
      rethrow;
    }
  }

  /// Clear old markers (older than 24 hours)
  Future<void> clearOldMarkers() async {
    try {
      final now = DateTime.now();
      final before = _markers.length;

      _markers = _markers.where((marker) {
        return now.difference(marker.timestamp).inHours < 24;
      }).toList();

      await _saveMarkers();
      final removed = before - _markers.length;
      debugPrint(' Cleared $removed old markers');
    } catch (e) {
      debugPrint(' Clear old markers error: $e');
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final active = getActiveMarkers();

    return {
      'totalMarkers': _markers.length,
      'activeMarkers': active.length,
      'medicalEmergencies': active.where((m) => m.type == 'medical').length,
      'securityEmergencies': active.where((m) => m.type == 'security').length,
      'fireEmergencies': active.where((m) => m.type == 'fire').length,
      'criticalEmergencies': active.where((m) => m.severity == 'critical').length,
      'highSeverity': active.where((m) => m.severity == 'high').length,
      'totalResponders': active.fold<int>(0, (sum, m) => sum + m.responderCount),
    };
  }

  /// Get marker types
  static const List<Map<String, dynamic>> markerTypes = [
    {
      'value': 'medical',
      'name': 'Medical Emergency',
      'icon': ' ',
      'color': 0xFFE53935,
    },
    {
      'value': 'security',
      'name': 'Security Threat',
      'icon': ' ',
      'color': 0xFFD32F2F,
    },
    {
      'value': 'fire',
      'name': 'Fire Emergency',
      'icon': ' ',
      'color': 0xFFFF6F00,
    },
    {
      'value': 'general',
      'name': 'General Emergency',
      'icon': ' ',
      'color': 0xFFFBC02D,
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
    {
      'value': 'critical',
      'name': 'Critical',
      'color': 0xFFD32F2F,
    },
  ];

  /// Clear all markers
  Future<void> clearAllMarkers() async {
    try {
      _markers.clear();
      await _saveMarkers();
      debugPrint(' All emergency markers cleared');
    } catch (e) {
      debugPrint(' Clear all markers error: $e');
      rethrow;
    }
  }

  /// Get marker by ID
  EmergencyMarker? getMarkerById(String markerId) {
    try {
      return _markers.firstWhere((m) => m.id == markerId);
    } catch (e) {
      return null;
    }
  }

  /// Calculate time elapsed since marker creation
  String getTimeElapsed(EmergencyMarker marker) {
    final now = DateTime.now();
    final difference = now.difference(marker.timestamp);

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
}