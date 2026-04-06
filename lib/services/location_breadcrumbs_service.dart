import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

/// ==================== LOCATION BREADCRUMBS SERVICE ====================
///
/// Track location history with time tracking and navigation
///
/// FEATURES:
/// - Automatic location tracking
/// - Dwell time calculation
/// - Named locations (geofencing)
/// - Navigation to past locations
/// - Persistent storage
///
/// ======================================================================

class LocationBreadcrumbsService {
  bool _isInitialized = false;
  bool _isTracking = false;

  final List<LocationBreadcrumb> _breadcrumbs = [];
  final StreamController<List<LocationBreadcrumb>> _breadcrumbsStreamController =
  StreamController<List<LocationBreadcrumb>>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _dwellTimer;

  LocationBreadcrumb? _currentLocation;
  Position? _lastPosition;

  // Configuration
  static const double _movementThresholdMeters = 50.0; // 50m to register new location
  static const Duration _minDwellTime = Duration(minutes: 5); // Min 5 min to save location
  static const int _maxBreadcrumbs = 20; // Keep last 20 locations

  // Geofence database (predefined locations)
  final Map<String, GeofenceLocation> _geofences = {};

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Load saved breadcrumbs
      await _loadBreadcrumbs();

      // Load geofences
      await _loadGeofences();

      _isInitialized = true;
      debugPrint(' Location Breadcrumbs Service initialized');
      debugPrint(' Loaded ${_breadcrumbs.length} breadcrumbs');
      debugPrint(' Loaded ${_geofences.length} geofences');
    } catch (e) {
      debugPrint(' Breadcrumbs init error: $e');
    }
  }

  // ==================== TRACKING ====================

  Future<void> startTracking() async {
    try {
      if (!_isInitialized) await initialize();
      if (_isTracking) return;

      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint(' Location permission denied');
        return;
      }

      // Start position stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(_onPositionUpdate);

      // Start dwell timer (check every minute)
      _dwellTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _updateDwellTime();
      });

      _isTracking = true;
      debugPrint(' Location tracking started');
    } catch (e) {
      debugPrint(' Start tracking error: $e');
    }
  }

  Future<void> stopTracking() async {
    try {
      _positionSubscription?.cancel();
      _positionSubscription = null;

      _dwellTimer?.cancel();
      _dwellTimer = null;

      // Save current location if exists
      if (_currentLocation != null) {
        _currentLocation!.departureTime = DateTime.now();
        await _saveBreadcrumbs();
      }

      _isTracking = false;
      debugPrint(' Location tracking stopped');
    } catch (e) {
      debugPrint(' Stop tracking error: $e');
    }
  }

  // ==================== POSITION UPDATES ====================

  void _onPositionUpdate(Position position) {
    try {
      // Check if this is a new location
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance < _movementThresholdMeters) {
          // Still at same location, update dwell time
          return;
        }
      }

      // New location detected
      _handleNewLocation(position);
      _lastPosition = position;
    } catch (e) {
      debugPrint(' Position update error: $e');
    }
  }

  void _handleNewLocation(Position position) {
    try {
      // Save previous location
      if (_currentLocation != null) {
        _currentLocation!.departureTime = DateTime.now();

        // Only save if dwell time > minimum
        if (_currentLocation!.dwellDuration >= _minDwellTime) {
          _breadcrumbs.add(_currentLocation!);

          // Keep only last N breadcrumbs
          if (_breadcrumbs.length > _maxBreadcrumbs) {
            _breadcrumbs.removeAt(0);
          }

          _saveBreadcrumbs();
        }
      }

      // Check if location matches a geofence
      final geofence = _findMatchingGeofence(position.latitude, position.longitude);

      // Create new breadcrumb
      _currentLocation = LocationBreadcrumb(
        name: geofence?.name ?? 'Unknown Location',
        icon: geofence?.icon ?? ' ',
        latitude: position.latitude,
        longitude: position.longitude,
        arrivalTime: DateTime.now(),
        departureTime: null,
        dwellDuration: Duration.zero,
        address: geofence?.address ?? 'Getting address...',
      );

      // Notify listeners
      _breadcrumbsStreamController.add(
          List.from(_breadcrumbs)..add(_currentLocation!)
      );

      debugPrint(' New breadcrumb: ${_currentLocation!.name}');

      // Get address if not from geofence
      if (geofence == null) {
        _getAddressForLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint(' Handle new location error: $e');
    }
  }

  void _updateDwellTime() {
    if (_currentLocation == null) return;

    final now = DateTime.now();
    _currentLocation!.dwellDuration = now.difference(_currentLocation!.arrivalTime);

    // Notify listeners
    _breadcrumbsStreamController.add(
        List.from(_breadcrumbs)..add(_currentLocation!)
    );
  }

  // ==================== GEOFENCING ====================

  GeofenceLocation? _findMatchingGeofence(double lat, double lng) {
    for (final geofence in _geofences.values) {
      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        geofence.latitude,
        geofence.longitude,
      );

      if (distance <= geofence.radiusMeters) {
        return geofence;
      }
    }
    return null;
  }

  Future<void> addGeofence({
    required String id,
    required String name,
    required String icon,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String? address,
  }) async {
    try {
      _geofences[id] = GeofenceLocation(
        id: id,
        name: name,
        icon: icon,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        address: address ?? name,
      );

      await _saveGeofences();
      debugPrint(' Geofence added: $name');
    } catch (e) {
      debugPrint(' Add geofence error: $e');
    }
  }

  Future<void> removeGeofence(String id) async {
    try {
      _geofences.remove(id);
      await _saveGeofences();
      debugPrint(' Geofence removed: $id');
    } catch (e) {
      debugPrint(' Remove geofence error: $e');
    }
  }

  // ==================== ADDRESS LOOKUP ====================

  Future<void> _getAddressForLocation(double lat, double lng) async {
    try {
      // In real implementation, would use geocoding service
      // For now, use coordinates
      if (_currentLocation != null) {
        _currentLocation!.address = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

        _breadcrumbsStreamController.add(
            List.from(_breadcrumbs)..add(_currentLocation!)
        );
      }
    } catch (e) {
      debugPrint(' Get address error: $e');
    }
  }

  // ==================== PERSISTENCE ====================

  Future<void> _loadBreadcrumbs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final breadcrumbsJson = prefs.getString('location_breadcrumbs');

      if (breadcrumbsJson != null) {
        final List<dynamic> breadcrumbsList = jsonDecode(breadcrumbsJson);
        _breadcrumbs.clear();

        for (final breadcrumbData in breadcrumbsList) {
          _breadcrumbs.add(LocationBreadcrumb.fromJson(breadcrumbData));
        }

        debugPrint(' Loaded ${_breadcrumbs.length} breadcrumbs');
      }
    } catch (e) {
      debugPrint(' Load breadcrumbs error: $e');
    }
  }

  Future<void> _saveBreadcrumbs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final breadcrumbsJson = jsonEncode(
          _breadcrumbs.map((b) => b.toJson()).toList()
      );

      await prefs.setString('location_breadcrumbs', breadcrumbsJson);
    } catch (e) {
      debugPrint(' Save breadcrumbs error: $e');
    }
  }

  Future<void> _loadGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final geofencesJson = prefs.getString('location_geofences');

      if (geofencesJson != null) {
        final Map<String, dynamic> geofencesMap = jsonDecode(geofencesJson);
        _geofences.clear();

        geofencesMap.forEach((key, value) {
          _geofences[key] = GeofenceLocation.fromJson(value);
        });

        debugPrint(' Loaded ${_geofences.length} geofences');
      } else {
        // Create default geofences
        await _createDefaultGeofences();
      }
    } catch (e) {
      debugPrint(' Load geofences error: $e');
    }
  }

  Future<void> _saveGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final geofencesMap = <String, dynamic>{};

      _geofences.forEach((key, value) {
        geofencesMap[key] = value.toJson();
      });

      final geofencesJson = jsonEncode(geofencesMap);
      await prefs.setString('location_geofences', geofencesJson);
    } catch (e) {
      debugPrint(' Save geofences error: $e');
    }
  }

  Future<void> _createDefaultGeofences() async {
    // Example default geofences - user can add more
    await addGeofence(
      id: 'home',
      name: 'Home',
      icon: ' ',
      latitude: 0.0, // User should set their actual home location
      longitude: 0.0,
      radiusMeters: 100,
      address: 'Home',
    );

    await addGeofence(
      id: 'work',
      name: 'Work',
      icon: ' ',
      latitude: 0.0, // User should set their actual work location
      longitude: 0.0,
      radiusMeters: 100,
      address: 'Work',
    );
  }

  // ==================== PUBLIC API ====================

  List<LocationBreadcrumb> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  Stream<List<LocationBreadcrumb>> get breadcrumbsStream =>
      _breadcrumbsStreamController.stream;

  LocationBreadcrumb? get currentLocation => _currentLocation;

  Future<void> clearBreadcrumbs() async {
    try {
      _breadcrumbs.clear();
      _currentLocation = null;
      await _saveBreadcrumbs();

      _breadcrumbsStreamController.add([]);

      debugPrint(' Breadcrumbs cleared');
    } catch (e) {
      debugPrint(' Clear breadcrumbs error: $e');
    }
  }

  // ==================== STATUS ====================

  bool get isInitialized => _isInitialized;
  bool get isTracking => _isTracking;
  int get breadcrumbCount => _breadcrumbs.length;
  int get geofenceCount => _geofences.length;

  // ==================== DISPOSE ====================

  void dispose() {
    stopTracking();
    _breadcrumbsStreamController.close();
    _isInitialized = false;
    debugPrint(' Location Breadcrumbs Service disposed');
  }
}

// ==================== LOCATION BREADCRUMB MODEL ====================

class LocationBreadcrumb {
  final String name;
  final String icon;
  final double latitude;
  final double longitude;
  final DateTime arrivalTime;
  DateTime? departureTime;
  Duration dwellDuration;
  String address;

  LocationBreadcrumb({
    required this.name,
    required this.icon,
    required this.latitude,
    required this.longitude,
    required this.arrivalTime,
    this.departureTime,
    required this.dwellDuration,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'latitude': latitude,
    'longitude': longitude,
    'arrivalTime': arrivalTime.toIso8601String(),
    'departureTime': departureTime?.toIso8601String(),
    'dwellDuration': dwellDuration.inSeconds,
    'address': address,
  };

  factory LocationBreadcrumb.fromJson(Map<String, dynamic> json) => LocationBreadcrumb(
    name: json['name'],
    icon: json['icon'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    arrivalTime: DateTime.parse(json['arrivalTime']),
    departureTime: json['departureTime'] != null
        ? DateTime.parse(json['departureTime'])
        : null,
    dwellDuration: Duration(seconds: json['dwellDuration']),
    address: json['address'],
  );
}

// ==================== GEOFENCE LOCATION MODEL ====================

class GeofenceLocation {
  final String id;
  final String name;
  final String icon;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String address;

  GeofenceLocation({
    required this.id,
    required this.name,
    required this.icon,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'address': address,
  };

  factory GeofenceLocation.fromJson(Map<String, dynamic> json) => GeofenceLocation(
    id: json['id'],
    name: json['name'],
    icon: json['icon'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    radiusMeters: json['radiusMeters'],
    address: json['address'],
  );
}