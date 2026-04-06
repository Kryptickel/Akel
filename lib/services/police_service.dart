import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class PoliceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Singleton pattern
  static final PoliceService _instance = PoliceService._internal();
  factory PoliceService() => _instance;
  PoliceService._internal();

  // Police emergency numbers by country
  static const Map<String, String> policeEmergencyNumbers = {
    'US': '911',
    'UK': '999',
    'EU': '112',
    'AU': '000',
    'CA': '911',
    'IN': '100',
    'JP': '110',
    'CN': '110',
    'BR': '190',
    'MX': '911',
    'ZA': '10111',
    'NZ': '111',
    'SG': '999',
    'AE': '999',
    'RU': '102',
  };

  // Emergency types
  static const List<String> emergencyTypes = [
    'Assault in Progress',
    'Robbery/Theft',
    'Break-In/Burglary',
    'Domestic Violence',
    'Kidnapping',
    'Suspicious Activity',
    'Vehicle Accident',
    'Missing Person',
    'Harassment/Stalking',
    'Public Disturbance',
    'Armed Threat',
    'Active Shooter',
    'Fraud/Scam',
    'Property Damage',
    'Trespassing',
    'Other Emergency',
  ];

  // Priority levels
  static const List<String> priorityLevels = [
    'Critical (Life-threatening)',
    'Urgent (Immediate response needed)',
    'High (Serious crime)',
    'Medium (Non-emergency)',
  ];

  // ==================== MAIN CALL METHOD ====================

  /// Call police emergency number
  /// This is the method used by emergency_command_center_screen.dart
  Future<void> callPolice() async {
    await _callPoliceNumber();
  }

  /// Get police emergency number (alias)
  String getPoliceNumber() {
    return getPoliceEmergencyNumber();
  }

  // ==================== REPORT EMERGENCY ====================

  /// Report police emergency
  Future<Map<String, dynamic>> reportPoliceEmergency({
    required String userId,
    required String userName,
    required String emergencyType,
    required String priority,
    required String description,
    String? location,
    String? suspectDescription,
    String? vehicleDescription,
    String? weaponsInvolved,
    bool? injuriesReported,
    String? photoUrl,
    Map<String, dynamic>? coordinates,
  }) async {
    try {
      debugPrint(' Reporting police emergency...');

      // Get location if not provided
      if (coordinates == null) {
        final position = await _getCurrentLocation();
        if (position != null) {
          coordinates = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
          };
        }
      }

      final reportId = _uuid.v4();

      // Create police report
      final policeReport = {
        'id': reportId,
        'userId': userId,
        'userName': userName,
        'emergencyType': emergencyType,
        'priority': priority,
        'description': description,
        'location': location,
        'suspectDescription': suspectDescription,
        'vehicleDescription': vehicleDescription,
        'weaponsInvolved': weaponsInvolved,
        'injuriesReported': injuriesReported ?? false,
        'photoUrl': photoUrl,
        'coordinates': coordinates,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'reported',
        'dispatchTime': null,
        'responseTime': getEstimatedResponseTime(priority),
        'policeNumber': getPoliceEmergencyNumber(),
      };

      // Save to Firestore
      await _firestore
          .collection('police_emergencies')
          .doc(reportId)
          .set(policeReport);

      debugPrint(' Police report created: $reportId');

      // Simulate dispatch
      await Future.delayed(const Duration(seconds: 2));
      await _updateStatus(reportId, 'dispatched');

      // Log to user history
      await _logPoliceEmergency(userId, reportId, policeReport);

      // Get police emergency number
      final policeNumber = getPoliceEmergencyNumber();

      return {
        'success': true,
        'reportId': reportId,
        'policeNumber': policeNumber,
        'location': coordinates,
        'responseTime': policeReport['responseTime'],
        'estimatedArrival': policeReport['responseTime'],
        'message': 'Police have been notified',
      };
    } catch (e) {
      debugPrint(' Report police emergency error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== CALL POLICE ====================

  /// Internal call police method
  Future<bool> _callPoliceNumber() async {
    try {
      final policeNumber = getPoliceEmergencyNumber();
      final uri = Uri.parse('tel:$policeNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint(' Calling police: $policeNumber');
        return true;
      } else {
        debugPrint(' Cannot launch phone dialer');
        return false;
      }
    } catch (e) {
      debugPrint(' Call police error: $e');
      return false;
    }
  }

  /// Get police emergency number
  String getPoliceEmergencyNumber() {
    // TODO: Detect country from location
    return policeEmergencyNumbers['US'] ?? '911';
  }

  /// Check if police number is available
  Future<bool> isPoliceNumberAvailable() async {
    final uri = Uri.parse('tel:${getPoliceEmergencyNumber()}');
    return await canLaunchUrl(uri);
  }

  // ==================== LOCATION ====================

  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(' Location services disabled');
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
        debugPrint(' Location permission denied forever');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      debugPrint(' Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint(' Get location error: $e');
      return null;
    }
  }

  // ==================== LOGGING ====================

  /// Log police emergency
  Future<void> _logPoliceEmergency(
      String userId,
      String reportId,
      Map<String, dynamic> report,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('police_history')
          .add({
        'reportId': reportId,
        'emergencyType': report['emergencyType'],
        'priority': report['priority'],
        'timestamp': FieldValue.serverTimestamp(),
        'coordinates': report['coordinates'],
        'status': report['status'],
      });

      debugPrint(' Police emergency logged');
    } catch (e) {
      debugPrint(' Log police emergency error: $e');
    }
  }

  /// Update status
  Future<void> _updateStatus(String reportId, String status) async {
    try {
      await _firestore.collection('police_emergencies').doc(reportId).update({
        'status': status,
        'dispatchTime': status == 'dispatched' ? FieldValue.serverTimestamp() : null,
        'arrivedTime': status == 'arrived' ? FieldValue.serverTimestamp() : null,
        'completedTime': status == 'completed' ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(' Police report status updated: $status');
    } catch (e) {
      debugPrint(' Update status error: $e');
    }
  }

  // ==================== HISTORY ====================

  /// Get police history
  Future<List<Map<String, dynamic>>> getPoliceHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('police_history')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint(' Get police history error: $e');
      return [];
    }
  }

  /// Get active police reports
  Future<List<Map<String, dynamic>>> getActiveReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('police_emergencies')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['reported', 'dispatched', 'en_route'])
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint(' Get active reports error: $e');
      return [];
    }
  }

  // ==================== SAFETY TIPS ====================

  /// Get safety tips based on emergency type
  static List<String> getSafetyTips(String emergencyType) {
    final lowercaseType = emergencyType.toLowerCase();

    if (lowercaseType.contains('assault') || lowercaseType.contains('attack')) {
      return [
        ' Get to a safe location immediately',
        ' Call police as soon as it\'s safe',
        ' Stay in a public area if possible',
        ' Lock doors and windows',
        ' Document injuries with photos',
        ' Seek medical attention if injured',
        ' Write down what happened while fresh in memory',
      ];
    } else if (lowercaseType.contains('robbery') || lowercaseType.contains('theft')) {
      return [
        ' Don\'t resist - your safety is most important',
        ' Try to remember suspect\'s description',
        ' Call police immediately after it\'s safe',
        ' Don\'t touch anything the suspect touched',
        ' Write down what was stolen',
        ' Cancel credit cards if stolen',
        ' Change locks if keys were stolen',
      ];
    } else if (lowercaseType.contains('break') || lowercaseType.contains('burgl')) {
      return [
        ' Don\'t enter if you see signs of break-in',
        ' Call police from a safe location',
        ' Don\'t touch anything',
        ' Note if anything is disturbed',
        ' Take photos for insurance',
        ' Stay outside until police clear the area',
        ' Get locks changed immediately',
      ];
    } else if (lowercaseType.contains('domestic')) {
      return [
        ' Leave immediately if you can safely do so',
        ' Call police from a safe location',
        ' Seek medical attention for injuries',
        ' Document all injuries',
        ' Go to a friend, family, or shelter',
        ' Consider protective order',
        ' Contact domestic violence resources',
      ];
    } else if (lowercaseType.contains('kidnap')) {
      return [
        ' Call police IMMEDIATELY',
        ' Note last seen location and time',
        ' Provide detailed description and photo',
        ' Note vehicle information if applicable',
        ' Don\'t touch victim\'s belongings',
        ' Amber Alert may be issued',
        ' Police will coordinate search',
      ];
    } else if (lowercaseType.contains('suspicious')) {
      return [
        ' Observe from a safe distance',
        ' Note descriptions: person, vehicle, activity',
        ' Call police non-emergency line',
        ' Don\'t approach or confront',
        ' Take photos/video if safe to do so',
        ' Stay inside and lock doors',
        ' Alert neighbors if appropriate',
      ];
    } else if (lowercaseType.contains('vehicle') || lowercaseType.contains('accident')) {
      return [
        ' Move to safe location if possible',
        ' Turn on hazard lights',
        ' Call police if injuries or major damage',
        ' Take photos of all vehicles and scene',
        ' Exchange information with other drivers',
        ' Get medical attention if needed',
        ' File police report',
      ];
    } else if (lowercaseType.contains('harassment') || lowercaseType.contains('stalk')) {
      return [
        ' Document all incidents with dates/times',
        ' Save all messages, emails, photos',
        ' Don\'t engage with harasser',
        ' Report to police',
        ' Increase security measures',
        ' Tell trusted people about situation',
        ' Consider restraining order',
      ];
    } else if (lowercaseType.contains('armed') || lowercaseType.contains('weapon') || lowercaseType.contains('shooter')) {
      return [
        ' RUN if you can safely escape',
        ' HIDE if escape isn\'t possible',
        ' FIGHT only as last resort',
        ' Call police when safe',
        ' Silence your phone',
        ' Barricade doors if hiding',
        ' Help others escape if safe',
      ];
    } else {
      return [
        ' Call police immediately',
        ' Get to a safe location',
        ' Note important details',
        ' Seek help from others nearby',
        ' Lock doors if at home',
        ' Get medical help if needed',
        ' Document the situation if safe',
      ];
    }
  }

  /// Get police tips
  static List<String> getPoliceTips() {
    return [
      ' Stay calm and safe',
      ' Share your exact location',
      ' Describe suspects if safe',
      ' Keep phone line open',
      ' Move to safety if possible',
      ' Don\'t confront suspects',
      ' Take photos/videos if safe',
      ' Alert others if appropriate',
    ];
  }

  // ==================== UTILITIES ====================

  /// Get estimated response time
  static String getEstimatedResponseTime(String priority) {
    final lowercasePriority = priority.toLowerCase();

    if (lowercasePriority.contains('critical') || lowercasePriority.contains('life')) {
      return '2-5 minutes';
    } else if (lowercasePriority.contains('urgent')) {
      return '5-10 minutes';
    } else if (lowercasePriority.contains('high')) {
      return '10-20 minutes';
    } else {
      return '20-60 minutes';
    }
  }

  /// Cancel police report
  Future<bool> cancelReport(String reportId) async {
    try {
      await _updateStatus(reportId, 'cancelled');
      debugPrint(' Police report cancelled: $reportId');
      return true;
    } catch (e) {
      debugPrint(' Cancel report error: $e');
      return false;
    }
  }

  /// Get report details
  Future<Map<String, dynamic>?> getReportDetails(String reportId) async {
    try {
      final doc = await _firestore
          .collection('police_emergencies')
          .doc(reportId)
          .get();

      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      debugPrint(' Get report details error: $e');
      return null;
    }
  }
}