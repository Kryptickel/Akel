import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationHistoryService {
  static final LocationHistoryService _instance = LocationHistoryService._internal();
  factory LocationHistoryService() => _instance;
  LocationHistoryService._internal();

  Timer? _trackingTimer;
  bool _isTracking = false;
  String? _currentEmergencyId;
  final List<LocationPoint> _currentTrail = [];

  // Callbacks
  Function(LocationPoint point)? onLocationUpdated;
  Function(String message)? onLog;

  bool get isTracking => _isTracking;
  String? get currentEmergencyId => _currentEmergencyId;
  List<LocationPoint> get currentTrail => List.unmodifiable(_currentTrail);
  int get totalPointsRecorded => _currentTrail.length;

  Future<void> startTracking(String emergencyId) async {
    if (_isTracking) {
      debugPrint('LocationHistory: Already tracking');
      return;
    }

    _currentEmergencyId = emergencyId;
    _isTracking = true;
    _currentTrail.clear();

    debugPrint('LocationHistory: Started tracking for emergency ' + emergencyId);
    onLog?.call('Location tracking started');

    await _recordLocation();

    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isTracking) {
        await _recordLocation();
      }
    });
  }

  Future<void> startEmergencyTracking(String emergencyId) async {
    await startTracking(emergencyId);
    onLog?.call('Emergency tracking active');
    debugPrint('LocationHistory: Emergency tracking started');
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _trackingTimer?.cancel();
    _trackingTimer = null;
    _isTracking = false;

    debugPrint('LocationHistory: Stopped tracking. Recorded ' + _currentTrail.length.toString() + ' points');
    onLog?.call('Location tracking stopped. ' + _currentTrail.length.toString() + ' points recorded');

    _currentEmergencyId = null;
    _currentTrail.clear();
  }

  Future<void> _recordLocation() async {
    if (_currentEmergencyId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final point = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
        altitude: position.altitude,
        isEmergency: true,
      );

      _currentTrail.add(point);

      await FirebaseFirestore.instance
          .collection('panic_alerts')
          .doc(_currentEmergencyId)
          .collection('location_history')
          .add({
        'latitude': point.latitude,
        'longitude': point.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'accuracy': point.accuracy,
        'speed': point.speed,
        'altitude': point.altitude,
        'isEmergency': point.isEmergency,
        'pointIndex': _currentTrail.length,
      });

      onLocationUpdated?.call(point);

      debugPrint('LocationHistory: Recorded point ' + _currentTrail.length.toString() + ': ' + point.latitude.toString() + ', ' + point.longitude.toString());
    } catch (e) {
      debugPrint('LocationHistory: Failed to record location: ' + e.toString());
    }
  }

  Future<void> addEmergencyMarker(String emergencyId, String note) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final point = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
        altitude: position.altitude,
        isEmergency: true,
        note: note,
      );

      _currentTrail.add(point);

      await FirebaseFirestore.instance
          .collection('panic_alerts')
          .doc(emergencyId)
          .collection('location_history')
          .add({
        'latitude': point.latitude,
        'longitude': point.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'accuracy': point.accuracy,
        'speed': point.speed,
        'altitude': point.altitude,
        'isEmergency': true,
        'note': note,
        'pointIndex': _currentTrail.length,
      });

      onLocationUpdated?.call(point);
      onLog?.call('Emergency marker added: ' + note);
      debugPrint('LocationHistory: Emergency marker added: ' + note);
    } catch (e) {
      debugPrint('LocationHistory: Failed to add marker: ' + e.toString());
    }
  }

  Future<LocationPoint?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
        altitude: position.altitude,
      );
    } catch (e) {
      debugPrint('LocationHistory: Failed to get current location: ' + e.toString());
      return null;
    }
  }

  Future<List<LocationPoint>> getHistoryForEmergency(String emergencyId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('panic_alerts')
          .doc(emergencyId)
          .collection('location_history')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LocationPoint(
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          accuracy: (data['accuracy'] as num? ?? 0.0).toDouble(),
          speed: (data['speed'] as num? ?? 0.0).toDouble(),
          altitude: (data['altitude'] as num? ?? 0.0).toDouble(),
          isEmergency: data['isEmergency'] as bool? ?? false,
          note: data['note'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('LocationHistory: Failed to fetch history: ' + e.toString());
      return [];
    }
  }

  Future<List<LocationPoint>> getRecentHistory(String emergencyId, {int limit = 50}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('panic_alerts')
          .doc(emergencyId)
          .collection('location_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final points = snapshot.docs.map((doc) {
        final data = doc.data();
        return LocationPoint(
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          accuracy: (data['accuracy'] as num? ?? 0.0).toDouble(),
          speed: (data['speed'] as num? ?? 0.0).toDouble(),
          altitude: (data['altitude'] as num? ?? 0.0).toDouble(),
          isEmergency: data['isEmergency'] as bool? ?? false,
          note: data['note'] as String?,
        );
      }).toList();

      return points.reversed.toList();
    } catch (e) {
      debugPrint('LocationHistory: Failed to fetch recent history: ' + e.toString());
      return [];
    }
  }

  double calculateTotalDistance(List<LocationPoint> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < points.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return totalDistance;
  }

  Future<Map<String, dynamic>> getStatistics(List<LocationPoint> points) async {
    if (points.isEmpty) {
      return {
        'totalPoints': 0,
        'totalDistance': 0.0,
        'averageSpeed': 0.0,
        'maxSpeed': 0.0,
        'duration': Duration.zero,
        'startTime': null,
        'endTime': null,
        'emergencyPoints': 0,
      };
    }

    double totalDistance = 0.0;
    double totalSpeed = 0.0;
    double maxSpeed = 0.0;
    int emergencyPoints = 0;

    for (int i = 0; i < points.length; i++) {
      if (i > 0) {
        totalDistance += Geolocator.distanceBetween(
          points[i - 1].latitude,
          points[i - 1].longitude,
          points[i].latitude,
          points[i].longitude,
        );
      }

      if (points[i].speed > maxSpeed) {
        maxSpeed = points[i].speed;
      }

      totalSpeed += points[i].speed;

      if (points[i].isEmergency) {
        emergencyPoints++;
      }
    }

    final duration = points.last.timestamp.difference(points.first.timestamp);
    final averageSpeed = totalSpeed / points.length;

    return {
      'totalPoints': points.length,
      'totalDistance': totalDistance,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'duration': duration,
      'startTime': points.first.timestamp,
      'endTime': points.last.timestamp,
      'emergencyPoints': emergencyPoints,
      'isTracking': _isTracking,
      'currentTrailLength': _currentTrail.length,
    };
  }

  String exportToCSV(List<LocationPoint> points) {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Latitude,Longitude,Accuracy,Speed,Altitude,IsEmergency,Note');

    for (final point in points) {
      buffer.writeln(
        point.timestamp.toIso8601String() + ',' +
            point.latitude.toString() + ',' +
            point.longitude.toString() + ',' +
            point.accuracy.toString() + ',' +
            point.speed.toString() + ',' +
            point.altitude.toString() + ',' +
            point.isEmergency.toString() + ',' +
            (point.note ?? ''),
      );
    }

    return buffer.toString();
  }

  String exportToJson(List<LocationPoint> points) {
    final buffer = StringBuffer();
    buffer.write('[');

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      buffer.write('{');
      buffer.write('"timestamp":"' + point.timestamp.toIso8601String() + '",');
      buffer.write('"latitude":' + point.latitude.toString() + ',');
      buffer.write('"longitude":' + point.longitude.toString() + ',');
      buffer.write('"accuracy":' + point.accuracy.toString() + ',');
      buffer.write('"speed":' + point.speed.toString() + ',');
      buffer.write('"altitude":' + point.altitude.toString() + ',');
      buffer.write('"isEmergency":' + point.isEmergency.toString() + ',');
      buffer.write('"note":"' + (point.note ?? '') + '"');
      buffer.write('}');
      if (i < points.length - 1) {
        buffer.write(',');
      }
    }

    buffer.write(']');
    return buffer.toString();
  }

  void dispose() {
    stopTracking();
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double speed;
  final double altitude;
  final bool isEmergency;
  final String? note;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    required this.speed,
    required this.altitude,
    this.isEmergency = false,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
      'altitude': altitude,
      'isEmergency': isEmergency,
      'note': note,
    };
  }
}