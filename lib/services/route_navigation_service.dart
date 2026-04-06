import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class RouteStep {
  final String instruction;
  final double distance; // in meters
  final int duration; // in seconds
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver; // turn-left, turn-right, straight, etc.

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });
}

class RouteInfo {
  final List<LatLng> polylinePoints;
  final List<RouteStep> steps;
  final double totalDistance; // in meters
  final int totalDuration; // in seconds
  final String summary;
  final bool hasTraffic;
  final String trafficLevel; // 'low', 'moderate', 'heavy'

  RouteInfo({
    required this.polylinePoints,
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
    required this.summary,
    this.hasTraffic = false,
    this.trafficLevel = 'low',
  });

  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toInt()}m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(1)}km';
    }
  }

  String get formattedDuration {
    final minutes = (totalDuration / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours hr $remainingMinutes min';
    }
  }
}

class RouteNavigationService {
  static final RouteNavigationService _instance = RouteNavigationService._internal();
  factory RouteNavigationService() => _instance;
  RouteNavigationService._internal();

  /// Calculate route between two points
  Future<RouteInfo> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    bool avoidHighways = false,
    bool avoidTolls = false,
  }) async {
    try {
// In production, you would call Google Directions API here
// For now, we'll generate a simulated route
      return _generateSimulatedRoute(origin, destination);
    } catch (e) {
      debugPrint('❌ Calculate route error: $e');
      rethrow;
    }
  }

  /// Generate simulated route (for demo/testing)
  RouteInfo _generateSimulatedRoute(LatLng origin, LatLng destination) {
// Calculate straight-line distance
    final distance = _calculateDistance(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

// Generate polyline points (simplified straight line with some variation)
    final polylinePoints = _generatePolylinePoints(origin, destination);

// Generate route steps
    final steps = _generateRouteSteps(polylinePoints, distance);

// Estimate duration (assuming average speed of 40 km/h in city)
    final durationSeconds = ((distance / 1000) / 40 * 3600).toInt();

    return RouteInfo(
      polylinePoints: polylinePoints,
      steps: steps,
      totalDistance: distance,
      totalDuration: durationSeconds,
      summary: 'Fastest route via main roads',
      hasTraffic: true,
      trafficLevel: _getRandomTrafficLevel(),
    );
  }

  /// Generate polyline points between origin and destination
  List<LatLng> _generatePolylinePoints(LatLng origin, LatLng destination) {
    final points = <LatLng>[];
    const numPoints = 10;

    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * t;

// Add slight variation to make it look more realistic
      final variation = math.sin(t * math.pi * 2) * 0.001;
      points.add(LatLng(lat + variation, lng + variation));
    }

    return points;
  }

  /// Generate route steps
  List<RouteStep> _generateRouteSteps(List<LatLng> points, double totalDistance) {
    final steps = <RouteStep>[];
    final maneuvers = ['turn-right', 'turn-left', 'straight', 'slight-right', 'slight-left'];
    final streets = ['Main St', 'Oak Ave', 'Maple Dr', 'Cedar Rd', 'Pine Blvd', 'Elm St'];

    for (int i = 0; i < points.length - 1; i++) {
      final stepDistance = _calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );

      final maneuver = i == 0 ? 'straight' : maneuvers[i % maneuvers.length];
      final street = streets[i % streets.length];

      String instruction;
      if (i == 0) {
        instruction = 'Head toward $street';
      } else if (i == points.length - 2) {
        instruction = 'Arrive at destination';
      } else {
        instruction = '${_getManeuverText(maneuver)} onto $street';
      }

      steps.add(RouteStep(
        instruction: instruction,
        distance: stepDistance,
        duration: (stepDistance / 1000 / 40 * 3600).toInt(),
        startLocation: points[i],
        endLocation: points[i + 1],
        maneuver: maneuver,
      ));
    }

    return steps;
  }

  String _getManeuverText(String maneuver) {
    switch (maneuver) {
      case 'turn-right':
        return 'Turn right';
      case 'turn-left':
        return 'Turn left';
      case 'slight-right':
        return 'Slight right';
      case 'slight-left':
        return 'Slight left';
      case 'straight':
        return 'Continue straight';
      default:
        return 'Continue';
    }
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  String _getRandomTrafficLevel() {
    final levels = ['low', 'moderate', 'heavy'];
    return levels[math.Random().nextInt(levels.length)];
  }

  /// Get navigation icon for maneuver
  IconData getManeuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-left':
        return Icons.turn_left;
      case 'slight-right':
        return Icons.turn_slight_right;
      case 'slight-left':
        return Icons.turn_slight_left;
      case 'straight':
        return Icons.straight;
      default:
        return Icons.navigation;
    }
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Format duration for display
  String formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours hr $remainingMinutes min';
    }
  }

  /// Get traffic color
  Color getTrafficColor(String level) {
    switch (level) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'heavy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Calculate ETA
  DateTime calculateETA(int durationSeconds) {
    return DateTime.now().add(Duration(seconds: durationSeconds));
  }

  /// Format ETA
  String formatETA(DateTime eta) {
    final hour = eta.hour;
    final minute = eta.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}