import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/fire_emergency.dart';
import '../models/emergency_info.dart';

class FireService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Fire emergency numbers by country
  static const Map<String, String> fireEmergencyNumbers = {
    'US': '911',
    'UK': '999',
    'EU': '112',
    'AU': '000',
    'CA': '911',
    'IN': '101',
    'JP': '119',
    'CN': '119',
    'BR': '193',
    'MX': '911',
  };

  // Fire types (extended)
  static const List<String> fireTypes = [
    'House Fire',
    'Building Fire',
    'Vehicle Fire',
    'Wildfire',
    'Electrical Fire',
    'Gas Fire',
    'Kitchen Fire',
    'Forest Fire',
    'Industrial Fire',
    'Chemical Fire',
    'Other',
  ];

  // Fire severity levels
  static const List<String> severityLevels = [
    'Minor (Small flames)',
    'Moderate (Spreading)',
    'Severe (Out of control)',
    'Critical (Life-threatening)',
  ];

  /// Report fire emergency (ENHANCED)
  Future<Map<String, dynamic>> reportFire({
    required String userId,
    required String userName,
    required String fireType,
    required String severity,
    String? buildingInfo,
    String? floorNumber,
    String? unitNumber,
    String? description,
    String? peopleTrapped,
    String? photoUrl,
    EmergencyInfo? medicalInfo,
    Map<String, dynamic>? location,
  }) async {
    try {
      // Get location if not provided
      Position? position;
      if (location == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          );
          location = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
          };
        } catch (e) {
          print('Could not get location: $e');
        }
      }

      // Create fire emergency
      final fireEmergency = FireEmergency(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        latitude: location?['latitude'],
        longitude: location?['longitude'],
        fireType: fireType,
        severity: severity,
        buildingInfo: buildingInfo ?? '',
        floorNumber: floorNumber ?? '',
        unitNumber: unitNumber ?? '',
        description: description ?? '',
        timestamp: DateTime.now(),
        status: 'pending',
      );

      // Save to Firestore with extended data
      await _firestore
          .collection('fire_emergencies')
          .doc(fireEmergency.id)
          .set({
        ...fireEmergency.toMap(),
        'peopleTrapped': peopleTrapped,
        'photoUrl': photoUrl,
        'notifiedFireDept': true,
        'notifiedNeighbors': false,
        'responseTime': '5-10 minutes',
      });

      // Build emergency message for fire department
      final message = _buildFireEmergencyMessage(
        fireEmergency: fireEmergency,
        medicalInfo: medicalInfo,
        peopleTrapped: peopleTrapped,
      );

      // Log the emergency message
      print(' FIRE EMERGENCY REPORTED:');
      print(message);

      // Simulate dispatch
      await Future.delayed(const Duration(seconds: 2));
      await _updateStatus(fireEmergency.id, 'dispatched');

      // Log to user's fire history
      await _logFireEmergency(userId, fireEmergency.id, fireEmergency.toMap());

      // Get fire department number
      final fireNumber = getFireEmergencyNumber();

      return {
        'success': true,
        'emergencyId': fireEmergency.id,
        'reportId': fireEmergency.id,
        'fireNumber': fireNumber,
        'location': location,
        'message': 'Fire department notified',
        'estimatedArrival': '5-10 minutes',
        'responseTime': '5-10 minutes',
      };
    } catch (e) {
      print(' Report fire error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Build fire emergency message (ENHANCED)
  String _buildFireEmergencyMessage({
    required FireEmergency fireEmergency,
    EmergencyInfo? medicalInfo,
    String? peopleTrapped,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(' FIRE EMERGENCY ALERT \n');
    buffer.writeln('Reporter: ${fireEmergency.userName}');
    buffer.writeln('Time: ${fireEmergency.timestamp}\n');

    // Fire details
    buffer.writeln(' FIRE DETAILS:');
    buffer.writeln('Type: ${_getFireTypeLabel(fireEmergency.fireType)}');
    buffer.writeln('Severity: ${_getSeverityLabel(fireEmergency.severity)}\n');

    // People trapped
    if (peopleTrapped != null && peopleTrapped.isNotEmpty) {
      buffer.writeln(' PEOPLE TRAPPED: $peopleTrapped\n');
    }

    // Location
    if (fireEmergency.latitude != null && fireEmergency.longitude != null) {
      buffer.writeln(' LOCATION:');
      buffer.writeln('Lat: ${fireEmergency.latitude!.toStringAsFixed(6)}');
      buffer.writeln('Lng: ${fireEmergency.longitude!.toStringAsFixed(6)}');
      buffer.writeln(
          'https://maps.google.com/?q=${fireEmergency.latitude},${fireEmergency.longitude}\n');
    }

    // Building info
    if (fireEmergency.buildingInfo.isNotEmpty ||
        fireEmergency.floorNumber.isNotEmpty ||
        fireEmergency.unitNumber.isNotEmpty) {
      buffer.writeln(' BUILDING INFO:');
      if (fireEmergency.buildingInfo.isNotEmpty) {
        buffer.writeln('Building: ${fireEmergency.buildingInfo}');
      }
      if (fireEmergency.floorNumber.isNotEmpty) {
        buffer.writeln('Floor: ${fireEmergency.floorNumber}');
      }
      if (fireEmergency.unitNumber.isNotEmpty) {
        buffer.writeln('Unit: ${fireEmergency.unitNumber}');
      }
      buffer.writeln();
    }

    // Description
    if (fireEmergency.description.isNotEmpty) {
      buffer.writeln(' DESCRIPTION:');
      buffer.writeln(fireEmergency.description);
      buffer.writeln();
    }

    // Medical info
    if (medicalInfo != null && medicalInfo.hasInfo) {
      buffer.write(medicalInfo.formatForAlert());
    }

    return buffer.toString();
  }

  String _getFireTypeLabel(String type) {
    // Handle both old and new fire type formats
    final lowercaseType = type.toLowerCase();

    if (lowercaseType.contains('building') || lowercaseType == 'building') {
      return 'Building Fire';
    } else if (lowercaseType.contains('house') || lowercaseType == 'house') {
      return 'House Fire';
    } else if (lowercaseType.contains('vehicle') || lowercaseType == 'vehicle') {
      return 'Vehicle Fire';
    } else if (lowercaseType.contains('wildfire') || lowercaseType == 'wildfire') {
      return 'Wildfire';
    } else if (lowercaseType.contains('electrical') || lowercaseType == 'electrical') {
      return 'Electrical Fire';
    } else if (lowercaseType.contains('gas') || lowercaseType == 'gas') {
      return 'Gas Fire';
    } else if (lowercaseType.contains('kitchen') || lowercaseType == 'kitchen') {
      return 'Kitchen Fire';
    } else if (lowercaseType.contains('forest') || lowercaseType == 'forest') {
      return 'Forest Fire';
    } else if (lowercaseType.contains('industrial') || lowercaseType == 'industrial') {
      return 'Industrial Fire';
    } else if (lowercaseType.contains('chemical') || lowercaseType == 'chemical') {
      return 'Chemical Fire';
    } else {
      return type; // Return original if no match
    }
  }

  String _getSeverityLabel(String severity) {
    final lowercaseSeverity = severity.toLowerCase();

    if (lowercaseSeverity.contains('minor') || lowercaseSeverity == 'minor') {
      return ' Minor (Small flames, contained)';
    } else if (lowercaseSeverity.contains('moderate') || lowercaseSeverity == 'moderate') {
      return ' Moderate (Spreading, smoke visible)';
    } else if (lowercaseSeverity.contains('severe') || lowercaseSeverity == 'severe') {
      return ' Severe (Large flames, immediate danger)';
    } else if (lowercaseSeverity.contains('critical') || lowercaseSeverity == 'critical') {
      return ' CRITICAL (Life-threatening, evacuation needed)';
    } else {
      return severity; // Return original if no match
    }
  }

  Future<void> _updateStatus(String emergencyId, String status) async {
    await _firestore
        .collection('fire_emergencies')
        .doc(emergencyId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Call fire department (NEW)
  Future<bool> callFireDepartment() async {
    try {
      final fireNumber = getFireEmergencyNumber();
      final uri = Uri.parse('tel:$fireNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        print(' Calling fire department: $fireNumber');
        return true;
      } else {
        print(' Cannot launch phone dialer');
        return false;
      }
    } catch (e) {
      print(' Call fire department error: $e');
      return false;
    }
  }

  /// Get fire emergency number based on location/country (NEW)
  String getFireEmergencyNumber() {
    // TODO: Detect country from location
    // For now, return default US number
    return fireEmergencyNumbers['US'] ?? '911';
  }

  /// Log fire emergency to user history (NEW)
  Future<void> _logFireEmergency(
      String userId,
      String reportId,
      Map<String, dynamic> report,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fire_history')
          .add({
        'reportId': reportId,
        'fireType': report['fireType'],
        'severity': report['severity'],
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': report['latitude'],
          'longitude': report['longitude'],
        },
      });

      print(' Fire emergency logged to user history');
    } catch (e) {
      print(' Log fire emergency error: $e');
    }
  }

  /// Get fire history (NEW)
  Future<List<Map<String, dynamic>>> getFireHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fire_history')
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
      print(' Get fire history error: $e');
      return [];
    }
  }

  /// Get nearby fire emergencies (NEW - for community alerts)
  Future<List<Map<String, dynamic>>> getNearbyFireEmergencies({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // Get all active fire emergencies
      final snapshot = await _firestore
          .collection('fire_emergencies')
          .where('status', whereIn: ['pending', 'dispatched', 'active'])
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      // Filter by distance
      final nearbyFires = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fireLat = data['latitude'] as double?;
        final fireLng = data['longitude'] as double?;

        if (fireLat != null && fireLng != null) {
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            fireLat,
            fireLng,
          );

          final distanceKm = distance / 1000;

          if (distanceKm <= radiusKm) {
            nearbyFires.add({
              'id': doc.id,
              'distance': distanceKm,
              ...data,
            });
          }
        }
      }

      // Sort by distance
      nearbyFires.sort(
              (a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      return nearbyFires;
    } catch (e) {
      print(' Get nearby fires error: $e');
      return [];
    }
  }

  /// Update fire status (NEW - extended)
  Future<bool> updateFireStatus(String reportId, String status) async {
    try {
      await _firestore.collection('fire_emergencies').doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(' Fire status updated: $status');
      return true;
    } catch (e) {
      print(' Update fire status error: $e');
      return false;
    }
  }

  /// Send neighborhood alert (NEW)
  Future<bool> sendNeighborhoodAlert(
      String reportId,
      double latitude,
      double longitude,
      ) async {
    try {
      // Mark as notified
      await _firestore.collection('fire_emergencies').doc(reportId).update({
        'notifiedNeighbors': true,
        'neighborhoodAlertSent': FieldValue.serverTimestamp(),
      });

      // TODO: Implement push notifications to nearby users
      print(' Neighborhood alert sent');
      return true;
    } catch (e) {
      print(' Send neighborhood alert error: $e');
      return false;
    }
  }

  /// Get fire safety tips (NEW)
  static List<String> getFireSafetyTips(String fireType) {
    final lowercaseType = fireType.toLowerCase();

    if (lowercaseType.contains('house') || lowercaseType.contains('building')) {
      return [
        ' Get out immediately - don\'t stop for belongings',
        ' Feel doors before opening - if hot, use another exit',
        ' Stay low to avoid smoke inhalation',
        ' Call fire department once outside',
        ' Never go back inside',
        ' Go to designated meeting point',
      ];
    } else if (lowercaseType.contains('kitchen')) {
      return [
        ' Turn off heat source immediately',
        ' Use fire extinguisher if small',
        ' Cover pan fires with metal lid',
        ' Never use water on grease fires',
        ' Evacuate if fire spreads',
        ' Call 911 if fire is large',
      ];
    } else if (lowercaseType.contains('electrical')) {
      return [
        ' Cut power at breaker if safe',
        ' Use Class C fire extinguisher',
        ' Never use water on electrical fires',
        ' Evacuate if fire spreads',
        ' Call fire department immediately',
        ' Unplug appliances if safe to do so',
      ];
    } else if (lowercaseType.contains('wildfire')) {
      return [
        ' Evacuate immediately if ordered',
        ' Close all windows and doors',
        ' Wet roof if safe and time permits',
        ' Grab emergency kit and go',
        ' Monitor emergency broadcasts',
        ' Don\'t return until authorities say it\'s safe',
      ];
    } else if (lowercaseType.contains('vehicle')) {
      return [
        ' Pull over safely away from traffic',
        ' Get everyone out immediately',
        ' Call fire department',
        ' Use fire extinguisher only if small fire',
        ' Don\'t open hood if flames visible',
        ' Move far away from vehicle',
      ];
    } else {
      return [
        ' Evacuate immediately',
        ' Stay low - crawl if necessary',
        ' Feel doors before opening',
        ' Call 911 once safe',
        ' Don\'t go back inside',
        ' Use fire extinguisher only if small and safe',
      ];
    }
  }

  /// Estimate response time (NEW)
  static String getEstimatedResponseTime() {
    return '5-10 minutes'; // TODO: Integrate with real fire department APIs
  }

  // Get fire emergency by ID (EXISTING - kept as is)
  Future<FireEmergency?> getFireEmergency(String emergencyId) async {
    try {
      final doc = await _firestore
          .collection('fire_emergencies')
          .doc(emergencyId)
          .get();

      if (doc.exists) {
        return FireEmergency.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting fire emergency: $e');
      return null;
    }
  }

  // Get user's fire emergency history (EXISTING - kept as is)
  Stream<List<FireEmergency>> getUserFireEmergencies(String userId) {
    return _firestore
        .collection('fire_emergencies')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FireEmergency.fromMap(doc.data()))
        .toList());
  }
}