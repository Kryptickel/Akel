import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  bool _isTracking = false;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint(' Check location service error: $e');
      return false;
    }
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint(' Check permission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(' Location permissions are permanently denied');
        return LocationPermission.deniedForever;
      }

      if (permission == LocationPermission.denied) {
        debugPrint(' Location permissions are denied');
        return LocationPermission.denied;
      }

      debugPrint(' Location permission granted');
      return permission;
    } catch (e) {
      debugPrint(' Request permission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Get current location
  Future<Position> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permission
      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastKnownPosition = position;
      debugPrint(' Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint(' Get current location error: $e');
      rethrow;
    }
  }

  /// Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _lastKnownPosition = position;
      }
      return position;
    } catch (e) {
      debugPrint(' Get last known position error: $e');
      return null;
    }
  }

  /// Start tracking location
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) {
    _isTracking = true;
    debugPrint(' Location tracking started');

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map((position) {
      _lastKnownPosition = position;
      return position;
    });
  }

  /// Stop tracking location
  void stopTracking() {
    _isTracking = false;
    debugPrint(' Location tracking stopped');
  }

  /// Calculate distance between two positions (in meters)
  double calculateDistance(Position from, Position to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calculate distance from current location to coordinates
  Future<double?> getDistanceFromCurrent(double latitude, double longitude) async {
    try {
      final currentPosition = await getCurrentLocation();
      return Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        latitude,
        longitude,
      );
    } catch (e) {
      debugPrint(' Calculate distance error: $e');
      return null;
    }
  }

  /// Get bearing between two positions (in degrees)
  double calculateBearing(Position from, Position to) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Check if user is within radius of location
  Future<bool> isWithinRadius({
    required double targetLat,
    required double targetLng,
    required double radiusInMeters,
  }) async {
    try {
      final currentPosition = await getCurrentLocation();
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLat,
        targetLng,
      );
      return distance <= radiusInMeters;
    } catch (e) {
      debugPrint(' Check radius error: $e');
      return false;
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint(' Open settings error: $e');
    }
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint(' Open app settings error: $e');
    }
  }

  /// Get location accuracy
  Future<LocationAccuracyStatus> getLocationAccuracy() async {
    try {
      return await Geolocator.getLocationAccuracy();
    } catch (e) {
      debugPrint(' Get accuracy error: $e');
      return LocationAccuracyStatus.reduced;
    }
  }

  /// Request temporary precise location (iOS 14+)
  Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) async {
    try {
      return await Geolocator.requestTemporaryFullAccuracy(
        purposeKey: purposeKey,
      );
    } catch (e) {
      debugPrint(' Request full accuracy error: $e');
      return LocationAccuracyStatus.reduced;
    }
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Format coordinates for display
  String formatCoordinates(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Get location as string
  String getLocationString(Position position) {
    return 'Lat: ${position.latitude.toStringAsFixed(4)}, '
        'Lng: ${position.longitude.toStringAsFixed(4)}';
  }

  /// Get Google Maps URL
  String getGoogleMapsUrl(Position position) {
    return 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
  }

  /// Get last known position (cached)
  Position? get cachedPosition => _lastKnownPosition;

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Get location age (how old is the cached location)
  Duration? getLocationAge() {
    if (_lastKnownPosition == null) return null;
    return DateTime.now().difference(_lastKnownPosition!.timestamp);
  }

  /// Check if cached location is fresh (less than 5 minutes old)
  bool isCachedLocationFresh() {
    final age = getLocationAge();
    if (age == null) return false;
    return age.inMinutes < 5;
  }

  /// Get location with fallback to cached
  Future<Position?> getLocationWithFallback() async {
    try {
      return await getCurrentLocation();
    } catch (e) {
      debugPrint(' Using cached location due to error: $e');
      return _lastKnownPosition ?? await getLastKnownPosition();
    }
  }

  /// Validate coordinates
  static bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Get location permission status as string
  String getPermissionStatusString(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
        return 'Always Allowed';
      case LocationPermission.whileInUse:
        return 'While Using App';
      case LocationPermission.denied:
        return 'Denied';
      case LocationPermission.deniedForever:
        return 'Permanently Denied';
      default:
        return 'Unknown';
    }
  }

  /// Clear cached location
  void clearCache() {
    _lastKnownPosition = null;
    debugPrint(' Location cache cleared');
  }

  /// Get detailed location info
  Map<String, dynamic> getLocationInfo(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'speed': position.speed,
      'speedAccuracy': position.speedAccuracy,
      'heading': position.heading,
      'timestamp': position.timestamp.toIso8601String(),
      'isMocked': position.isMocked,
    };
  }
}