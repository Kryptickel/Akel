import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/hospital.dart';
import '../core/constants/themes/utils/api_keys.dart';

// NEW: Hospital Review Model
class HospitalReview {
  final String id;
  final String hospitalId;
  final String userName;
  final double rating;
  final String title;
  final String comment;
  final DateTime date;
  final Map<String, double> categoryRatings;

  HospitalReview({
    required this.id,
    required this.hospitalId,
    required this.userName,
    required this.rating,
    required this.title,
    required this.comment,
    required this.date,
    this.categoryRatings = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hospitalId': hospitalId,
    'userName': userName,
    'rating': rating,
    'title': title,
    'comment': comment,
    'date': date.toIso8601String(),
    'categoryRatings': categoryRatings,
  };

  factory HospitalReview.fromJson(Map<String, dynamic> json) =>
      HospitalReview(
        id: json['id'] as String,
        hospitalId: json['hospitalId'] as String,
        userName: json['userName'] as String,
        rating: (json['rating'] as num).toDouble(),
        title: json['title'] as String,
        comment: json['comment'] as String,
        date: DateTime.parse(json['date'] as String),
        categoryRatings: (json['categoryRatings'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            {},
      );
}

class HospitalService {
  static final HospitalService _instance = HospitalService._internal();
  factory HospitalService() => _instance;
  HospitalService._internal();

// NEW: Storage keys
  static const String _reviewsKey = 'hospital_reviews';
  static const String _favoritesKey = 'favorite_hospitals';

// NEW: Cache for reviews
  List<HospitalReview> _reviews = [];
  List<String> _favoriteHospitalIds = [];

// EXISTING: Get user's current location
  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

// EXISTING: Search nearby hospitals using Google Places API
  Future<List<Hospital>> searchNearbyHospitals({
    required double latitude,
    required double longitude,
    double radiusMiles = 10,
    FacilityType? filterType,
  }) async {
// Convert miles to meters
    final radiusMeters = (radiusMiles * 1609.34).toInt();

    if (ApiKeys.isGooglePlacesConfigured) {
      return await _searchWithGooglePlaces(
        latitude,
        longitude,
        radiusMeters,
        filterType,
      );
    } else {
// Use mock data for testing
      return _getMockHospitals(latitude, longitude, filterType);
    }
  }

// EXISTING: Search with Google Places API (production)
  Future<List<Hospital>> _searchWithGooglePlaces(
      double latitude,
      double longitude,
      int radiusMeters,
      FacilityType? filterType,
      ) async {
    try {
      final apiKey = ApiKeys.googlePlacesApiKey;
      final type = _getPlaceType(filterType);

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
            'location=$latitude,$longitude'
            '&radius=$radiusMeters'
            '&type=$type'
            '&key=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        final hospitals = <Hospital>[];
        for (final result in results) {
          final hospital = _parseGooglePlaceResult(result, latitude, longitude);
          hospitals.add(hospital);
        }

// Sort by distance
        hospitals.sort((a, b) => a.distance.compareTo(b.distance));
        return hospitals;
      }
    } catch (e) {
      print('Google Places API error: $e');
    }

// Fallback to mock data
    return _getMockHospitals(latitude, longitude, filterType);
  }

  String _getPlaceType(FacilityType? type) {
    switch (type) {
      case FacilityType.hospital:
      case FacilityType.emergencyRoom:
        return 'hospital';
      case FacilityType.pharmacy:
        return 'pharmacy';
      case FacilityType.clinic:
      case FacilityType.urgentCare:
        return 'doctor';
      default:
        return 'hospital';
    }
  }

  Hospital _parseGooglePlaceResult(
      Map<String, dynamic> result,
      double userLat,
      double userLng,
      ) {
    final geometry = result['geometry']['location'];
    final lat = geometry['lat'];
    final lng = geometry['lng'];
    final distance = _calculateDistance(userLat, userLng, lat, lng);

    return Hospital(
      id: result['place_id'],
      name: result['name'] ?? 'Unknown',
      address: result['vicinity'] ?? 'Address not available',
      latitude: lat,
      longitude: lng,
      phoneNumber: result['formatted_phone_number'] ?? 'Not available',
      type: _determineFacilityType(result['types']),
      rating: (result['rating'] ?? 0.0).toDouble(),
      reviewCount: result['user_ratings_total'] ?? 0,
      distance: distance,
      isOpen24Hours: result['opening_hours']?['open_now'] ?? false,
    );
  }

  FacilityType _determineFacilityType(List<dynamic>? types) {
    if (types == null) return FacilityType.hospital;

    if (types.contains('pharmacy')) return FacilityType.pharmacy;
    if (types.contains('hospital')) return FacilityType.hospital;
    if (types.contains('doctor')) return FacilityType.clinic;

    return FacilityType.hospital;
  }

// EXISTING: Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 3959; // Earth's radius in miles
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

// EXISTING: Mock data for testing/demo
  List<Hospital> _getMockHospitals(
      double userLat,
      double userLng,
      FacilityType? filterType,
      ) {
    final random = Random();
    final hospitals = <Hospital>[];

// Generate mock hospitals around user's location
    final mockData = [
      {
        'name': 'City General Hospital',
        'type': FacilityType.hospital,
        'hasER': true,
        'rating': 4.5,
        'reviews': 1250,
        'waitTime': 25,
      },
      {
        'name': 'MediCare Urgent Care Center',
        'type': FacilityType.urgentCare,
        'hasER': false,
        'rating': 4.7,
        'reviews': 890,
        'waitTime': 12,
      },
      {
        'name': 'HealthPlus Pharmacy',
        'type': FacilityType.pharmacy,
        'hasER': false,
        'rating': 4.3,
        'reviews': 456,
        'waitTime': 5,
      },
      {
        'name': 'Memorial Hospital & Medical Center',
        'type': FacilityType.hospital,
        'hasER': true,
        'rating': 4.6,
        'reviews': 2100,
        'waitTime': 35,
      },
      {
        'name': 'Quick Care Walk-In Clinic',
        'type': FacilityType.clinic,
        'hasER': false,
        'rating': 4.4,
        'reviews': 678,
        'waitTime': 8,
      },
      {
        'name': 'St. Mary\'s Emergency Room',
        'type': FacilityType.emergencyRoom,
        'hasER': true,
        'rating': 4.8,
        'reviews': 1567,
        'waitTime': 18,
      },
      {
        'name': 'CVS Pharmacy',
        'type': FacilityType.pharmacy,
        'hasER': false,
        'rating': 4.2,
        'reviews': 345,
        'waitTime': 3,
      },
      {
        'name': 'Riverside Community Hospital',
        'type': FacilityType.hospital,
        'hasER': true,
        'rating': 4.5,
        'reviews': 1890,
        'waitTime': 28,
      },
    ];

    for (int i = 0; i < mockData.length; i++) {
      final data = mockData[i];
      final type = data['type'] as FacilityType;

// Filter by type if specified
      if (filterType != null && type != filterType) continue;

// Generate random location near user (within 0.1 degrees ~ 7 miles)
      final lat = userLat + (random.nextDouble() - 0.5) * 0.1;
      final lng = userLng + (random.nextDouble() - 0.5) * 0.1;
      final distance = _calculateDistance(userLat, userLng, lat, lng);

      hospitals.add(Hospital(
        id: 'mock-$i',
        name: data['name'] as String,
        address: '${123 + i * 10} Medical Drive, City, ST 12345',
        latitude: lat,
        longitude: lng,
        phoneNumber: '(555) ${100 + i * 11}-${1000 + i * 111}',
        type: type,
        specialties: _getSpecialties(type),
        rating: data['rating'] as double,
        reviewCount: data['reviews'] as int,
        estimatedWaitTime: data['waitTime'] as int,
        isOpen24Hours: data['hasER'] as bool,
        operatingHours: (data['hasER'] as bool) ? '24/7' : '8:00 AM - 8:00 PM',
        distance: distance,
        hasEmergencyRoom: data['hasER'] as bool,
        acceptsWalkIns: true,
        website:
        'https://${data['name'].toString().toLowerCase().replaceAll(' ', '')}.com',
      ));
    }

// Sort by distance
    hospitals.sort((a, b) => a.distance.compareTo(b.distance));
    return hospitals;
  }

  List<Specialty> _getSpecialties(FacilityType type) {
    switch (type) {
      case FacilityType.hospital:
        return [
          Specialty.emergency,
          Specialty.cardiology,
          Specialty.pediatrics,
          Specialty.orthopedics,
        ];
      case FacilityType.urgentCare:
        return [Specialty.urgentCare, Specialty.generalPractice];
      case FacilityType.pharmacy:
        return [Specialty.pharmacy];
      case FacilityType.clinic:
        return [Specialty.generalPractice];
      case FacilityType.emergencyRoom:
        return [Specialty.emergency];
    }
  }

// EXISTING: Get recommendations based on symptoms
  List<Hospital> getRecommendations(
      List<Hospital> hospitals,
      String symptoms,
      ) {
    final lowerSymptoms = symptoms.toLowerCase();

// Emergency symptoms -> recommend ER
    if (lowerSymptoms.contains('chest pain') ||
        lowerSymptoms.contains('heart') ||
        lowerSymptoms.contains('severe') ||
        lowerSymptoms.contains('breathing') ||
        lowerSymptoms.contains('stroke')) {
      return hospitals
          .where((h) =>
      h.hasEmergencyRoom || h.type == FacilityType.emergencyRoom)
          .toList();
    }

// Minor symptoms -> recommend urgent care/clinic
    if (lowerSymptoms.contains('cold') ||
        lowerSymptoms.contains('flu') ||
        lowerSymptoms.contains('cough') ||
        lowerSymptoms.contains('fever')) {
      return hospitals
          .where((h) =>
      h.type == FacilityType.urgentCare ||
          h.type == FacilityType.clinic)
          .toList();
    }

// Medication -> recommend pharmacy
    if (lowerSymptoms.contains('prescription') ||
        lowerSymptoms.contains('medication') ||
        lowerSymptoms.contains('pharmacy')) {
      return hospitals.where((h) => h.type == FacilityType.pharmacy).toList();
    }

    return hospitals;
  }

// ========================================
// NEW FEATURES: REVIEWS & RATINGS SYSTEM
// ========================================

  /// Add hospital review
  Future<void> addReview(HospitalReview review) async {
    try {
      _reviews.add(review);
      await _saveReviews();
      print('✅ Review added for hospital ${review.hospitalId}');
    } catch (e) {
      print('❌ Add review error: $e');
      rethrow;
    }
  }

  /// Get reviews for hospital
  Future<List<HospitalReview>> getReviewsForHospital(String hospitalId) async {
    try {
      await _loadReviews();
      return _reviews.where((r) => r.hospitalId == hospitalId).toList();
    } catch (e) {
      print('❌ Get reviews error: $e');
      return [];
    }
  }

  /// Load reviews from storage
  Future<void> _loadReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewsJson = prefs.getStringList(_reviewsKey) ?? [];

      _reviews = reviewsJson.map((jsonStr) {
        try {
          final Map<String, dynamic> data = json.decode(jsonStr);
          return HospitalReview.fromJson(data);
        } catch (e) {
          print('❌ Error parsing review: $e');
          return null;
        }
      }).whereType<HospitalReview>().toList();
    } catch (e) {
      print('❌ Load reviews error: $e');
    }
  }

  /// Save reviews to storage
  Future<void> _saveReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewsJson =
      _reviews.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_reviewsKey, reviewsJson);
    } catch (e) {
      print('❌ Save reviews error: $e');
    }
  }

  /// Get average rating for hospital
  Future<double> getAverageRating(String hospitalId) async {
    try {
      final reviews = await getReviewsForHospital(hospitalId);
      if (reviews.isEmpty) return 0.0;

      final avgRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      return double.parse(avgRating.toStringAsFixed(1));
    } catch (e) {
      return 0.0;
    }
  }

// ========================================
// NEW FEATURES: FAVORITES SYSTEM
// ========================================

  /// Add hospital to favorites
  Future<void> addToFavorites(String hospitalId) async {
    try {
      if (!_favoriteHospitalIds.contains(hospitalId)) {
        _favoriteHospitalIds.add(hospitalId);
        await _saveFavorites();
        print('✅ Hospital added to favorites');
      }
    } catch (e) {
      print('❌ Add to favorites error: $e');
    }
  }

  /// Remove hospital from favorites
  Future<void> removeFromFavorites(String hospitalId) async {
    try {
      _favoriteHospitalIds.remove(hospitalId);
      await _saveFavorites();
      print('✅ Hospital removed from favorites');
    } catch (e) {
      print('❌ Remove from favorites error: $e');
    }
  }

  /// Check if hospital is favorite
  Future<bool> isFavorite(String hospitalId) async {
    await _loadFavorites();
    return _favoriteHospitalIds.contains(hospitalId);
  }

  /// Get all favorite hospital IDs
  Future<List<String>> getFavoriteIds() async {
    await _loadFavorites();
    return _favoriteHospitalIds;
  }

  /// Load favorites from storage
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favoriteHospitalIds = prefs.getStringList(_favoritesKey) ?? [];
    } catch (e) {
      print('❌ Load favorites error: $e');
    }
  }

  /// Save favorites to storage
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteHospitalIds);
    } catch (e) {
      print('❌ Save favorites error: $e');
    }
  }

// ========================================
// NEW FEATURES: ENHANCED FILTERING
// ========================================

  /// Get top-rated hospitals
  List<Hospital> getTopRatedHospitals(List<Hospital> hospitals, {int limit = 5}) {
    final sorted = List<Hospital>.from(hospitals);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(limit).toList();
  }

  /// Get hospitals with shortest wait times
  List<Hospital> getHospitalsByWaitTime(List<Hospital> hospitals, {int limit = 5}) {
    final sorted = List<Hospital>.from(hospitals);
    sorted.sort((a, b) => (a.estimatedWaitTime ?? 999).compareTo(b.estimatedWaitTime ?? 999));
    return sorted.take(limit).toList();
  }

  /// Get hospitals with ER
  List<Hospital> getHospitalsWithER(List<Hospital> hospitals) {
    return hospitals.where((h) => h.hasEmergencyRoom).toList();
  }

  /// Get 24-hour hospitals
  List<Hospital> get24HourHospitals(List<Hospital> hospitals) {
    return hospitals.where((h) => h.isOpen24Hours).toList();
  }

  /// Get hospitals sorted by distance
  List<Hospital> getHospitalsSortedByDistance(
      List<Hospital> hospitals,
      Position position,
      ) {
    final hospitalsWithDistance = hospitals.map((hospital) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        hospital.latitude,
        hospital.longitude,
      );
      return {
        'hospital': hospital,
        'distance': distance,
      };
    }).toList();

    hospitalsWithDistance.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));

    return hospitalsWithDistance
        .map((item) => item['hospital'] as Hospital)
        .toList();
  }

// ========================================
// NEW FEATURES: STATISTICS
// ========================================

  /// Get statistics
  Map<String, dynamic> getStatistics(List<Hospital> hospitals) {
    if (hospitals.isEmpty) {
      return {
        'totalHospitals': 0,
        'withER': 0,
        'open24Hours': 0,
        'totalReviews': 0,
        'averageRating': 0.0,
      };
    }

    return {
      'totalHospitals': hospitals.length,
      'withER': hospitals.where((h) => h.hasEmergencyRoom).length,
      'open24Hours': hospitals.where((h) => h.isOpen24Hours).length,
      'totalReviews': _reviews.length,
      'averageRating':
      hospitals.map((h) => h.rating).reduce((a, b) => a + b) /
          hospitals.length,
    };
  }

  /// Format distance for display
  String formatDistance(double distanceInMiles) {
    if (distanceInMiles < 1) {
      return '${(distanceInMiles * 5280).toInt()} ft';
    } else {
      return '${distanceInMiles.toStringAsFixed(1)} mi';
    }
  }
}