import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

enum ZoneType { safe, danger, home, work, school, custom }

class GeofenceZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final ZoneType type;
  final bool notifyOnEntry;
  final bool notifyOnExit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastEntry;
  final DateTime? lastExit;
  final int entryCount;
  final int exitCount;

  GeofenceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.type,
    this.notifyOnEntry = true,
    this.notifyOnExit = true,
    this.isActive = true,
    required this.createdAt,
    this.lastEntry,
    this.lastExit,
    this.entryCount = 0,
    this.exitCount = 0,
  });

  // ADD: Convenience getter for radius (for compatibility)
  double get radius => radiusMeters;

  factory GeofenceZone.fromMap(Map<String, dynamic> map, String id) {
    return GeofenceZone(
      id: id,
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      radiusMeters: (map['radiusMeters'] ?? 100.0).toDouble(),
      type: _typeFromString(map['type'] ?? 'custom'),
      notifyOnEntry: map['notifyOnEntry'] ?? true,
      notifyOnExit: map['notifyOnExit'] ?? true,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastEntry: (map['lastEntry'] as Timestamp?)?.toDate(),
      lastExit: (map['lastExit'] as Timestamp?)?.toDate(),
      entryCount: map['entryCount'] ?? 0,
      exitCount: map['exitCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'type': _typeToString(type),
      'notifyOnEntry': notifyOnEntry,
      'notifyOnExit': notifyOnExit,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'lastEntry': lastEntry != null ? Timestamp.fromDate(lastEntry!) : null,
      'lastExit': lastExit != null ? Timestamp.fromDate(lastExit!) : null,
      'entryCount': entryCount,
      'exitCount': exitCount,
    };
  }

  static ZoneType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'safe':
        return ZoneType.safe;
      case 'danger':
        return ZoneType.danger;
      case 'home':
        return ZoneType.home;
      case 'work':
        return ZoneType.work;
      case 'school':
        return ZoneType.school;
      default:
        return ZoneType.custom;
    }
  }

  static String _typeToString(ZoneType type) {
    switch (type) {
      case ZoneType.safe:
        return 'safe';
      case ZoneType.danger:
        return 'danger';
      case ZoneType.home:
        return 'home';
      case ZoneType.work:
        return 'work';
      case ZoneType.school:
        return 'school';
      case ZoneType.custom:
        return 'custom';
    }
  }
}

class GeofenceEvent {
  final String id;
  final String zoneId;
  final String zoneName;
  final String eventType;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  GeofenceEvent({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory GeofenceEvent.fromMap(Map<String, dynamic> map, String id) {
    return GeofenceEvent(
      id: id,
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      eventType: map['eventType'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class GeofenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<Position>? _positionStream;
  final Map<String, bool> _zoneStates = {}; // Track if user is inside zone
  Function(GeofenceZone, bool)? onZoneEvent; // Callback for zone entry/exit
  String? _currentUserId;

  // ==================== NEW METHOD: getUserGeofences ====================
  /// Get all geofences for a user (compatibility method for unified safety map)
  Future<List<GeofenceZone>> getUserGeofences(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('geofence_zones')
          .get();

      final geofences = snapshot.docs.map((doc) {
        return GeofenceZone.fromMap(doc.data(), doc.id);
      }).toList();

      debugPrint(' Loaded ${geofences.length} geofences for user');
      return geofences;
    } catch (e) {
      debugPrint(' Get user geofences error: $e');
      return [];
    }
  }

  // Create a geofence zone
  Future<String> createZone({
    required String userId,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required ZoneType type,
    bool notifyOnEntry = true,
    bool notifyOnExit = true,
  }) async {
    try {
      final zone = GeofenceZone(
        id: '',
        name: name,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        type: type,
        notifyOnEntry: notifyOnEntry,
        notifyOnExit: notifyOnExit,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('geofence_zones')
          .add(zone.toMap());

      debugPrint(' Geofence zone created: $name (${docRef.id})');
      return docRef.id;
    } catch (e) {
      debugPrint(' Create geofence zone error: $e');
      rethrow;
    }
  }

  // Get all zones for user
  Stream<List<GeofenceZone>> getZones(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('geofence_zones')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GeofenceZone.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get zones as Future (for one-time fetch)
  Future<List<GeofenceZone>> getZonesList(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('geofence_zones')
          .get();

      return snapshot.docs.map((doc) {
        return GeofenceZone.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get zones list error: $e');
      return [];
    }
  }

  // Get active zones only
  Future<List<GeofenceZone>> getActiveZones(String userId) async {
    try {
      final zones = await getZonesList(userId);
      return zones.where((z) => z.isActive).toList();
    } catch (e) {
      debugPrint(' Get active zones error: $e');
      return [];
    }
  }

  // Update zone
  Future<void> updateZone({
    required String userId,
    required String zoneId,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    ZoneType? type,
    bool? notifyOnEntry,
    bool? notifyOnExit,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (radiusMeters != null) updates['radiusMeters'] = radiusMeters;
      if (type != null) updates['type'] = GeofenceZone._typeToString(type);
      if (notifyOnEntry != null) updates['notifyOnEntry'] = notifyOnEntry;
      if (notifyOnExit != null) updates['notifyOnExit'] = notifyOnExit;
      if (isActive != null) updates['isActive'] = isActive;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('geofence_zones')
          .doc(zoneId)
          .update(updates);

      debugPrint(' Geofence zone updated: $zoneId');
    } catch (e) {
      debugPrint(' Update geofence zone error: $e');
      rethrow;
    }
  }

  // Toggle zone active status
  Future<void> toggleZoneStatus(String userId, String zoneId, bool isActive) async {
    await updateZone(
      userId: userId,
      zoneId: zoneId,
      isActive: isActive,
    );
  }

  // Delete zone
  Future<void> deleteZone(String userId, String zoneId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('geofence_zones')
          .doc(zoneId)
          .delete();

      debugPrint(' Geofence zone deleted: $zoneId');
    } catch (e) {
      debugPrint(' Delete geofence zone error: $e');
      rethrow;
    }
  }

  // Check if position is inside zone
  bool isInsideZone(Position position, GeofenceZone zone) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      zone.latitude,
      zone.longitude,
    );

    return distance <= zone.radiusMeters;
  }

  // Start monitoring geofences
  void startMonitoring(String userId) async {
    _currentUserId = userId;
    debugPrint(' Starting geofence monitoring');

    // Get all zones
    final zonesStream = getZones(userId);
    List<GeofenceZone> currentZones = [];

    zonesStream.listen((zones) {
      currentZones = zones.where((z) => z.isActive).toList();
      debugPrint(' Monitoring ${currentZones.length} active geofence zones');
    });

    // Monitor position changes
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      _checkZones(position, currentZones, userId);
    });
  }

  // Stop monitoring
  void stopMonitoring() {
    _positionStream?.cancel();
    _positionStream = null;
    _zoneStates.clear();
    _currentUserId = null;
    debugPrint(' Stopped geofence monitoring');
  }

  // Check all zones
  void _checkZones(Position position, List<GeofenceZone> zones, String userId) {
    for (final zone in zones) {
      final isInside = isInsideZone(position, zone);
      final wasInside = _zoneStates[zone.id] ?? false;

      // Entry event
      if (isInside && !wasInside) {
        debugPrint(' Entered zone: ${zone.name}');
        _zoneStates[zone.id] = true;

        if (zone.notifyOnEntry && onZoneEvent != null) {
          onZoneEvent!(zone, true); // true = entry
        }

        _logZoneEvent(userId, zone, 'entry', position);
      }

      // Exit event
      else if (!isInside && wasInside) {
        debugPrint(' Exited zone: ${zone.name}');
        _zoneStates[zone.id] = false;

        if (zone.notifyOnExit && onZoneEvent != null) {
          onZoneEvent!(zone, false); // false = exit
        }

        _logZoneEvent(userId, zone, 'exit', position);
      }
    }
  }

  // Log zone events
  Future<void> _logZoneEvent(
      String userId,
      GeofenceZone zone,
      String eventType,
      Position position,
      ) async {
    try {
      // Log event
      await _firestore.collection('geofence_events').add({
        'userId': userId,
        'zoneId': zone.id,
        'zoneName': zone.name,
        'eventType': eventType,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update zone counters
      final updates = <String, dynamic>{};
      if (eventType == 'entry') {
        updates['lastEntry'] = FieldValue.serverTimestamp();
        updates['entryCount'] = FieldValue.increment(1);
      } else {
        updates['lastExit'] = FieldValue.serverTimestamp();
        updates['exitCount'] = FieldValue.increment(1);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('geofence_zones')
          .doc(zone.id)
          .update(updates);

      debugPrint(' Zone event logged: ${zone.name} ($eventType)');
    } catch (e) {
      debugPrint(' Log zone event error: $e');
    }
  }

  // Get zone events/history
  Future<List<GeofenceEvent>> getZoneEvents(
      String userId, {
        String? zoneId,
        int limit = 50,
      }) async {
    try {
      Query query = _firestore
          .collection('geofence_events')
          .where('userId', isEqualTo: userId);

      if (zoneId != null) {
        query = query.where('zoneId', isEqualTo: zoneId);
      }

      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return GeofenceEvent.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get zone events error: $e');
      return [];
    }
  }

  // Get zone statistics
  Future<Map<String, dynamic>> getZoneStatistics(String userId, String zoneId) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('geofence_events')
          .where('userId', isEqualTo: userId)
          .where('zoneId', isEqualTo: zoneId)
          .get();

      final entries = eventsSnapshot.docs
          .where((doc) => doc.data()['eventType'] == 'entry')
          .length;

      final exits = eventsSnapshot.docs
          .where((doc) => doc.data()['eventType'] == 'exit')
          .length;

      final lastEvent = eventsSnapshot.docs.isNotEmpty
          ? eventsSnapshot.docs.first.data()
          : null;

      return {
        'totalEntries': entries,
        'totalExits': exits,
        'lastEvent': lastEvent != null
            ? (lastEvent['timestamp'] as Timestamp?)?.toDate()
            : null,
        'lastEventType': lastEvent?['eventType'],
      };
    } catch (e) {
      debugPrint(' Get zone statistics error: $e');
      return {
        'totalEntries': 0,
        'totalExits': 0,
        'lastEvent': null,
        'lastEventType': null,
      };
    }
  }

  // Get overall statistics
  Future<Map<String, dynamic>> getOverallStatistics(String userId) async {
    try {
      final zones = await getZonesList(userId);
      final events = await getZoneEvents(userId, limit: 1000);

      final totalZones = zones.length;
      final activeZones = zones.where((z) => z.isActive).length;
      final totalEvents = events.length;
      final entryEvents = events.where((e) => e.eventType == 'entry').length;
      final exitEvents = events.where((e) => e.eventType == 'exit').length;

      // Count by type
      final safeZones = zones.where((z) => z.type == ZoneType.safe).length;
      final dangerZones = zones.where((z) => z.type == ZoneType.danger).length;
      final homeZones = zones.where((z) => z.type == ZoneType.home).length;
      final workZones = zones.where((z) => z.type == ZoneType.work).length;

      return {
        'totalZones': totalZones,
        'activeZones': activeZones,
        'totalEvents': totalEvents,
        'entryEvents': entryEvents,
        'exitEvents': exitEvents,
        'safeZones': safeZones,
        'dangerZones': dangerZones,
        'homeZones': homeZones,
        'workZones': workZones,
      };
    } catch (e) {
      debugPrint(' Get overall statistics error: $e');
      return {};
    }
  }

  // Get current zone (which zone user is in)
  Future<GeofenceZone?> getCurrentZone(
      String userId,
      Position position,
      ) async {
    try {
      final zones = await getActiveZones(userId);

      for (final zone in zones) {
        if (isInsideZone(position, zone)) {
          return zone;
        }
      }

      return null;
    } catch (e) {
      debugPrint(' Get current zone error: $e');
      return null;
    }
  }

  // Get type icon
  static String getTypeIcon(ZoneType type) {
    switch (type) {
      case ZoneType.safe:
        return ' ';
      case ZoneType.danger:
        return ' ';
      case ZoneType.home:
        return ' ';
      case ZoneType.work:
        return ' ';
      case ZoneType.school:
        return ' ';
      case ZoneType.custom:
        return ' ';
    }
  }

  // Get type color
  static String getTypeColor(ZoneType type) {
    switch (type) {
      case ZoneType.safe:
        return '#4CAF50'; // Green
      case ZoneType.danger:
        return '#F44336'; // Red
      case ZoneType.home:
        return '#2196F3'; // Blue
      case ZoneType.work:
        return '#FF9800'; // Orange
      case ZoneType.school:
        return '#9C27B0'; // Purple
      case ZoneType.custom:
        return '#607D8B'; // Grey
    }
  }

  // Get type label
  static String getTypeLabel(ZoneType type) {
    switch (type) {
      case ZoneType.safe:
        return 'Safe Zone';
      case ZoneType.danger:
        return 'Danger Zone';
      case ZoneType.home:
        return 'Home';
      case ZoneType.work:
        return 'Work';
      case ZoneType.school:
        return 'School';
      case ZoneType.custom:
        return 'Custom';
    }
  }

  // Format radius for display
  String formatRadius(double radiusMeters) {
    if (radiusMeters >= 1000) {
      return '${(radiusMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${radiusMeters.toInt()} m';
  }

  // Dispose
  void dispose() {
    stopMonitoring();
  }
}