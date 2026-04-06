import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

class SafeZone {
  final String id;
  final String name;
  final String type; // 'police', 'hospital', 'safe_house', 'public', 'custom'
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String description;
  final bool isPublic;
  final DateTime createdAt;
  final List<String> features; // 'cameras', 'lighting', 'guards', etc.
  final int safetyRating; // 1-5
  final String? contactInfo;

  SafeZone({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.description,
    this.isPublic = true,
    required this.createdAt,
    this.features = const [],
    this.safetyRating = 3,
    this.contactInfo,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'description': description,
    'isPublic': isPublic,
    'createdAt': createdAt.toIso8601String(),
    'features': features,
    'safetyRating': safetyRating,
    'contactInfo': contactInfo,
  };

  factory SafeZone.fromJson(Map<String, dynamic> json) => SafeZone(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radius: (json['radius'] as num).toDouble(),
    description: json['description'] as String,
    isPublic: json['isPublic'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
    features: (json['features'] as List?)?.map((e) => e as String).toList() ?? [],
    safetyRating: json['safetyRating'] as int? ?? 3,
    contactInfo: json['contactInfo'] as String?,
  );

  SafeZone copyWith({
    String? id,
    String? name,
    String? type,
    double? latitude,
    double? longitude,
    double? radius,
    String? description,
    bool? isPublic,
    DateTime? createdAt,
    List<String>? features,
    int? safetyRating,
    String? contactInfo,
  }) {
    return SafeZone(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      features: features ?? this.features,
      safetyRating: safetyRating ?? this.safetyRating,
      contactInfo: contactInfo ?? this.contactInfo,
    );
  }
}

class SafeZoneVisualizationService {
  static final SafeZoneVisualizationService _instance =
  SafeZoneVisualizationService._internal();
  factory SafeZoneVisualizationService() => _instance;
  SafeZoneVisualizationService._internal();

  static const String _zonesKey = 'safe_zones';

  List<SafeZone> _zones = [];

  /// Get all safe zones
  Future<List<SafeZone>> getAllZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesJson = prefs.getStringList(_zonesKey) ?? [];

      _zones = zonesJson.map((jsonStr) {
        try {
          final Map<String, dynamic> data = json.decode(jsonStr);
          return SafeZone.fromJson(data);
        } catch (e) {
          debugPrint('❌ Error parsing safe zone: $e');
          return null;
        }
      }).whereType<SafeZone>().toList();

      debugPrint('✅ Loaded ${_zones.length} safe zones');
      return _zones;
    } catch (e) {
      debugPrint('❌ Get safe zones error: $e');
      return [];
    }
  }

  /// Add new safe zone
  Future<void> addZone(SafeZone zone) async {
    try {
      _zones.add(zone);
      await _saveZones();
      debugPrint('✅ Safe zone added: ${zone.name}');
    } catch (e) {
      debugPrint('❌ Add safe zone error: $e');
      rethrow;
    }
  }

  /// Update zone
  Future<void> updateZone(SafeZone zone) async {
    try {
      final index = _zones.indexWhere((z) => z.id == zone.id);
      if (index != -1) {
        _zones[index] = zone;
        await _saveZones();
        debugPrint('✅ Safe zone updated: ${zone.name}');
      }
    } catch (e) {
      debugPrint('❌ Update safe zone error: $e');
      rethrow;
    }
  }

  /// Delete zone
  Future<void> deleteZone(String zoneId) async {
    try {
      _zones.removeWhere((z) => z.id == zoneId);
      await _saveZones();
      debugPrint('✅ Safe zone deleted');
    } catch (e) {
      debugPrint('❌ Delete safe zone error: $e');
      rethrow;
    }
  }

  /// Get zones by type
  List<SafeZone> getZonesByType(String type) {
    return _zones.where((z) => z.type == type).toList();
  }

  /// Get public zones only
  List<SafeZone> getPublicZones() {
    return _zones.where((z) => z.isPublic).toList();
  }

  /// Get zones near position
  List<SafeZone> getZonesNearPosition(
      Position position,
      double radiusInMeters,
      ) {
    return _zones.where((zone) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  /// Check if position is inside any safe zone
  Map<String, dynamic>? isInsideSafeZone(Position position) {
    for (final zone in _zones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      if (distance <= zone.radius) {
        return {
          'zone': zone,
          'distance': distance,
        };
      }
    }
    return null;
  }

  /// Get nearest safe zone
  Map<String, dynamic>? getNearestSafeZone(Position position) {
    if (_zones.isEmpty) return null;

    SafeZone? nearestZone;
    double? minDistance;

    for (final zone in _zones) {
      final distance = Geolocator.distanceBetween(
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
    };
  }

  /// Get zones sorted by safety rating
  List<SafeZone> getZonesBySafetyRating({int minRating = 1}) {
    final filtered = _zones.where((z) => z.safetyRating >= minRating).toList();
    filtered.sort((a, b) => b.safetyRating.compareTo(a.safetyRating));
    return filtered;
  }

  /// Create circle overlay for zone
  Circle createZoneCircle(SafeZone zone) {
    return Circle(
      circleId: CircleId(zone.id),
      center: LatLng(zone.latitude, zone.longitude),
      radius: zone.radius,
      fillColor: _getZoneColor(zone).withValues(alpha: 0.2),
      strokeColor: _getZoneColor(zone),
      strokeWidth: 2,
    );
  }

  /// Create marker for zone
  Marker createZoneMarker(SafeZone zone, {VoidCallback? onTap}) {
    return Marker(
      markerId: MarkerId(zone.id),
      position: LatLng(zone.latitude, zone.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        _getMarkerHue(zone.type),
      ),
      infoWindow: InfoWindow(
        title: zone.name,
        snippet: '${_getZoneTypeIcon(zone.type)} Safety: ${'⭐' * zone.safetyRating}',
      ),
      onTap: onTap,
    );
  }

  Color _getZoneColor(SafeZone zone) {
    switch (zone.type) {
      case 'police':
        return Colors.blue;
      case 'hospital':
        return Colors.red;
      case 'safe_house':
        return Colors.green;
      case 'public':
        return Colors.orange;
      case 'custom':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  double _getMarkerHue(String type) {
    switch (type) {
      case 'police':
        return BitmapDescriptor.hueBlue;
      case 'hospital':
        return BitmapDescriptor.hueRed;
      case 'safe_house':
        return BitmapDescriptor.hueGreen;
      case 'public':
        return BitmapDescriptor.hueOrange;
      case 'custom':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  String _getZoneTypeIcon(String type) {
    switch (type) {
      case 'police':
        return '🚓';
      case 'hospital':
        return '🏥';
      case 'safe_house':
        return '🏠';
      case 'public':
        return '🏛️';
      case 'custom':
        return '📍';
      default:
        return '🛡️';
    }
  }

  /// Save zones
  Future<void> _saveZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesJson = _zones.map((zone) => json.encode(zone.toJson())).toList();
      await prefs.setStringList(_zonesKey, zonesJson);
      debugPrint('✅ Saved ${_zones.length} zones to storage');
    } catch (e) {
      debugPrint('❌ Save safe zones error: $e');
      rethrow;
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalZones': _zones.length,
      'policeStations': _zones.where((z) => z.type == 'police').length,
      'hospitals': _zones.where((z) => z.type == 'hospital').length,
      'safeHouses': _zones.where((z) => z.type == 'safe_house').length,
      'publicZones': _zones.where((z) => z.isPublic).length,
      'averageRating': _zones.isEmpty
          ? 0.0
          : _zones.map((z) => z.safetyRating).reduce((a, b) => a + b) /
          _zones.length,
      'totalCoverage': _zones.map((z) => z.radius).reduce((a, b) => a + b),
    };
  }

  /// Get zone types
  static const List<Map<String, dynamic>> zoneTypes = [
    {
      'value': 'police',
      'name': 'Police Station',
      'icon': '🚓',
      'color': 0xFF2196F3,
    },
    {
      'value': 'hospital',
      'name': 'Hospital',
      'icon': '🏥',
      'color': 0xFFE53935,
    },
    {
      'value': 'safe_house',
      'name': 'Safe House',
      'icon': '🏠',
      'color': 0xFF4CAF50,
    },
    {
      'value': 'public',
      'name': 'Public Zone',
      'icon': '🏛️',
      'color': 0xFFFF9800,
    },
    {
      'value': 'custom',
      'name': 'Custom Zone',
      'icon': '📍',
      'color': 0xFF9C27B0,
    },
  ];

  /// Get available features
  static const List<String> availableFeatures = [
    'CCTV Cameras',
    'Street Lighting',
    'Security Guards',
    'Emergency Call Box',
    'Public Restrooms',
    'Well-lit Area',
    '24/7 Access',
    'Police Patrol',
  ];

  /// Clear all zones
  Future<void> clearAllZones() async {
    try {
      _zones.clear();
      await _saveZones();
      debugPrint('🧹 All safe zones cleared');
    } catch (e) {
      debugPrint('❌ Clear all zones error: $e');
      rethrow;
    }
  }

  /// Get zone by ID
  SafeZone? getZoneById(String zoneId) {
    try {
      return _zones.firstWhere((z) => z.id == zoneId);
    } catch (e) {
      return null;
    }
  }

  /// Format distance
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Initialize sample data
  Future<void> initializeSampleData(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_zonesKey);

      if (existing == null || existing.isEmpty) {
// Add sample safe zones around user's location
        final sampleZones = [
          SafeZone(
            id: '1',
            name: 'Central Police Station',
            type: 'police',
            latitude: position.latitude + 0.02,
            longitude: position.longitude + 0.02,
            radius: 500,
            description: 'Main police headquarters with 24/7 service',
            isPublic: true,
            createdAt: DateTime.now(),
            features: ['CCTV Cameras', 'Security Guards', '24/7 Access', 'Emergency Call Box'],
            safetyRating: 5,
            contactInfo: '911',
          ),
          SafeZone(
            id: '2',
            name: 'City General Hospital',
            type: 'hospital',
            latitude: position.latitude - 0.015,
            longitude: position.longitude + 0.025,
            radius: 400,
            description: 'Full-service hospital with emergency room',
            isPublic: true,
            createdAt: DateTime.now(),
            features: ['CCTV Cameras', 'Security Guards', '24/7 Access', 'Well-lit Area'],
            safetyRating: 5,
            contactInfo: '(555) 123-4567',
          ),
          SafeZone(
            id: '3',
            name: 'Community Safe House',
            type: 'safe_house',
            latitude: position.latitude + 0.01,
            longitude: position.longitude - 0.02,
            radius: 300,
            description: 'Designated safe house for emergencies',
            isPublic: true,
            createdAt: DateTime.now(),
            features: ['CCTV Cameras', 'Emergency Call Box', 'Well-lit Area'],
            safetyRating: 4,
          ),
          SafeZone(
            id: '4',
            name: 'Downtown Public Square',
            type: 'public',
            latitude: position.latitude - 0.01,
            longitude: position.longitude - 0.01,
            radius: 600,
            description: 'Well-lit public area with heavy foot traffic',
            isPublic: true,
            createdAt: DateTime.now(),
            features: ['Street Lighting', 'Police Patrol', 'Well-lit Area', 'Public Restrooms'],
            safetyRating: 4,
          ),
          SafeZone(
            id: '5',
            name: 'Shopping District',
            type: 'public',
            latitude: position.latitude + 0.025,
            longitude: position.longitude - 0.015,
            radius: 700,
            description: 'Busy commercial area with security',
            isPublic: true,
            createdAt: DateTime.now(),
            features: ['CCTV Cameras', 'Security Guards', 'Street Lighting', 'Well-lit Area'],
            safetyRating: 4,
          ),
        ];

        for (final zone in sampleZones) {
          await addZone(zone);
        }

        debugPrint('✅ Sample safe zones initialized');
      }
    } catch (e) {
      debugPrint('❌ Initialize sample data error: $e');
    }
  }
}