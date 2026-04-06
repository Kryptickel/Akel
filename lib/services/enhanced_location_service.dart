import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class EnhancedLocationService {
  static final EnhancedLocationService _instance = EnhancedLocationService._internal();
  factory EnhancedLocationService() => _instance;
  EnhancedLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  String? _currentAddress;
  List<Position> _locationHistory = [];

  // Location tracking settings
  bool _isTracking = false;
  int _trackingIntervalSeconds = 30;
  final int _maxHistorySize = 100;

  // Callbacks
  Function(Position)? _onLocationUpdate;
  Function(String)? _onAddressUpdate;

  // Statistics
  double _totalDistanceTraveled = 0.0;
  int _locationUpdates = 0;

  /// Initialize service
  Future<void> initialize({
    Function(Position)? onLocationUpdate,
    Function(String)? onAddressUpdate,
  }) async {
    _onLocationUpdate = onLocationUpdate;
    _onAddressUpdate = onAddressUpdate;

    debugPrint(' Enhanced Location Service initialized');
  }

  // ==================== NEW METHOD: getPositionStream ====================
  /// Get position stream for real-time tracking
  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(' Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint(' Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(' Location permission permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      _addToHistory(position);
      _locationUpdates++;

      debugPrint(' Current location: ${position.latitude}, ${position.longitude}');

      // Get address
      await _updateAddress(position);

      _onLocationUpdate?.call(position);

      return position;
    } catch (e) {
      debugPrint(' Get current location error: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<void> startTracking({int? intervalSeconds}) async {
    if (_isTracking) {
      debugPrint(' Already tracking location');
      return;
    }

    if (intervalSeconds != null) {
      _trackingIntervalSeconds = intervalSeconds;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      _isTracking = true;

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Duration(seconds: _trackingIntervalSeconds),
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
            (Position position) {
          _handleLocationUpdate(position);
        },
        onError: (error) {
          debugPrint(' Location tracking error: $error');
        },
      );

      debugPrint(' Location tracking started (interval: $_trackingIntervalSeconds seconds)');
    } catch (e) {
      _isTracking = false;
      debugPrint(' Start tracking error: $e');
      rethrow;
    }
  }

  /// Stop location tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;

    debugPrint(' Location tracking stopped');
  }

  /// Handle location update
  void _handleLocationUpdate(Position position) {
    if (_currentPosition != null) {
      // Calculate distance from last position
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      _totalDistanceTraveled += distance;
    }

    _currentPosition = position;
    _addToHistory(position);
    _locationUpdates++;

    debugPrint(' Location updated: ${position.latitude}, ${position.longitude}');

    _onLocationUpdate?.call(position);

    // Update address periodically (not every update to save API calls)
    if (_locationUpdates % 5 == 0) {
      _updateAddress(position);
    }
  }

  /// Add position to history
  void _addToHistory(Position position) {
    _locationHistory.add(position);

    if (_locationHistory.length > _maxHistorySize) {
      _locationHistory.removeAt(0);
    }
  }

  /// Update current address
  Future<void> _updateAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentAddress = _formatAddress(place);

        debugPrint(' Address: $_currentAddress');
        _onAddressUpdate?.call(_currentAddress!);
      }
    } catch (e) {
      debugPrint(' Get address error: $e');
    }
  }

  /// Format address from placemark
  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      parts.add(place.postalCode!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    return parts.join(', ');
  }

  /// Calculate distance between two coordinates (in meters)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        return _formatAddress(placemarks.first);
      }

      return null;
    } catch (e) {
      debugPrint(' Get address from coordinates error: $e');
      return null;
    }
  }

  /// Get coordinates from address
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }

      return null;
    } catch (e) {
      debugPrint(' Get coordinates from address error: $e');
      return null;
    }
  }

  /// Save location to Firestore
  Future<void> saveLocation({
    required String userId,
    required Position position,
    String? label,
    String? notes,
  }) async {
    try {
      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'address': address,
        'label': label,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(' Location saved to Firestore');
    } catch (e) {
      debugPrint(' Save location error: $e');
    }
  }

  /// Get saved locations
  Future<List<Map<String, dynamic>>> getSavedLocations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint(' Get saved locations error: $e');
      return [];
    }
  }

  /// Share location (generate shareable data)
  Map<String, dynamic> shareCurrentLocation() {
    if (_currentPosition == null) {
      throw Exception('No current location available');
    }

    return {
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
      'accuracy': _currentPosition!.accuracy,
      'address': _currentAddress ?? 'Address not available',
      'timestamp': DateTime.now().toIso8601String(),
      'googleMapsUrl': 'https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}',
    };
  }

  /// Get location history
  List<Position> getLocationHistory() {
    return List.from(_locationHistory);
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isTracking': _isTracking,
      'locationUpdates': _locationUpdates,
      'totalDistanceTraveled': _totalDistanceTraveled,
      'totalDistanceKm': (_totalDistanceTraveled / 1000).toStringAsFixed(2),
      'historySize': _locationHistory.length,
      'hasCurrentLocation': _currentPosition != null,
      'currentAccuracy': _currentPosition?.accuracy.toStringAsFixed(2) ?? 'N/A',
    };
  }

  /// Get distance to location
  double? getDistanceToLocation(double latitude, double longitude) {
    if (_currentPosition == null) return null;

    return _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  /// Check if within radius of location
  bool isWithinRadius({
    required double targetLat,
    required double targetLon,
    required double radiusMeters,
  }) {
    if (_currentPosition == null) return false;

    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLon,
    );

    return distance <= radiusMeters;
  }

  /// Get bearing to location (direction in degrees)
  double? getBearingToLocation(double latitude, double longitude) {
    if (_currentPosition == null) return null;

    return Geolocator.bearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    }
  }

  /// Format bearing to compass direction
  static String bearingToCompass(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isTracking => _isTracking;
  double get totalDistanceTraveled => _totalDistanceTraveled;

  /// Dispose
  void dispose() {
    stopTracking();
  }
}