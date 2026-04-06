import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class NearbyPlacesService {
  static final NearbyPlacesService _instance = NearbyPlacesService._internal();
  factory NearbyPlacesService() => _instance;
  NearbyPlacesService._internal();

// Place categories
  static const Map<String, Map<String, dynamic>> placeCategories = {
    'hospital': {
      'name': 'Hospitals',
      'icon': '🏥',
      'color': 0xFFE53935,
      'keywords': ['hospital', 'emergency room', 'medical center', 'clinic'],
    },
    'police': {
      'name': 'Police Stations',
      'icon': '🚓',
      'color': 0xFF1E88E5,
      'keywords': ['police station', 'police department', 'law enforcement'],
    },
    'fire': {
      'name': 'Fire Stations',
      'icon': '🚒',
      'color': 0xFFFF6F00,
      'keywords': ['fire station', 'fire department'],
    },
    'pharmacy': {
      'name': 'Pharmacies',
      'icon': '💊',
      'color': 0xFF43A047,
      'keywords': ['pharmacy', 'drugstore', 'chemist'],
    },
    'gas': {
      'name': 'Gas Stations',
      'icon': '⛽',
      'color': 0xFFFFB300,
      'keywords': ['gas station', 'petrol station', 'fuel'],
    },
    'atm': {
      'name': 'ATMs',
      'icon': '🏧',
      'color': 0xFF00897B,
      'keywords': ['atm', 'cash machine', 'bank'],
    },
    'shelter': {
      'name': 'Shelters',
      'icon': '🏠',
      'color': 0xFF8E24AA,
      'keywords': ['shelter', 'refuge', 'safe house'],
    },
  };

// Simulated places database (in production, use Google Places API)
  static List<Map<String, dynamic>> _generateMockPlaces(
      String category,
      Position currentPosition,
      ) {
    final places = <Map<String, dynamic>>[];
    final random = Random();
    final categoryData = placeCategories[category]!;
    final keywords = categoryData['keywords'] as List<String>;

// Generate 5-10 nearby places
    final count = 5 + random.nextInt(6);

    for (int i = 0; i < count; i++) {
// Generate random offset (within ~5km radius)
      final latOffset = (random.nextDouble() - 0.5) * 0.09; // ~5km
      final lonOffset = (random.nextDouble() - 0.5) * 0.09;

      final lat = currentPosition.latitude + latOffset;
      final lon = currentPosition.longitude + lonOffset;

// Calculate distance
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lon,
      );

      places.add({
        'id': 'place_${category}_$i',
        'name': '${categoryData['name']} ${i + 1}',
        'category': category,
        'latitude': lat,
        'longitude': lon,
        'distance': distance,
        'address': '${100 + i * 50} Main Street, City ${i + 1}',
        'phone': '+1 (555) ${100 + i * 11}-${1000 + i * 100}',
        'rating': 3.5 + random.nextDouble() * 1.5,
        'isOpen': random.nextBool(),
        'openingHours': '24/7',
      });
    }

// Sort by distance
    places.sort((a, b) => a['distance'].compareTo(b['distance']));

    return places;
  }

  /// Find nearby places
  Future<List<Map<String, dynamic>>> findNearbyPlaces({
    required String category,
    required Position position,
    double? radiusMeters,
  }) async {
    try {
      debugPrint('🔍 Finding nearby $category...');

// Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

// Get mock places
      final places = _generateMockPlaces(category, position);

// Filter by radius if specified
      if (radiusMeters != null) {
        final filtered = places.where((place) {
          return place['distance'] <= radiusMeters;
        }).toList();

        debugPrint('✅ Found ${filtered.length} $category within ${radiusMeters}m');
        return filtered;
      }

      debugPrint('✅ Found ${places.length} $category');
      return places;
    } catch (e) {
      debugPrint('❌ Find nearby places error: $e');
      return [];
    }
  }

  /// Get directions to place
  Future<void> getDirections({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) async {
    final url = 'https://www.google.com/maps/dir/?api=1&origin=$fromLat,$fromLon&destination=$toLat,$toLon&travelmode=driving';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('🗺️ Opening directions');
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      debugPrint('❌ Get directions error: $e');
      rethrow;
    }
  }

  /// Call place
  Future<void> callPlace(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('📞 Calling $phoneNumber');
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('❌ Call place error: $e');
      rethrow;
    }
  }

  /// Open place in maps
  Future<void> openInMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('🗺️ Opening in maps');
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      debugPrint('❌ Open in maps error: $e');
      rethrow;
    }
  }

  /// Format distance
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get category data
  static Map<String, dynamic>? getCategoryData(String category) {
    return placeCategories[category];
  }

  /// Get all categories
  static List<String> getAllCategories() {
    return placeCategories.keys.toList();
  }

  /// Calculate estimated travel time (simple estimation)
  static String estimateTravelTime(double distanceMeters) {
// Assume average speed of 40 km/h in city
    final distanceKm = distanceMeters / 1000;
    final hours = distanceKm / 40;
    final minutes = (hours * 60).ceil();

    if (minutes < 1) {
      return '< 1 min';
    } else if (minutes < 60) {
      return '$minutes min';
    } else {
      final hrs = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hrs}h ${mins}m';
    }
  }
}