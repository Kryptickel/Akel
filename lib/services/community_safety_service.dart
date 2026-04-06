import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// ==================== ENHANCED COMMUNITY SAFETY SERVICE ====================
///
/// LIVE COMMUNITY EMERGENCY NETWORK - PHASE 3 ENHANCED
/// Your existing service + new Phase 3 features:
/// - Your existing: Alerts, Safe Zones, Helpers
/// - Witness Mode (safe documentation)
/// - First Responder Capabilities (CPR, First Aid, etc.)
/// - Response Types (Can Help, On My Way, Arrived)
/// - Privacy Controls (Anonymous Mode)
/// - Opt-in/Opt-out System
/// - Customizable Alert Radius
/// - Enhanced Statistics
/// - Nearby Responders Network
///
/// ================================================================

class CommunitySafetyService {
  static final CommunitySafetyService _instance = CommunitySafetyService._internal();
  factory CommunitySafetyService() => _instance;
  CommunitySafetyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _alertsSubscription;

  bool _isOptedIn = false;
  bool _isAnonymous = false;
  double _alertRadius = 2000.0;
  Set<ResponderCapability> _userCapabilities = {};

  Function(Map<String, dynamic>)? onAlertReceived;
  Function(String)? onLog;

  // ==================== ALERT TYPES ====================

  static const List<String> alertTypes = [
    'Emergency',
    'Suspicious Activity',
    'Medical Emergency',
    'Fire',
    'Accident',
    'Crime',
    'Natural Disaster',
    'Lost Person',
    'Other',
  ];

  static const List<String> severityLevels = [
    'Critical',
    'High',
    'Medium',
    'Low',
  ];

  static const List<String> responseTypes = [
    'I can help',
    'I\'m witnessing',
    'On my way',
    'I\'ve arrived',
  ];

  // ==================== INITIALIZATION ====================

  Future<bool> initialize() async {
    try {
      debugPrint('Initializing Enhanced Community Safety Service...');
      await _loadSettings();
      debugPrint('Community Safety Service initialized');
      return true;
    } catch (e) {
      debugPrint('Community Safety initialization error: ' + e.toString());
      return false;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _isOptedIn = prefs.getBool('community_opted_in') ?? false;
    _isAnonymous = prefs.getBool('community_anonymous') ?? false;
    _alertRadius = prefs.getDouble('community_radius') ?? 2000.0;

    final capabilitiesJson = prefs.getStringList('community_capabilities') ?? [];
    _userCapabilities = capabilitiesJson
        .map((e) => ResponderCapability.values.firstWhere(
          (c) => c.name == e,
      orElse: () => ResponderCapability.none,
    ))
        .where((c) => c != ResponderCapability.none)
        .toSet();

    debugPrint('Settings loaded (Opted in: ' + _isOptedIn.toString() + ', Radius: ' + _alertRadius.toString() + 'm)');
  }

  // ==================== BROADCAST ALERT ====================

  Future<String?> broadcastAlert({
    required String userId,
    required String userName,
    required String alertType,
    required String severity,
    required String description,
    required Position position,
    String? address,
    bool shareLiveVideo = false,
    bool notifyAuthorities = false,
  }) async {
    try {
      final displayName = _isAnonymous ? 'Anonymous User' : userName;

      final alertDoc = await _firestore.collection('community_alerts').add({
        'userId': userId,
        'userName': displayName,
        'alertType': alertType,
        'severity': severity,
        'description': description,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
        'address': address,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'helpersCount': 0,
        'witnessCount': 0,
        'viewsCount': 0,
        'isResolved': false,
        'shareLiveVideo': shareLiveVideo,
        'notifyAuthorities': notifyAuthorities,
        'isAnonymous': _isAnonymous,
      });

      debugPrint('Community alert broadcast: ' + alertDoc.id);
      onLog?.call('Community alert broadcasted');

      return alertDoc.id;
    } catch (e) {
      debugPrint('Broadcast alert error: ' + e.toString());
      return null;
    }
  }

  // ==================== GET NEARBY ALERTS ====================

  Future<List<Map<String, dynamic>>> getNearbyAlerts({
    required Position currentPosition,
    double? radiusKm,
  }) async {
    try {
      final radius = radiusKm ?? (_alertRadius / 1000);

      final snapshot = await _firestore
          .collection('community_alerts')
          .where('status', isEqualTo: 'active')
          .where('isResolved', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final alerts = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'];

        if (location != null) {
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            location['latitude'],
            location['longitude'],
          );

          if (distance / 1000 <= radius) {
            alerts.add({
              'id': doc.id,
              'distance': distance,
              ...data,
            });
          }
        }
      }

      alerts.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      debugPrint('Found ' + alerts.length.toString() + ' nearby alerts');
      return alerts;
    } catch (e) {
      debugPrint('Get nearby alerts error: ' + e.toString());
      return [];
    }
  }

  // ==================== SUBSCRIBE TO ALERTS ====================

  Stream<List<Map<String, dynamic>>> subscribeToNearbyAlerts({
    required Position currentPosition,
    double? radiusKm,
  }) {
    final radius = radiusKm ?? (_alertRadius / 1000);

    return _firestore
        .collection('community_alerts')
        .where('status', isEqualTo: 'active')
        .where('isResolved', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      final alerts = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'];

        if (location != null) {
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            location['latitude'],
            location['longitude'],
          );

          if (distance / 1000 <= radius) {
            final alert = {
              'id': doc.id,
              'distance': distance,
              ...data,
            };
            alerts.add(alert);
            onAlertReceived?.call(alert);
          }
        }
      }

      alerts.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      return alerts;
    });
  }

  // ==================== OFFER HELP ====================

  Future<void> offerHelp({
    required String alertId,
    required String userId,
    required String userName,
    String? message,
    String responseType = 'I can help',
  }) async {
    try {
      final displayName = _isAnonymous ? 'Anonymous Helper' : userName;

      await _firestore
          .collection('community_alerts')
          .doc(alertId)
          .collection('helpers')
          .doc(userId)
          .set({
        'userId': userId,
        'userName': displayName,
        'message': message,
        'responseType': responseType,
        'capabilities': _userCapabilities.map((e) => e.name).toList(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'offered',
      });

      await _firestore.collection('community_alerts').doc(alertId).update({
        'helpersCount': FieldValue.increment(1),
      });

      debugPrint('Help offered on alert: ' + alertId);
      onLog?.call('Response sent to alert');
    } catch (e) {
      debugPrint('Offer help error: ' + e.toString());
      rethrow;
    }
  }

  // ==================== WITNESS MODE ====================

  Future<void> markAsWitness({
    required String alertId,
    required String userId,
    required String userName,
    String? notes,
    Position? location,
  }) async {
    try {
      final displayName = _isAnonymous ? 'Anonymous Witness' : userName;

      await _firestore
          .collection('community_alerts')
          .doc(alertId)
          .collection('witnesses')
          .doc(userId)
          .set({
        'userId': userId,
        'userName': displayName,
        'notes': notes,
        'location': location != null
            ? {
          'latitude': location.latitude,
          'longitude': location.longitude,
        }
            : null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('community_alerts').doc(alertId).update({
        'witnessCount': FieldValue.increment(1),
      });

      debugPrint('Marked as witness for alert: ' + alertId);
      onLog?.call('Marked as witness');
    } catch (e) {
      debugPrint('Mark as witness error: ' + e.toString());
      rethrow;
    }
  }

  // ==================== GET WITNESSES ====================

  Future<List<Map<String, dynamic>>> getWitnesses(String alertId) async {
    try {
      final snapshot = await _firestore
          .collection('community_alerts')
          .doc(alertId)
          .collection('witnesses')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      debugPrint('Get witnesses error: ' + e.toString());
      return [];
    }
  }

  // ==================== RESOLVE ALERT ====================

  Future<void> resolveAlert(String alertId) async {
    try {
      await _firestore.collection('community_alerts').doc(alertId).update({
        'isResolved': true,
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Alert resolved: ' + alertId);
    } catch (e) {
      debugPrint('Resolve alert error: ' + e.toString());
      rethrow;
    }
  }

  // ==================== CANCEL ALERT ====================

  Future<void> cancelAlert(String alertId) async {
    try {
      await _firestore.collection('community_alerts').doc(alertId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Alert cancelled: ' + alertId);
    } catch (e) {
      debugPrint('Cancel alert error: ' + e.toString());
      rethrow;
    }
  }

  // ==================== INCREMENT VIEW COUNT ====================

  Future<void> incrementViewCount(String alertId) async {
    try {
      await _firestore.collection('community_alerts').doc(alertId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Increment view count error: ' + e.toString());
    }
  }

  // ==================== GET HELPERS ====================

  Future<List<Map<String, dynamic>>> getHelpers(String alertId) async {
    try {
      final snapshot = await _firestore
          .collection('community_alerts')
          .doc(alertId)
          .collection('helpers')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      debugPrint('Get helpers error: ' + e.toString());
      return [];
    }
  }

  // ==================== CREATE SAFE ZONE ====================

  Future<String?> createSafeZone({
    required String userId,
    required String name,
    required String description,
    required Position position,
    required double radiusMeters,
    String? address,
  }) async {
    try {
      final doc = await _firestore.collection('safe_zones').add({
        'userId': userId,
        'name': name,
        'description': description,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'radiusMeters': radiusMeters,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'visitCount': 0,
      });

      debugPrint('Safe zone created: ' + doc.id);
      return doc.id;
    } catch (e) {
      debugPrint('Create safe zone error: ' + e.toString());
      return null;
    }
  }

  // ==================== GET NEARBY SAFE ZONES ====================

  Future<List<Map<String, dynamic>>> getNearbySafeZones({
    required Position currentPosition,
    double radiusKm = 5.0,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('safe_zones')
          .where('isActive', isEqualTo: true)
          .get();

      final safeZones = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'];

        if (location != null) {
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            location['latitude'],
            location['longitude'],
          );

          if (distance / 1000 <= radiusKm) {
            safeZones.add({
              'id': doc.id,
              'distance': distance,
              ...data,
            });
          }
        }
      }

      safeZones.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      debugPrint('Found ' + safeZones.length.toString() + ' safe zones');
      return safeZones;
    } catch (e) {
      debugPrint('Get safe zones error: ' + e.toString());
      return [];
    }
  }

  // ==================== DELETE SAFE ZONE ====================

  Future<void> deleteSafeZone(String zoneId) async {
    try {
      await _firestore.collection('safe_zones').doc(zoneId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Safe zone deleted: ' + zoneId);
    } catch (e) {
      debugPrint('Delete safe zone error: ' + e.toString());
      rethrow;
    }
  }

  // ==================== GET NEARBY RESPONDERS ====================

  Future<List<Map<String, dynamic>>> getNearbyResponders({
    required Position currentPosition,
    double radiusKm = 5.0,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('responder_profiles')
          .where('isOnline', isEqualTo: true)
          .get();

      final responders = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'] as Map<String, dynamic>?;

        if (location != null) {
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            location['latitude'],
            location['longitude'],
          );

          if (distance / 1000 <= radiusKm) {
            responders.add({
              'id': doc.id,
              'distance': distance,
              ...data,
            });
          }
        }
      }

      responders.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      debugPrint('Found ' + responders.length.toString() + ' nearby responders');
      return responders;
    } catch (e) {
      debugPrint('Get nearby responders error: ' + e.toString());
      return [];
    }
  }

  // ==================== UPDATE RESPONDER PROFILE ====================

  Future<void> updateResponderProfile({
    required String userId,
    required String userName,
    required Position position,
    required Set<ResponderCapability> capabilities,
    bool isOnline = true,
  }) async {
    try {
      final displayName = _isAnonymous ? 'Anonymous Responder' : userName;

      await _firestore.collection('responder_profiles').doc(userId).set({
        'userId': userId,
        'userName': displayName,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'capabilities': capabilities.map((e) => e.name).toList(),
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Responder profile updated for: ' + userId);
    } catch (e) {
      debugPrint('Update responder profile error: ' + e.toString());
    }
  }

  // ==================== GET COMMUNITY STATS ====================

  Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final alertsSnapshot = await _firestore
          .collection('community_alerts')
          .where('status', isEqualTo: 'active')
          .get();

      final resolvedSnapshot = await _firestore
          .collection('community_alerts')
          .where('isResolved', isEqualTo: true)
          .get();

      final safeZonesSnapshot = await _firestore
          .collection('safe_zones')
          .where('isActive', isEqualTo: true)
          .get();

      final respondersSnapshot = await _firestore
          .collection('responder_profiles')
          .where('isOnline', isEqualTo: true)
          .get();

      int totalHelpers = 0;
      int totalWitnesses = 0;

      for (final doc in alertsSnapshot.docs) {
        final data = doc.data();
        totalHelpers += (data['helpersCount'] as int?) ?? 0;
        totalWitnesses += (data['witnessCount'] as int?) ?? 0;
      }

      return {
        'activeAlerts': alertsSnapshot.size,
        'resolvedAlerts': resolvedSnapshot.size,
        'safeZones': safeZonesSnapshot.size,
        'totalHelpers': totalHelpers,
        'totalWitnesses': totalWitnesses,
        'onlineResponders': respondersSnapshot.size,
      };
    } catch (e) {
      debugPrint('Get community stats error: ' + e.toString());
      return {
        'activeAlerts': 0,
        'resolvedAlerts': 0,
        'safeZones': 0,
        'totalHelpers': 0,
        'totalWitnesses': 0,
        'onlineResponders': 0,
      };
    }
  }

  // ==================== SETTINGS MANAGEMENT ====================

  Future<void> setOptInStatus(bool optedIn) async {
    _isOptedIn = optedIn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('community_opted_in', optedIn);
    debugPrint('Community opt-in: ' + optedIn.toString());
    onLog?.call('Community settings updated');
  }

  Future<void> setAnonymousMode(bool anonymous) async {
    _isAnonymous = anonymous;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('community_anonymous', anonymous);
    debugPrint('Anonymous mode: ' + anonymous.toString());
  }

  Future<void> setAlertRadius(double radiusMeters) async {
    _alertRadius = radiusMeters;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('community_radius', radiusMeters);
    debugPrint('Alert radius: ' + radiusMeters.toString() + 'm');
  }

  Future<void> setUserCapabilities(Set<ResponderCapability> capabilities) async {
    _userCapabilities = capabilities;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'community_capabilities',
      capabilities.map((e) => e.name).toList(),
    );
    debugPrint('User capabilities updated: ' + capabilities.length.toString() + ' capabilities');
  }

  // ==================== GETTERS ====================

  bool isOptedIn() => _isOptedIn;
  bool isAnonymous() => _isAnonymous;
  double getAlertRadius() => _alertRadius;
  Set<ResponderCapability> getUserCapabilities() => _userCapabilities;

  // ==================== FORMAT DISTANCE ====================

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return meters.toStringAsFixed(0) + 'm away';
    } else {
      return (meters / 1000).toStringAsFixed(1) + 'km away';
    }
  }

  // ==================== GET SEVERITY COLOR ====================

  static Color getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow;
      case 'Low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // ==================== GET ALERT ICON ====================

  static IconData getAlertIcon(String alertType) {
    switch (alertType) {
      case 'Emergency':
        return Icons.warning;
      case 'Suspicious Activity':
        return Icons.visibility;
      case 'Medical Emergency':
        return Icons.medical_services;
      case 'Fire':
        return Icons.local_fire_department;
      case 'Accident':
        return Icons.car_crash;
      case 'Crime':
        return Icons.report;
      case 'Natural Disaster':
        return Icons.tsunami;
      case 'Lost Person':
        return Icons.person_search;
      default:
        return Icons.info;
    }
  }

  // ==================== DISPOSE ====================

  void dispose() {
    _alertsSubscription?.cancel();
    debugPrint('Community Safety Service disposed');
  }
}

// ==================== MODELS ====================

enum ResponderCapability {
  none,
  cprTrained,
  firstAid,
  medicalProfessional,
  fireTraining,
  selfDefense,
  mentalHealthFirst,
  translation,
  vehicleAssistance,
}

extension ResponderCapabilityExtension on ResponderCapability {
  String get displayName {
    switch (this) {
      case ResponderCapability.none:
        return 'None';
      case ResponderCapability.cprTrained:
        return 'CPR Trained';
      case ResponderCapability.firstAid:
        return 'First Aid';
      case ResponderCapability.medicalProfessional:
        return 'Medical Professional';
      case ResponderCapability.fireTraining:
        return 'Fire Training';
      case ResponderCapability.selfDefense:
        return 'Self Defense';
      case ResponderCapability.mentalHealthFirst:
        return 'Mental Health First Aid';
      case ResponderCapability.translation:
        return 'Translation Services';
      case ResponderCapability.vehicleAssistance:
        return 'Vehicle Assistance';
    }
  }

  IconData get icon {
    switch (this) {
      case ResponderCapability.none:
        return Icons.person;
      case ResponderCapability.cprTrained:
        return Icons.favorite;
      case ResponderCapability.firstAid:
        return Icons.medical_services;
      case ResponderCapability.medicalProfessional:
        return Icons.local_hospital;
      case ResponderCapability.fireTraining:
        return Icons.local_fire_department;
      case ResponderCapability.selfDefense:
        return Icons.shield;
      case ResponderCapability.mentalHealthFirst:
        return Icons.psychology;
      case ResponderCapability.translation:
        return Icons.translate;
      case ResponderCapability.vehicleAssistance:
        return Icons.car_repair;
    }
  }
}