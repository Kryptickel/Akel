import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

enum EmergencyServiceType {
  police,
  ambulance,
  fire,
  rescue,
  general,
}

class EmergencyService {
  final String id;
  final String name;
  final String number;
  final EmergencyServiceType type;
  final String? description;
  final bool isAvailable;

  EmergencyService({
    required this.id,
    required this.name,
    required this.number,
    required this.type,
    this.description,
    this.isAvailable = true,
  });

  factory EmergencyService.fromMap(Map<String, dynamic> map, String id) {
    return EmergencyService(
      id: id,
      name: map['name'] ?? '',
      number: map['number'] ?? '',
      type: _typeFromString(map['type'] ?? 'general'),
      description: map['description'],
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
      'type': _typeToString(type),
      'description': description,
      'isAvailable': isAvailable,
    };
  }

  static EmergencyServiceType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return EmergencyServiceType.police;
      case 'ambulance':
        return EmergencyServiceType.ambulance;
      case 'fire':
        return EmergencyServiceType.fire;
      case 'rescue':
        return EmergencyServiceType.rescue;
      default:
        return EmergencyServiceType.general;
    }
  }

  static String _typeToString(EmergencyServiceType type) {
    switch (type) {
      case EmergencyServiceType.police:
        return 'police';
      case EmergencyServiceType.ambulance:
        return 'ambulance';
      case EmergencyServiceType.fire:
        return 'fire';
      case EmergencyServiceType.rescue:
        return 'rescue';
      case EmergencyServiceType.general:
        return 'general';
    }
  }
}

class EmergencyCall {
  final String id;
  final String userId;
  final EmergencyServiceType serviceType;
  final String serviceNumber;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? location;
  final bool locationShared;

  EmergencyCall({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.serviceNumber,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.location,
    this.locationShared = false,
  });

  factory EmergencyCall.fromMap(Map<String, dynamic> map, String id) {
    return EmergencyCall(
      id: id,
      userId: map['userId'] ?? '',
      serviceType: EmergencyService._typeFromString(map['serviceType'] ?? 'general'),
      serviceNumber: map['serviceNumber'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: map['latitude'],
      longitude: map['longitude'],
      location: map['location'],
      locationShared: map['locationShared'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceType': EmergencyService._typeToString(serviceType),
      'serviceNumber': serviceNumber,
      'timestamp': FieldValue.serverTimestamp(),
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'locationShared': locationShared,
    };
  }
}

class EmergencyServicesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default emergency services (US)
  static final List<EmergencyService> defaultServices = [
    EmergencyService(
      id: 'us_911',
      name: '911 - Emergency Services',
      number: '911',
      type: EmergencyServiceType.general,
      description: 'General emergency number (Police, Fire, Medical)',
    ),
    EmergencyService(
      id: 'us_police',
      name: 'Police Department',
      number: '911',
      type: EmergencyServiceType.police,
      description: 'Law enforcement emergency',
    ),
    EmergencyService(
      id: 'us_ambulance',
      name: 'Ambulance / Medical Emergency',
      number: '911',
      type: EmergencyServiceType.ambulance,
      description: 'Medical emergency services',
    ),
    EmergencyService(
      id: 'us_fire',
      name: 'Fire Department',
      number: '911',
      type: EmergencyServiceType.fire,
      description: 'Fire and rescue services',
    ),
  ];

  // Get emergency services for user's region
  Future<List<EmergencyService>> getEmergencyServices(String? countryCode) async {
    // For now, return default US services
    // In production, this would query based on countryCode
    return defaultServices;
  }

  // Call emergency service
  Future<bool> callEmergencyService({
    required String userId,
    required EmergencyService service,
    bool shareLocation = true,
  }) async {
    try {
      Position? position;
      String? locationText;

      // Get current location if sharing is enabled
      if (shareLocation) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          locationText = 'Lat: ${position.latitude.toStringAsFixed(6)}, '
              'Lng: ${position.longitude.toStringAsFixed(6)}';

          debugPrint(' Location: $locationText');
        } catch (e) {
          debugPrint(' Get location error: $e');
        }
      }

      // Make the call
      final phoneUri = Uri.parse('tel:${service.number}');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);

        // Log the call
        await _logEmergencyCall(
          userId: userId,
          service: service,
          position: position,
          locationText: locationText,
          locationShared: shareLocation && position != null,
        );

        debugPrint(' Calling ${service.name} at ${service.number}');
        return true;
      } else {
        debugPrint(' Cannot make call to ${service.number}');
        return false;
      }
    } catch (e) {
      debugPrint(' Call emergency service error: $e');
      return false;
    }
  }

  // Log emergency call
  Future<void> _logEmergencyCall({
    required String userId,
    required EmergencyService service,
    Position? position,
    String? locationText,
    bool locationShared = false,
  }) async {
    try {
      final call = EmergencyCall(
        id: '',
        userId: userId,
        serviceType: service.type,
        serviceNumber: service.number,
        timestamp: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
        location: locationText,
        locationShared: locationShared,
      );

      await _firestore.collection('emergency_calls').add(call.toMap());

      debugPrint(' Emergency call logged');
    } catch (e) {
      debugPrint(' Log emergency call error: $e');
    }
  }

  // Get emergency call history
  Future<List<EmergencyCall>> getEmergencyCallHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('emergency_calls')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return EmergencyCall.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get emergency call history error: $e');
      return [];
    }
  }

  // Get call statistics
  Future<Map<String, dynamic>> getCallStatistics(String userId) async {
    try {
      final calls = await getEmergencyCallHistory(userId);

      final totalCalls = calls.length;
      final policeCalls = calls.where((c) => c.serviceType == EmergencyServiceType.police).length;
      final ambulanceCalls = calls.where((c) => c.serviceType == EmergencyServiceType.ambulance).length;
      final fireCalls = calls.where((c) => c.serviceType == EmergencyServiceType.fire).length;
      final locationShared = calls.where((c) => c.locationShared).length;

      final lastCall = calls.isNotEmpty ? calls.first.timestamp : null;

      return {
        'totalCalls': totalCalls,
        'policeCalls': policeCalls,
        'ambulanceCalls': ambulanceCalls,
        'fireCalls': fireCalls,
        'locationShared': locationShared,
        'lastCall': lastCall,
      };
    } catch (e) {
      debugPrint(' Get call statistics error: $e');
      return {};
    }
  }

  // Get service type icon
  static String getServiceTypeIcon(EmergencyServiceType type) {
    switch (type) {
      case EmergencyServiceType.police:
        return ' ';
      case EmergencyServiceType.ambulance:
        return ' ';
      case EmergencyServiceType.fire:
        return ' ';
      case EmergencyServiceType.rescue:
        return ' ';
      case EmergencyServiceType.general:
        return ' ';
    }
  }

  // Get service type label
  static String getServiceTypeLabel(EmergencyServiceType type) {
    switch (type) {
      case EmergencyServiceType.police:
        return 'Police';
      case EmergencyServiceType.ambulance:
        return 'Ambulance';
      case EmergencyServiceType.fire:
        return 'Fire Department';
      case EmergencyServiceType.rescue:
        return 'Rescue';
      case EmergencyServiceType.general:
        return 'Emergency Services';
    }
  }

  // Get service type color
  static String getServiceTypeColor(EmergencyServiceType type) {
    switch (type) {
      case EmergencyServiceType.police:
        return '#2196F3'; // Blue
      case EmergencyServiceType.ambulance:
        return '#F44336'; // Red
      case EmergencyServiceType.fire:
        return '#FF5722'; // Deep Orange
      case EmergencyServiceType.rescue:
        return '#FF9800'; // Orange
      case EmergencyServiceType.general:
        return '#9C27B0'; // Purple
    }
  }

  // International emergency numbers
  static Map<String, String> getInternationalEmergencyNumbers() {
    return {
      'US': '911',
      'UK': '999',
      'EU': '112',
      'AU': '000',
      'IN': '112',
      'CA': '911',
      'JP': '110',
      'CN': '110',
      'BR': '190',
      'MX': '911',
      'ZA': '10111',
      'KR': '112',
      'SG': '999',
      'NZ': '111',
      'PH': '911',
    };
  }
}