import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class PlacesService {
  // Singleton pattern
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  // YOUR GOOGLE PLACES API KEY
  static const String _apiKey = 'AIzaSyB-XnURPPKNzLevLhsgNtS_KU1uX5viV00';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // ==================== NEARBY SEARCH ====================

  /// Get nearby hospitals
  Future<List<Map<String, dynamic>>> getNearbyHospitals(
      double latitude,
      double longitude, {
        int radius = 5000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'hospital',
      radius: radius,
    );
  }

  /// Get nearby police stations
  Future<List<Map<String, dynamic>>> getNearbyPoliceStations(
      double latitude,
      double longitude, {
        int radius = 5000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'police',
      radius: radius,
    );
  }

  /// Get nearby fire stations
  Future<List<Map<String, dynamic>>> getNearbyFireStations(
      double latitude,
      double longitude, {
        int radius = 5000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'fire_station',
      radius: radius,
    );
  }

  /// Get nearby pharmacies
  Future<List<Map<String, dynamic>>> getNearbyPharmacies(
      double latitude,
      double longitude, {
        int radius = 5000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'pharmacy',
      radius: radius,
    );
  }

  /// Get nearby gas stations
  Future<List<Map<String, dynamic>>> getNearbyGasStations(
      double latitude,
      double longitude, {
        int radius = 5000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'gas_station',
      radius: radius,
    );
  }

  /// Get nearby ATMs
  Future<List<Map<String, dynamic>>> getNearbyATMs(
      double latitude,
      double longitude, {
        int radius = 2000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'atm',
      radius: radius,
    );
  }

  /// Get nearby restaurants
  Future<List<Map<String, dynamic>>> getNearbyRestaurants(
      double latitude,
      double longitude, {
        int radius = 2000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'restaurant',
      radius: radius,
    );
  }

  /// Get nearby hotels
  Future<List<Map<String, dynamic>>> getNearbyHotels(
      double latitude,
      double longitude, {
        int radius = 5000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'lodging',
      radius: radius,
    );
  }

  /// Get nearby parking
  Future<List<Map<String, dynamic>>> getNearbyParking(
      double latitude,
      double longitude, {
        int radius = 1000,
      }) async {
    return _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: 'parking',
      radius: radius,
    );
  }

  // ==================== GENERIC NEARBY SEARCH ====================

  /// Generic method to get nearby places by type
  Future<List<Map<String, dynamic>>> _getNearbyPlaces({
    required double latitude,
    required double longitude,
    required String type,
    int radius = 5000,
    String? keyword,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json?'
            'location=$latitude,$longitude&'
            'radius=$radius&'
            'type=$type&'
            '${keyword != null ? 'keyword=$keyword&' : ''}'
            'key=$_apiKey',
      );

      debugPrint(' Searching for $type near ($latitude, $longitude)');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = (data['results'] as List)
              .map((place) => place as Map<String, dynamic>)
              .toList();

          debugPrint(' Found ${results.length} $type places');
          return results;
        } else if (data['status'] == 'ZERO_RESULTS') {
          debugPrint(' No $type places found');
          return [];
        } else {
          debugPrint(' Places API error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      } else {
        debugPrint(' HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint(' Error fetching nearby places: $e');
      return [];
    }
  }

  // ==================== TEXT SEARCH ====================

  /// Search nearby places by query
  Future<List<Map<String, dynamic>>> searchNearby({
    required String query,
    required double latitude,
    required double longitude,
    int radius = 10000,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/textsearch/json?'
            'query=$query&'
            'location=$latitude,$longitude&'
            'radius=$radius&'
            'key=$_apiKey',
      );

      debugPrint(' Searching for: $query');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = (data['results'] as List)
              .map((place) => place as Map<String, dynamic>)
              .toList();

          debugPrint(' Found ${results.length} results for "$query"');
          return results;
        } else if (data['status'] == 'ZERO_RESULTS') {
          debugPrint(' No results for "$query"');
          return [];
        } else {
          debugPrint(' Search error: ${data['status']}');
          return [];
        }
      } else {
        debugPrint(' HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint(' Error searching places: $e');
      return [];
    }
  }

  // ==================== PLACE DETAILS ====================

  /// Get detailed information about a place
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?'
            'place_id=$placeId&'
            'fields=name,formatted_address,formatted_phone_number,opening_hours,website,rating,user_ratings_total,geometry,photos&'
            'key=$_apiKey',
      );

      debugPrint(' Getting details for place: $placeId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          debugPrint(' Place details retrieved');
          return data['result'] as Map<String, dynamic>;
        } else {
          debugPrint(' Place details error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint(' HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint(' Error getting place details: $e');
      return null;
    }
  }

  // ==================== AUTOCOMPLETE ====================

  /// Get autocomplete suggestions
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions({
    required String input,
    required double latitude,
    required double longitude,
    int radius = 50000,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/autocomplete/json?'
            'input=$input&'
            'location=$latitude,$longitude&'
            'radius=$radius&'
            'key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = (data['predictions'] as List)
              .map((prediction) => prediction as Map<String, dynamic>)
              .toList();

          return predictions;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint(' Error getting autocomplete: $e');
      return [];
    }
  }

  // ==================== DISTANCE CALCULATION ====================

  /// Calculate distance between two points (Haversine formula)
  double calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // ==================== SORTING & FILTERING ====================

  /// Sort places by distance from current location
  List<Map<String, dynamic>> sortByDistance(
      List<Map<String, dynamic>> places,
      double currentLat,
      double currentLon,
      ) {
    final placesWithDistance = places.map((place) {
      final lat = place['geometry']['location']['lat'] as double;
      final lng = place['geometry']['location']['lng'] as double;
      final distance = calculateDistance(currentLat, currentLon, lat, lng);

      return {
        ...place,
        'distance': distance,
        'distanceFormatted': formatDistance(distance),
      };
    }).toList();

    placesWithDistance.sort((a, b) {
      final distA = a['distance'] as double;
      final distB = b['distance'] as double;
      return distA.compareTo(distB);
    });

    return placesWithDistance;
  }

  /// Filter places by rating
  List<Map<String, dynamic>> filterByRating(
      List<Map<String, dynamic>> places,
      double minRating,
      ) {
    return places.where((place) {
      final rating = place['rating'] as double?;
      return rating != null && rating >= minRating;
    }).toList();
  }

  /// Filter places currently open
  List<Map<String, dynamic>> filterOpenNow(
      List<Map<String, dynamic>> places,
      ) {
    return places.where((place) {
      final openingHours = place['opening_hours'] as Map<String, dynamic>?;
      return openingHours?['open_now'] == true;
    }).toList();
  }

  // ==================== EMERGENCY SERVICES ====================

  /// Get nearest emergency service
  Future<Map<String, dynamic>?> getNearestEmergencyService({
    required double latitude,
    required double longitude,
    required String type, // 'hospital', 'police', 'fire_station'
  }) async {
    final places = await _getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      type: type,
      radius: 10000, // 10km radius
    );

    if (places.isEmpty) return null;

    // Sort by distance
    final sorted = sortByDistance(places, latitude, longitude);

    return sorted.first;
  }

  /// Get all emergency services nearby
  Future<Map<String, List<Map<String, dynamic>>>> getAllEmergencyServices({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    final results = await Future.wait([
      getNearbyHospitals(latitude, longitude, radius: radius),
      getNearbyPoliceStations(latitude, longitude, radius: radius),
      getNearbyFireStations(latitude, longitude, radius: radius),
    ]);

    return {
      'hospitals': sortByDistance(results[0], latitude, longitude),
      'police': sortByDistance(results[1], latitude, longitude),
      'fire': sortByDistance(results[2], latitude, longitude),
    };
  }

  // ==================== PHOTO URL ====================

  /// Get photo URL for a place
  String? getPhotoUrl(Map<String, dynamic> place, {int maxWidth = 400}) {
    final photos = place['photos'] as List?;
    if (photos == null || photos.isEmpty) return null;

    final photoReference = photos[0]['photo_reference'] as String;

    return 'https://maps.googleapis.com/maps/api/place/photo?'
        'maxwidth=$maxWidth&'
        'photo_reference=$photoReference&'
        'key=$_apiKey';
  }

  // ==================== CACHE (OPTIONAL) ====================

  final Map<String, List<Map<String, dynamic>>> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Clear cache
  void clearCache() {
    _cache.clear();
    debugPrint(' Places cache cleared');
  }

  /// Get cached results if available
  List<Map<String, dynamic>>? _getCached(String key) {
    return _cache[key];
  }

  /// Cache results
  void _setCached(String key, List<Map<String, dynamic>> results) {
    _cache[key] = results;

    // Auto-clear after duration
    Future.delayed(_cacheDuration, () {
      _cache.remove(key);
    });
  }

  // ==================== UTILITIES ====================

  /// Check if API key is configured
  bool isConfigured() {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE';
  }

  /// Get icon for place type
  IconData getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'fire_station':
        return Icons.local_fire_department;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'gas_station':
        return Icons.local_gas_station;
      case 'atm':
        return Icons.atm;
      case 'restaurant':
        return Icons.restaurant;
      case 'lodging':
      case 'hotel':
        return Icons.hotel;
      case 'parking':
        return Icons.local_parking;
      default:
        return Icons.place;
    }
  }

  /// Get color for place type
  Color getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'fire_station':
        return Colors.orange;
      case 'pharmacy':
        return Colors.green;
      case 'gas_station':
        return Colors.yellow;
      case 'atm':
        return Colors.purple;
      case 'restaurant':
        return Colors.amber;
      case 'lodging':
      case 'hotel':
        return Colors.teal;
      case 'parking':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}