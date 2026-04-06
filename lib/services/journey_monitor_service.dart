import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';

class JourneyTrip {
  final String id;
  final String? name;
  final DateTime startTime;
  DateTime? endTime;
  final String startLocation;
  String? endLocation;
  final List<TripCheckpoint> checkpoints;
  bool isActive;
  bool arrivedSafely;
  double? totalDistance; // in kilometers

  JourneyTrip({
    required this.id,
    this.name,
    required this.startTime,
    this.endTime,
    required this.startLocation,
    this.endLocation,
    required this.checkpoints,
    this.isActive = true,
    this.arrivedSafely = false,
    this.totalDistance,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'startLocation': startLocation,
    'endLocation': endLocation,
    'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
    'isActive': isActive,
    'arrivedSafely': arrivedSafely,
    'totalDistance': totalDistance,
  };

  factory JourneyTrip.fromJson(Map<String, dynamic> json) => JourneyTrip(
    id: json['id'],
    name: json['name'],
    startTime: DateTime.parse(json['startTime']),
    endTime:
    json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    startLocation: json['startLocation'],
    endLocation: json['endLocation'],
    checkpoints: (json['checkpoints'] as List)
        .map((c) => TripCheckpoint.fromJson(c))
        .toList(),
    isActive: json['isActive'] ?? true,
    arrivedSafely: json['arrivedSafely'] ?? false,
    totalDistance: json['totalDistance'],
  );
}

class TripCheckpoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? note;
  final bool isCheckIn;

  TripCheckpoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.note,
    this.isCheckIn = false,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'note': note,
    'isCheckIn': isCheckIn,
  };

  factory TripCheckpoint.fromJson(Map<String, dynamic> json) => TripCheckpoint(
    timestamp: DateTime.parse(json['timestamp']),
    latitude: json['latitude'],
    longitude: json['longitude'],
    note: json['note'],
    isCheckIn: json['isCheckIn'] ?? false,
  );
}

class CheckInReminder {
  final String id;
  final DateTime scheduledTime;
  final String message;
  bool isCompleted;

  CheckInReminder({
    required this.id,
    required this.scheduledTime,
    required this.message,
    this.isCompleted = false,
  });
}

class ParkingLocation {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? photoUrl;

  ParkingLocation({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'notes': notes,
    'photoUrl': photoUrl,
  };

  factory ParkingLocation.fromJson(Map<String, dynamic> json) =>
      ParkingLocation(
        timestamp: DateTime.parse(json['timestamp']),
        latitude: json['latitude'],
        longitude: json['longitude'],
        notes: json['notes'],
        photoUrl: json['photoUrl'],
      );
}

class JourneyMonitorService {
  static final JourneyMonitorService _instance =
  JourneyMonitorService._internal();
  factory JourneyMonitorService() => _instance;
  JourneyMonitorService._internal();

  static const String _activeTripsKey = 'active_trips';
  static const String _tripHistoryKey = 'trip_history';
  static const String _parkingLocationKey = 'parking_location';
  static const String _settingsKey = 'journey_settings';

  JourneyTrip? _activeTrip;
  List<JourneyTrip> _tripHistory = [];
  ParkingLocation? _savedParkingLocation;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _checkInReminderTimer;

  // Settings
  bool _autoCheckInEnabled = true;
  int _checkInIntervalMinutes = 30;
  bool _routeDeviationAlertsEnabled = true;
  double _deviationThresholdKm = 2.0;

  /// Initialize service
  Future<void> initialize() async {
    await _loadActiveTrip();
    await _loadTripHistory();
    await _loadParkingLocation();
    await _loadSettings();

    if (_activeTrip != null && _activeTrip!.isActive) {
      _resumeMonitoring();
    }

    debugPrint(' Journey Monitor Service initialized');
  }

  /// Start new trip
  Future<JourneyTrip> startTrip({String? name, String? destination}) async {
    if (_activeTrip != null && _activeTrip!.isActive) {
      throw Exception('A trip is already in progress');
    }

    try {
      final position = await _getCurrentPosition();
      final locationName = await _getLocationName(position);

      _activeTrip = JourneyTrip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? 'Trip to ${destination ?? "destination"}',
        startTime: DateTime.now(),
        startLocation: locationName,
        checkpoints: [
          TripCheckpoint(
            timestamp: DateTime.now(),
            latitude: position.latitude,
            longitude: position.longitude,
            note: 'Trip started',
            isCheckIn: true,
          ),
        ],
        isActive: true,
      );

      await _saveActiveTrip();
      _startMonitoring();

      debugPrint(' Trip started: ${_activeTrip!.name}');
      return _activeTrip!;
    } catch (e) {
      debugPrint(' Start trip error: $e');
      rethrow;
    }
  }

  /// End active trip
  Future<void> endTrip({required bool arrivedSafely}) async {
    if (_activeTrip == null || !_activeTrip!.isActive) {
      throw Exception('No active trip to end');
    }

    try {
      final position = await _getCurrentPosition();
      final locationName = await _getLocationName(position);

      _activeTrip!.endTime = DateTime.now();
      _activeTrip!.endLocation = locationName;
      _activeTrip!.isActive = false;
      _activeTrip!.arrivedSafely = arrivedSafely;

      // Add final checkpoint
      _activeTrip!.checkpoints.add(
        TripCheckpoint(
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          note: arrivedSafely ? 'Arrived safely' : 'Trip ended',
          isCheckIn: true,
        ),
      );

      // Calculate total distance
      _activeTrip!.totalDistance = _calculateTotalDistance();

      // Move to history
      _tripHistory.insert(0, _activeTrip!);
      await _saveTripHistory();

      _stopMonitoring();
      _activeTrip = null;
      await _saveActiveTrip();

      debugPrint(' Trip ended safely: $arrivedSafely');
    } catch (e) {
      debugPrint(' End trip error: $e');
      rethrow;
    }
  }

  /// Add manual check-in
  Future<void> addCheckIn({String? note}) async {
    if (_activeTrip == null || !_activeTrip!.isActive) {
      throw Exception('No active trip');
    }

    try {
      final position = await _getCurrentPosition();

      final checkpoint = TripCheckpoint(
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        note: note ?? 'Manual check-in',
        isCheckIn: true,
      );

      _activeTrip!.checkpoints.add(checkpoint);
      await _saveActiveTrip();

      debugPrint(' Check-in added');
    } catch (e) {
      debugPrint(' Add check-in error: $e');
      rethrow;
    }
  }

  /// Save parking location
  Future<void> saveParkingLocation({String? notes}) async {
    try {
      final position = await _getCurrentPosition();

      _savedParkingLocation = ParkingLocation(
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        notes: notes,
      );

      await _saveParkingLocationToStorage();
      debugPrint(' Parking location saved');
    } catch (e) {
      debugPrint(' Save parking error: $e');
      rethrow;
    }
  }

  /// Clear parking location
  Future<void> clearParkingLocation() async {
    _savedParkingLocation = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_parkingLocationKey);
    debugPrint(' Parking location cleared');
  }

  /// Get active trip
  JourneyTrip? getActiveTrip() => _activeTrip;

  /// Get trip history
  List<JourneyTrip> getTripHistory() => _tripHistory;

  /// Get saved parking location
  ParkingLocation? getParkingLocation() => _savedParkingLocation;

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final completedTrips =
    _tripHistory.where((trip) => trip.endTime != null).toList();
    final totalDistance = completedTrips.fold<double>(
      0,
          (sum, trip) => sum + (trip.totalDistance ?? 0),
    );
    final totalDuration = completedTrips.fold<Duration>(
      Duration.zero,
          (sum, trip) => sum + trip.duration,
    );

    return {
      'totalTrips': _tripHistory.length,
      'completedTrips': completedTrips.length,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration.inMinutes,
      'averageDistance':
      completedTrips.isNotEmpty ? totalDistance / completedTrips.length : 0,
      'safeArrivals':
      _tripHistory.where((trip) => trip.arrivedSafely).length,
    };
  }

  /// Settings
  bool isAutoCheckInEnabled() => _autoCheckInEnabled;
  int getCheckInInterval() => _checkInIntervalMinutes;
  bool isRouteDeviationAlertsEnabled() => _routeDeviationAlertsEnabled;
  double getDeviationThreshold() => _deviationThresholdKm;

  Future<void> setAutoCheckIn(bool enabled, int intervalMinutes) async {
    _autoCheckInEnabled = enabled;
    _checkInIntervalMinutes = intervalMinutes;
    await _saveSettings();

    if (enabled && _activeTrip != null) {
      _startCheckInReminders();
    } else {
      _stopCheckInReminders();
    }
  }

  Future<void> setRouteDeviationAlerts(
      bool enabled, double thresholdKm) async {
    _routeDeviationAlertsEnabled = enabled;
    _deviationThresholdKm = thresholdKm;
    await _saveSettings();
  }

  /// Start monitoring location
  void _startMonitoring() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    ).listen((position) {
      _onLocationUpdate(position);
    });

    if (_autoCheckInEnabled) {
      _startCheckInReminders();
    }

    debugPrint(' Location monitoring started');
  }

  /// Stop monitoring
  void _stopMonitoring() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _stopCheckInReminders();
    debugPrint(' Location monitoring stopped');
  }

  /// Resume monitoring (after app restart)
  void _resumeMonitoring() {
    if (_activeTrip != null && _activeTrip!.isActive) {
      _startMonitoring();
      debugPrint(' Monitoring resumed for active trip');
    }
  }

  /// Handle location updates
  void _onLocationUpdate(Position position) {
    if (_activeTrip == null || !_activeTrip!.isActive) return;

    // Add checkpoint every X updates (not every location update)
    if (_activeTrip!.checkpoints.length % 10 == 0) {
      _activeTrip!.checkpoints.add(
        TripCheckpoint(
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
      _saveActiveTrip();
    }

    // Check for route deviation (simplified)
    if (_routeDeviationAlertsEnabled) {
      _checkRouteDeviation(position);
    }
  }

  /// Check for route deviation
  void _checkRouteDeviation(Position currentPosition) {
    if (_activeTrip == null || _activeTrip!.checkpoints.isEmpty) return;

    final lastCheckpoint = _activeTrip!.checkpoints.last;
    final distance = Geolocator.distanceBetween(
      lastCheckpoint.latitude,
      lastCheckpoint.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    if (distance / 1000 > _deviationThresholdKm) {
      debugPrint(' Route deviation detected: ${distance / 1000} km');
      // In real app, would trigger notification
    }
  }

  /// Start check-in reminders
  void _startCheckInReminders() {
    _stopCheckInReminders();
    _checkInReminderTimer = Timer.periodic(
      Duration(minutes: _checkInIntervalMinutes),
          (timer) {
        debugPrint(' Check-in reminder triggered');
        // In real app, would show notification
      },
    );
  }

  /// Stop check-in reminders
  void _stopCheckInReminders() {
    _checkInReminderTimer?.cancel();
    _checkInReminderTimer = null;
  }

  /// Calculate total trip distance
  double _calculateTotalDistance() {
    if (_activeTrip == null || _activeTrip!.checkpoints.length < 2) {
      return 0;
    }

    double total = 0;
    for (int i = 1; i < _activeTrip!.checkpoints.length; i++) {
      final prev = _activeTrip!.checkpoints[i - 1];
      final curr = _activeTrip!.checkpoints[i];
      total += Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
    }

    return total / 1000; // Convert to km
  }

  /// Get current position
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Get location name (mock)
  Future<String> _getLocationName(Position position) async {
    // In real app, would use geocoding
    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }

  /// Storage methods
  Future<void> _loadActiveTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripJson = prefs.getString(_activeTripsKey);
      if (tripJson != null) {
        _activeTrip = JourneyTrip.fromJson(json.decode(tripJson));
      }
    } catch (e) {
      debugPrint(' Load active trip error: $e');
    }
  }

  Future<void> _saveActiveTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeTrip != null) {
        await prefs.setString(
            _activeTripsKey, json.encode(_activeTrip!.toJson()));
      } else {
        await prefs.remove(_activeTripsKey);
      }
    } catch (e) {
      debugPrint(' Save active trip error: $e');
    }
  }

  Future<void> _loadTripHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_tripHistoryKey);
      if (historyJson != null) {
        _tripHistory = historyJson
            .map((str) => JourneyTrip.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load trip history error: $e');
    }
  }

  Future<void> _saveTripHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _tripHistory
          .take(50) // Keep last 50 trips
          .map((trip) => json.encode(trip.toJson()))
          .toList();
      await prefs.setStringList(_tripHistoryKey, historyJson);
    } catch (e) {
      debugPrint(' Save trip history error: $e');
    }
  }

  Future<void> _loadParkingLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parkingJson = prefs.getString(_parkingLocationKey);
      if (parkingJson != null) {
        _savedParkingLocation =
            ParkingLocation.fromJson(json.decode(parkingJson));
      }
    } catch (e) {
      debugPrint(' Load parking location error: $e');
    }
  }

  Future<void> _saveParkingLocationToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_savedParkingLocation != null) {
        await prefs.setString(_parkingLocationKey,
            json.encode(_savedParkingLocation!.toJson()));
      }
    } catch (e) {
      debugPrint(' Save parking location error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = json.decode(settingsJson);
        _autoCheckInEnabled = settings['autoCheckInEnabled'] ?? true;
        _checkInIntervalMinutes = settings['checkInIntervalMinutes'] ?? 30;
        _routeDeviationAlertsEnabled =
            settings['routeDeviationAlertsEnabled'] ?? true;
        _deviationThresholdKm = settings['deviationThresholdKm'] ?? 2.0;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'autoCheckInEnabled': _autoCheckInEnabled,
        'checkInIntervalMinutes': _checkInIntervalMinutes,
        'routeDeviationAlertsEnabled': _routeDeviationAlertsEnabled,
        'deviationThresholdKm': _deviationThresholdKm,
      };
      await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint(' Save settings error: $e');
    }
  }

  /// Dispose
  void dispose() {
    _locationSubscription?.cancel();
    _checkInReminderTimer?.cancel();
  }
}