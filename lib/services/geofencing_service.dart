import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:convert';

class GeofenceZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String type; // 'safe' or 'danger'
  final bool alertOnEntry;
  final bool alertOnExit;
  final String? description;
  final DateTime createdAt;

  GeofenceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.type,
    this.alertOnEntry = true,
    this.alertOnExit = true,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'type': type,
    'alertOnEntry': alertOnEntry,
    'alertOnExit': alertOnExit,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GeofenceZone.fromJson(Map<String, dynamic> json) => GeofenceZone(
    id: json['id'] as String,
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radius: (json['radius'] as num).toDouble(),
    type: json['type'] as String,
    alertOnEntry: json['alertOnEntry'] as bool? ?? true,
    alertOnExit: json['alertOnExit'] as bool? ?? true,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  GeofenceZone copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    String? type,
    bool? alertOnEntry,
    bool? alertOnExit,
    String? description,
    DateTime? createdAt,
  }) {
    return GeofenceZone(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      type: type ?? this.type,
      alertOnEntry: alertOnEntry ?? this.alertOnEntry,
      alertOnExit: alertOnExit ?? this.alertOnExit,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GeofencingService {
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;
  GeofencingService._internal();

  static const String _zonesKey = 'geofence_zones';
  static const String _monitoringKey = 'geofence_monitoring_enabled';

  List<GeofenceZone> _zones = [];
  Position? _lastPosition;
  final Map<String, bool> _insideZones = {};
  bool _isMonitoring = false;

  /// Get all geofence zones
  Future<List<GeofenceZone>> getAllZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesJson = prefs.getStringList(_zonesKey) ?? [];

      _zones = zonesJson.map((jsonStr) {
        try {
          final Map<String, dynamic> data = json.decode(jsonStr);
          return GeofenceZone.fromJson(data);
        } catch (e) {
          debugPrint('❌ Error parsing zone: $e');
          return null;
        }
      }).whereType<GeofenceZone>().toList();

      debugPrint('✅ Loaded ${_zones.length} geofence zones');
      return _zones;
    } catch (e) {
      debugPrint('❌ Get geofence zones error: $e');
      return [];
    }
  }

  /// Add new geofence zone
  Future<void> addZone(GeofenceZone zone) async {
    try {
      _zones.add(zone);
      await _saveZones();
      debugPrint('✅ Geofence zone added: ${zone.name}');
    } catch (e) {
      debugPrint('❌ Add geofence zone error: $e');
      rethrow;
    }
  }

  /// Update existing zone
  Future<void> updateZone(GeofenceZone zone) async {
    try {
      final index = _zones.indexWhere((z) => z.id == zone.id);
      if (index != -1) {
        _zones[index] = zone;
        await _saveZones();
        debugPrint('✅ Geofence zone updated: ${zone.name}');
      } else {
        throw Exception('Zone not found');
      }
    } catch (e) {
      debugPrint('❌ Update geofence zone error: $e');
      rethrow;
    }
  }

  /// Delete zone
  Future<void> deleteZone(String zoneId) async {
    try {
      _zones.removeWhere((z) => z.id == zoneId);
      _insideZones.remove(zoneId);
      await _saveZones();
      debugPrint('✅ Geofence zone deleted: $zoneId');
    } catch (e) {
      debugPrint('❌ Delete geofence zone error: $e');
      rethrow;
    }
  }

  /// Get zone by ID
  GeofenceZone? getZoneById(String zoneId) {
    try {
      return _zones.firstWhere((z) => z.id == zoneId);
    } catch (e) {
      return null;
    }
  }

  /// Save zones to storage
  Future<void> _saveZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesJson = _zones.map((zone) => json.encode(zone.toJson())).toList();
      await prefs.setStringList(_zonesKey, zonesJson);
      debugPrint('✅ Saved ${_zones.length} zones to storage');
    } catch (e) {
      debugPrint('❌ Save geofence zones error: $e');
      rethrow;
    }
  }

  /// Calculate distance between two points (in meters) - PUBLIC
  double calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const R = 6371000; // Earth's radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  /// Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Check if position is inside zone
  bool isInsideZone(Position position, GeofenceZone zone) {
    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      zone.latitude,
      zone.longitude,
    );
    return distance <= zone.radius;
  }

  /// Check if currently inside a specific zone
  bool isCurrentlyInZone(String zoneId) {
    return _insideZones[zoneId] ?? false;
  }

  /// Monitor location and trigger alerts
  Future<List<Map<String, dynamic>>> checkGeofences(Position position) async {
    final alerts = <Map<String, dynamic>>[];

    try {
      if (_zones.isEmpty) {
        await getAllZones();
      }

      for (final zone in _zones) {
        final isInside = isInsideZone(position, zone);
        final wasInside = _insideZones[zone.id] ?? false;

// Entry alert
        if (isInside && !wasInside && zone.alertOnEntry) {
          alerts.add({
            'type': 'entry',
            'zone': zone,
            'message': 'Entered ${zone.type} zone: ${zone.name}',
            'timestamp': DateTime.now().toIso8601String(),
          });
          debugPrint('🚨 Entered zone: ${zone.name}');
        }

// Exit alert
        if (!isInside && wasInside && zone.alertOnExit) {
          alerts.add({
            'type': 'exit',
            'zone': zone,
            'message': 'Exited ${zone.type} zone: ${zone.name}',
            'timestamp': DateTime.now().toIso8601String(),
          });
          debugPrint('🚪 Exited zone: ${zone.name}');
        }

        _insideZones[zone.id] = isInside;
      }

      _lastPosition = position;
    } catch (e) {
      debugPrint('❌ Check geofences error: $e');
    }

    return alerts;
  }

  /// Get zones by type
  List<GeofenceZone> getZonesByType(String type) {
    return _zones.where((z) => z.type == type).toList();
  }

  /// Get safe zones
  List<GeofenceZone> getSafeZones() {
    return getZonesByType('safe');
  }

  /// Get danger zones
  List<GeofenceZone> getDangerZones() {
    return getZonesByType('danger');
  }

  /// Get zones near position
  List<GeofenceZone> getZonesNearPosition(
      Position position,
      double radiusInMeters,
      ) {
    return _zones.where((zone) {
      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  /// Get zones within view bounds
  List<GeofenceZone> getZonesInBounds({
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
  }) {
    return _zones.where((zone) {
      return zone.latitude >= southLat &&
          zone.latitude <= northLat &&
          zone.longitude >= westLng &&
          zone.longitude <= eastLng;
    }).toList();
  }

  /// Get distance to nearest zone
  Map<String, dynamic>? getNearestZone(Position position) {
    if (_zones.isEmpty) return null;

    GeofenceZone? nearestZone;
    double? minDistance;

    for (final zone in _zones) {
      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
        nearestZone = zone;
      }
    }

    if (nearestZone == null) return null;

    return {
      'zone': nearestZone,
      'distance': minDistance,
      'isInside': minDistance! <= nearestZone.radius,
    };
  }

  /// Start monitoring geofences
  Future<void> startMonitoring() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_monitoringKey, true);
      _isMonitoring = true;
      debugPrint('🎯 Geofence monitoring started');
    } catch (e) {
      debugPrint('❌ Start monitoring error: $e');
    }
  }

  /// Stop monitoring geofences
  Future<void> stopMonitoring() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_monitoringKey, false);
      _isMonitoring = false;
      debugPrint('⏸️ Geofence monitoring stopped');
    } catch (e) {
      debugPrint('❌ Stop monitoring error: $e');
    }
  }

  /// Check if monitoring is enabled
  Future<bool> isMonitoringEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMonitoring = prefs.getBool(_monitoringKey) ?? false;
      return _isMonitoring;
    } catch (e) {
      debugPrint('❌ Check monitoring error: $e');
      return false;
    }
  }

  /// Get monitoring status
  bool get isMonitoring => _isMonitoring;

  /// Get total zone count
  int get zoneCount => _zones.length;

  /// Get safe zone count
  int get safeZoneCount => _zones.where((z) => z.type == 'safe').length;

  /// Get danger zone count
  int get dangerZoneCount => _zones.where((z) => z.type == 'danger').length;

  /// Clear all zones
  Future<void> clearAllZones() async {
    try {
      _zones.clear();
      _insideZones.clear();
      await _saveZones();
      debugPrint('🧹 All geofence zones cleared');
    } catch (e) {
      debugPrint('❌ Clear zones error: $e');
      rethrow;
    }
  }

  /// Export zones to JSON
  String exportZones() {
    try {
      final data = {
        'zones': _zones.map((z) => z.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'totalZones': _zones.length,
      };
      return json.encode(data);
    } catch (e) {
      debugPrint('❌ Export zones error: $e');
      return '{}';
    }
  }

  /// Import zones from JSON
  Future<int> importZones(String jsonData) async {
    try {
      final data = json.decode(jsonData) as Map<String, dynamic>;
      final zonesList = data['zones'] as List;

      int imported = 0;
      for (final zoneData in zonesList) {
        try {
          final zone = GeofenceZone.fromJson(zoneData as Map<String, dynamic>);
// Generate new ID to avoid conflicts
          final newZone = zone.copyWith(
            id: DateTime.now().millisecondsSinceEpoch.toString() + imported.toString(),
          );
          await addZone(newZone);
          imported++;
        } catch (e) {
          debugPrint('❌ Error importing zone: $e');
        }
      }

      debugPrint('✅ Imported $imported zones');
      return imported;
    } catch (e) {
      debugPrint('❌ Import zones error: $e');
      return 0;
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalZones': _zones.length,
      'safeZones': safeZoneCount,
      'dangerZones': dangerZoneCount,
      'monitoringEnabled': _isMonitoring,
      'zonesWithEntryAlert': _zones.where((z) => z.alertOnEntry).length,
      'zonesWithExitAlert': _zones.where((z) => z.alertOnExit).length,
      'currentlyInsideZones': _insideZones.values.where((v) => v).length,
    };
  }

  /// Reset all zone states
  void resetZoneStates() {
    _insideZones.clear();
    _lastPosition = null;
    debugPrint('🔄 Zone states reset');
  }

  /// Get last known position
  Position? get lastPosition => _lastPosition;

  /// Get all zone IDs
  List<String> get zoneIds => _zones.map((z) => z.id).toList();

  /// Check if zone exists
  bool zoneExists(String zoneId) {
    return _zones.any((z) => z.id == zoneId);
  }

  /// Get zones user is currently inside
  List<GeofenceZone> getCurrentZones() {
    return _zones.where((z) => _insideZones[z.id] == true).toList();
  }

  /// Validate zone data
  static bool validateZone({
    required String name,
    required double radius,
    required String type,
  }) {
    if (name.trim().isEmpty) return false;
    if (radius < 50 || radius > 5000) return false;
    if (type != 'safe' && type != 'danger') return false;
    return true;
  }
}