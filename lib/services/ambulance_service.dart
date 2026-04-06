import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class AmbulanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

// Singleton pattern
  static final AmbulanceService _instance = AmbulanceService._internal();
  factory AmbulanceService() => _instance;
  AmbulanceService._internal();

// EMS emergency numbers by country
  static const Map<String, String> emsEmergencyNumbers = {
    'US': '911',
    'UK': '999',
    'EU': '112',
    'AU': '000',
    'CA': '911',
    'IN': '102',
    'JP': '119',
    'CN': '120',
    'BR': '192',
    'MX': '911',
    'ZA': '10177',
    'NZ': '111',
    'SG': '995',
    'AE': '998',
  };

// Medical emergency types
  static const List<String> emergencyTypes = [
    'Heart Attack/Chest Pain',
    'Stroke',
    'Difficulty Breathing',
    'Severe Bleeding',
    'Unconscious Person',
    'Severe Allergic Reaction',
    'Seizure',
    'Severe Burns',
    'Broken Bones/Fractures',
    'Poisoning/Overdose',
    'Severe Pain',
    'Pregnancy/Childbirth',
    'Diabetic Emergency',
    'Head Injury',
    'Cardiac Arrest',
    'Other Medical Emergency',
  ];

// Severity levels
  static const List<String> severityLevels = [
    'Critical (Life-threatening)',
    'Severe (Serious injury/illness)',
    'Moderate (Needs medical attention)',
    'Minor (Non-emergency)',
  ];

// ==================== MAIN CALL METHOD (NEW!) ====================

  /// Call ambulance emergency number
  /// This is the method used by emergency_command_center_screen.dart
  Future<void> callAmbulance() async {
    await callEMS();
  }

  /// Get ambulance emergency number (alias for getEMSNumber)
  String getAmbulanceNumber() {
    return getEMSNumber();
  }

// ==================== REQUEST AMBULANCE ====================

  /// Request ambulance
  Future<Map<String, dynamic>> requestAmbulance({
    required String userId,
    required String userName,
    required String emergencyType,
    required String severity,
    required String description,
    String? patientAge,
    String? patientGender,
    bool? isConscious,
    bool? isBreathing,
    String? medications,
    String? allergies,
    String? medicalConditions,
    String? location,
    String? photoUrl,
    Map<String, dynamic>? coordinates,
  }) async {
    try {
      debugPrint('🚑 Requesting ambulance...');

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

      final requestId = _uuid.v4();

// Create ambulance request
      final ambulanceRequest = {
        'id': requestId,
        'userId': userId,
        'userName': userName,
        'emergencyType': emergencyType,
        'severity': severity,
        'description': description,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'isConscious': isConscious,
        'isBreathing': isBreathing,
        'medications': medications,
        'allergies': allergies,
        'medicalConditions': medicalConditions,
        'location': location,
        'photoUrl': photoUrl,
        'coordinates': coordinates,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'requested',
        'dispatchTime': null,
        'eta': getEstimatedArrivalTime(severity),
        'emsNumber': getEMSNumber(),
      };

// Save to Firestore
      await _firestore
          .collection('ambulance_requests')
          .doc(requestId)
          .set(ambulanceRequest);

      debugPrint('✅ Ambulance request created: $requestId');

// Simulate dispatch
      await Future.delayed(const Duration(seconds: 2));
      await _updateStatus(requestId, 'dispatched');

// Log to user history
      await _logAmbulanceRequest(userId, requestId, ambulanceRequest);

// Get EMS number
      final emsNumber = getEMSNumber();

      return {
        'success': true,
        'requestId': requestId,
        'emsNumber': emsNumber,
        'location': coordinates,
        'eta': ambulanceRequest['eta'],
        'message': 'Ambulance dispatched',
        'estimatedArrival': ambulanceRequest['eta'],
      };
    } catch (e) {
      debugPrint('❌ Request ambulance error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

// ==================== CALL EMS ====================

  /// Call EMS
  Future<bool> callEMS() async {
    try {
      final emsNumber = getEMSNumber();
      final uri = Uri.parse('tel:$emsNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('📞 Calling EMS: $emsNumber');
        return true;
      } else {
        debugPrint('❌ Cannot launch phone dialer');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Call EMS error: $e');
      return false;
    }
  }

  /// Get EMS emergency number
  String getEMSNumber() {
// TODO: Detect country from location
    return emsEmergencyNumbers['US'] ?? '911';
  }

  /// Check if EMS number is available
  Future<bool> isEMSAvailable() async {
    final uri = Uri.parse('tel:${getEMSNumber()}');
    return await canLaunchUrl(uri);
  }

// ==================== LOCATION ====================

  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      debugPrint('📍 Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Get location error: $e');
      return null;
    }
  }

// ==================== LOGGING ====================

  /// Log ambulance request
  Future<void> _logAmbulanceRequest(
      String userId,
      String requestId,
      Map<String, dynamic> request,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ambulance_history')
          .add({
        'requestId': requestId,
        'emergencyType': request['emergencyType'],
        'severity': request['severity'],
        'timestamp': FieldValue.serverTimestamp(),
        'coordinates': request['coordinates'],
        'eta': request['eta'],
        'status': request['status'],
      });

      debugPrint('✅ Ambulance request logged');
    } catch (e) {
      debugPrint('❌ Log ambulance request error: $e');
    }
  }

  /// Update status
  Future<void> _updateStatus(String requestId, String status) async {
    try {
      await _firestore.collection('ambulance_requests').doc(requestId).update({
        'status': status,
        'dispatchTime': status == 'dispatched' ? FieldValue.serverTimestamp() : null,
        'arrivedTime': status == 'arrived' ? FieldValue.serverTimestamp() : null,
        'completedTime': status == 'completed' ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Ambulance status updated: $status');
    } catch (e) {
      debugPrint('❌ Update status error: $e');
    }
  }

// ==================== HISTORY ====================

  /// Get ambulance history
  Future<List<Map<String, dynamic>>> getAmbulanceHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ambulance_history')
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
      debugPrint('❌ Get ambulance history error: $e');
      return [];
    }
  }

  /// Get active ambulance requests
  Future<List<Map<String, dynamic>>> getActiveRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ambulance_requests')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['requested', 'dispatched', 'en_route'])
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
      debugPrint('❌ Get active requests error: $e');
      return [];
    }
  }

// ==================== FIRST AID ====================

  /// Get first aid instructions
  static List<String> getFirstAidInstructions(String emergencyType) {
    final lowercaseType = emergencyType.toLowerCase();

    if (lowercaseType.contains('heart') || lowercaseType.contains('chest')) {
      return [
        '📞 Call 911 IMMEDIATELY',
        '💊 Give aspirin if available (chew, don\'t swallow)',
        '🪑 Have person sit down and rest',
        '👔 Loosen tight clothing',
        '❌ Don\'t leave person alone',
        '🫀 Be ready to perform CPR if needed',
        '⏱️ Note time symptoms started',
      ];
    } else if (lowercaseType.contains('stroke')) {
      return [
        '📞 Call 911 IMMEDIATELY - time is critical',
        '🪑 Have person lie down with head elevated',
        '⏱️ Note exact time symptoms started',
        '🍽️ Don\'t give food or drink',
        '👀 Monitor breathing and consciousness',
        '🚫 Don\'t give aspirin (unlike heart attack)',
        '✋ FAST test: Face drooping, Arm weakness, Speech difficulty, Time to call',
      ];
    } else if (lowercaseType.contains('breathing') || lowercaseType.contains('chok')) {
      return [
        '📞 Call 911 immediately',
        '🪑 Help person sit upright',
        '👔 Loosen tight clothing',
        '💨 Encourage slow, deep breaths',
        '💊 Use inhaler if person has one',
        '🚫 Don\'t lay person flat',
        '🫁 If choking, perform Heimlich maneuver',
      ];
    } else if (lowercaseType.contains('bleeding')) {
      return [
        '📞 Call 911 if severe bleeding',
        '🧤 Wear gloves if available',
        '👐 Apply direct pressure with clean cloth',
        '⬆️ Elevate injured area above heart',
        '🩹 Don\'t remove cloth if soaked - add more',
        '🚫 Don\'t apply tourniquet unless trained',
        '📊 Monitor for shock symptoms',
      ];
    } else if (lowercaseType.contains('unconscious')) {
      return [
        '📞 Call 911 IMMEDIATELY',
        '✅ Check if breathing',
        '🫀 Start CPR if not breathing',
        '🛏️ Place in recovery position if breathing',
        '🚫 Don\'t move if spinal injury suspected',
        '🍽️ Don\'t give anything by mouth',
        '👀 Monitor breathing until help arrives',
      ];
    } else if (lowercaseType.contains('allergic') || lowercaseType.contains('anaph')) {
      return [
        '📞 Call 911 IMMEDIATELY',
        '💉 Use EpiPen if available (inject into thigh)',
        '🪑 Have person lie down with legs elevated',
        '👔 Loosen tight clothing',
        '🚫 Don\'t give anything by mouth',
        '💊 Antihistamine can help but not enough alone',
        '👀 Monitor breathing - be ready for CPR',
      ];
    } else if (lowercaseType.contains('seizure')) {
      return [
        '📞 Call 911 if first seizure or lasts >5 minutes',
        '⏱️ Time the seizure',
        '🛏️ Move objects away - protect head',
        '🚫 Don\'t restrain or hold person down',
        '🚫 Don\'t put anything in mouth',
        '🔄 Turn on side after seizure stops',
        '🕐 Stay with person until fully conscious',
      ];
    } else if (lowercaseType.contains('burn')) {
      return [
        '📞 Call 911 for severe burns',
        '❄️ Cool with cool (not cold) running water',
        '⏱️ Cool for at least 10 minutes',
        '🧴 Cover with sterile, non-stick dressing',
        '🚫 Don\'t use ice or butter',
        '🚫 Don\'t break blisters',
        '💊 Give pain reliever if conscious',
      ];
    } else if (lowercaseType.contains('broken') || lowercaseType.contains('fracture')) {
      return [
        '📞 Call 911 for severe fractures',
        '🚫 Don\'t move injured area',
        '❄️ Apply ice pack (wrapped in cloth)',
        '📏 Immobilize with splint if trained',
        '⬆️ Elevate if possible',
        '💊 Give pain reliever if conscious',
        '👀 Watch for shock symptoms',
      ];
    } else if (lowercaseType.contains('poison') || lowercaseType.contains('overdose')) {
      return [
        '📞 Call 911 AND Poison Control (1-800-222-1222)',
        '📦 Bring medication/substance container',
        '🚫 Don\'t induce vomiting unless told',
        '🪑 Keep person sitting or lying on side',
        '👀 Monitor breathing and consciousness',
        '🫀 Be ready to perform CPR',
        '⏱️ Note time of ingestion',
      ];
    } else if (lowercaseType.contains('pregnancy') || lowercaseType.contains('birth')) {
      return [
        '📞 Call 911 immediately',
        '🛏️ Have mother lie on left side',
        '⏱️ Time contractions',
        '🚫 Don\'t try to delay delivery',
        '🧼 Prepare clean towels and blankets',
        '👶 Support baby\'s head during delivery',
        '🔗 Don\'t cut umbilical cord',
      ];
    } else if (lowercaseType.contains('diabetic')) {
      return [
        '📞 Call 911 if unconscious or seizure',
        '🍬 Give sugar if conscious and low blood sugar',
        '💉 Use glucagon kit if available and trained',
        '🚫 Don\'t give insulin without guidance',
        '👀 Monitor consciousness level',
        '🪑 Have person sit or lie down',
        '⏱️ Note time of onset',
      ];
    } else {
      return [
        '📞 Call 911 for medical emergency',
        '🪑 Keep person calm and still',
        '👀 Monitor vital signs',
        '🚫 Don\'t move if injury suspected',
        '🍽️ Don\'t give food or drink',
        '🫀 Be ready to perform CPR',
        '📋 Provide information to paramedics',
      ];
    }
  }

  /// Get ambulance safety tips
  static List<String> getAmbulanceTips() {
    return [
      '🫀 Stay calm and speak clearly',
      '📍 Provide exact location',
      '🩺 Describe symptoms accurately',
      '💊 List medications if known',
      '⏰ Note when symptoms started',
      '👤 Stay with the patient',
      '🚪 Unlock doors for paramedics',
      '🐕 Secure pets if possible',
    ];
  }

// ==================== UTILITIES ====================

  /// Get estimated arrival time
  static String getEstimatedArrivalTime(String severity) {
    final lowercaseSeverity = severity.toLowerCase();

    if (lowercaseSeverity.contains('critical') || lowercaseSeverity.contains('life')) {
      return '4-8 minutes';
    } else if (lowercaseSeverity.contains('severe')) {
      return '8-15 minutes';
    } else if (lowercaseSeverity.contains('moderate')) {
      return '15-30 minutes';
    } else {
      return '30-60 minutes';
    }
  }

  /// Cancel ambulance request
  Future<bool> cancelRequest(String requestId) async {
    try {
      await _updateStatus(requestId, 'cancelled');
      debugPrint('✅ Ambulance request cancelled: $requestId');
      return true;
    } catch (e) {
      debugPrint('❌ Cancel request error: $e');
      return false;
    }
  }
}