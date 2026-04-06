import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'sms_service.dart';
import 'location_history_service.dart';
import 'connectivity_service.dart';

class PanicService {
// 1. Move the initialize method here, inside the class!
  Future<void> initialize() async {
// Add any setup logic here if needed
    print('PanicService initialized');
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SMSService _smsService = SMSService();
  final LocationHistoryService _locationHistory = LocationHistoryService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Retry configuration
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const List<int> RETRY_DELAYS = [30, 60, 300]; // 30s, 1m, 5m in seconds

  // ==================== MAIN PANIC TRIGGER ====================

  Future<Map<String, dynamic>> triggerPanic(String userId, String userName) async {
    try {
      print(' PANIC SERVICE: Starting panic trigger for user: $userName');

      // Get location
      final position = await _getLocation();
      final locationString = position != null
          ? '${position.latitude}, ${position.longitude}'
          : 'Location unavailable';

      print(' Location obtained: $locationString');

      // Get contacts
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      if (contactsSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'error': 'No emergency contacts found',
        };
      }

      // Sort contacts by priority
      final contacts = contactsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'phone': data['phone'] ?? '',
          'priority': data['priority'] ?? 2,
          'relationship': data['relationship'] ?? 'Contact',
        };
      }).toList();

      contacts.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

      print(' Found ${contacts.length} emergency contacts');

      // Create panic event
      final eventRef = await _firestore.collection('panic_events').add({
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'location': locationString,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'status': 'active',
        'contactsNotified': 0,
        'smsSent': 0,
        'smsFailed': 0,
        'callsMade': 0,
        'callsSuccessful': 0,
        'retriesQueued': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      print(' Panic event created: ${eventRef.id}');

      // Start location tracking
      _locationHistory.startTracking(eventRef.id);

      // Check connectivity
      final isOnline = await _connectivityService.isOnline();
      print(' Connectivity status: ${isOnline ? "ONLINE" : "OFFLINE"}');

      // Send alerts with escalation
      final alertResult = await _sendAlertsWithEscalation(
        contacts: contacts,
        userName: userName,
        location: locationString,
        eventId: eventRef.id,
        isOnline: isOnline,
      );

      // Update event with results
      await eventRef.update({
        'contactsNotified': alertResult['contactsNotified'],
        'smsSent': alertResult['smsSent'],
        'smsFailed': alertResult['smsFailed'],
        'callsMade': alertResult['callsMade'],
        'callsSuccessful': alertResult['callsSuccessful'],
        'retriesQueued': alertResult['retriesQueued'],
        'autoCallUsed': alertResult['autoCallUsed'],
        'autoRetryUsed': alertResult['autoRetryUsed'],
        'locationTrackingActive': true,
      });

      print(' PANIC SERVICE: Alert completed successfully');

      return {
        'success': true,
        'alertId': eventRef.id,
        'location': locationString,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'contactsNotified': alertResult['contactsNotified'],
        'smsSent': alertResult['smsSent'],
        'smsFailed': alertResult['smsFailed'],
        'callsMade': alertResult['callsMade'],
        'callsSuccessful': alertResult['callsSuccessful'],
        'retriesQueued': alertResult['retriesQueued'],
        'autoCallUsed': alertResult['autoCallUsed'],
        'autoRetryUsed': alertResult['autoRetryUsed'],
        'locationTrackingActive': true,
      };
    } catch (e) {
      print(' PANIC SERVICE ERROR: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== ESCALATION SYSTEM ====================

  Future<Map<String, dynamic>> _sendAlertsWithEscalation({
    required List<Map<String, dynamic>> contacts,
    required String userName,
    required String location,
    required String eventId,
    required bool isOnline,
  }) async {
    int contactsNotified = 0;
    int smsSent = 0;
    int smsFailed = 0;
    int callsMade = 0;
    int callsSuccessful = 0;
    int retriesQueued = 0;
    bool autoCallUsed = false;
    bool autoRetryUsed = false;

    final message = ' EMERGENCY ALERT from $userName!\n'
        'Location: $location\n'
        'Timestamp: ${DateTime.now()}\n'
        'This is an automated panic alert.';

    print(' Starting alert escalation for ${contacts.length} contacts');

    for (var contact in contacts) {
      final contactName = contact['name'] as String;
      final phone = contact['phone'] as String;
      final priority = contact['priority'] as int;

      print(' Processing contact: $contactName (Priority: $priority)');

      // Try sending SMS with retry
      final smsResult = await _sendSMSWithRetry(
        phone: phone,
        message: message,
        contactName: contactName,
        eventId: eventId,
        maxRetries: MAX_RETRY_ATTEMPTS,
      );

      if (smsResult['success'] == true) {
        smsSent++;
        contactsNotified++;
        print(' SMS sent successfully to $contactName');

        // Log success
        await _logContactAttempt(
          eventId: eventId,
          contactName: contactName,
          phone: phone,
          method: 'SMS',
          status: 'success',
          attempts: smsResult['attempts'] ?? 1,
        );
      } else {
        smsFailed++;
        print(' SMS failed to $contactName after ${smsResult['attempts']} attempts');

        // Log failure
        await _logContactAttempt(
          eventId: eventId,
          contactName: contactName,
          phone: phone,
          method: 'SMS',
          status: 'failed',
          attempts: smsResult['attempts'] ?? MAX_RETRY_ATTEMPTS,
          error: smsResult['error'],
        );

        // ESCALATE TO PHONE CALL
        print(' Escalating to phone call for $contactName');
        final callResult = await _makeEmergencyCall(phone, contactName);

        if (callResult['success'] == true) {
          callsMade++;
          callsSuccessful++;
          contactsNotified++;
          autoCallUsed = true;
          print(' Call initiated to $contactName');

          await _logContactAttempt(
            eventId: eventId,
            contactName: contactName,
            phone: phone,
            method: 'CALL',
            status: 'initiated',
            attempts: 1,
          );
        } else {
          callsMade++;
          print(' Call failed to $contactName');

          // QUEUE FOR RETRY
          print(' Queueing $contactName for retry');
          await _queueRetry(
            eventId: eventId,
            contactName: contactName,
            phone: phone,
            message: message,
          );
          retriesQueued++;
          autoRetryUsed = true;
        }
      }

      // Small delay between contacts
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print(' Alert Summary:');
    print(' Contacts Notified: $contactsNotified');
    print(' SMS Sent: $smsSent');
    print(' SMS Failed: $smsFailed');
    print(' Calls Made: $callsMade');
    print(' Calls Successful: $callsSuccessful');
    print(' Retries Queued: $retriesQueued');

    return {
      'contactsNotified': contactsNotified,
      'smsSent': smsSent,
      'smsFailed': smsFailed,
      'callsMade': callsMade,
      'callsSuccessful': callsSuccessful,
      'retriesQueued': retriesQueued,
      'autoCallUsed': autoCallUsed,
      'autoRetryUsed': autoRetryUsed,
    };
  }

  // ==================== SMS WITH RETRY ====================

  Future<Map<String, dynamic>> _sendSMSWithRetry({
    required String phone,
    required String message,
    required String contactName,
    required String eventId,
    required int maxRetries,
  }) async {
    int attempts = 0;

    for (int i = 0; i < maxRetries; i++) {
      attempts++;
      print(' SMS Attempt $attempts/$maxRetries to $contactName');

      try {
        await _smsService.sendSMS(phoneNumber: phone, message: message);
        print(' SMS sent on attempt $attempts');
        return {
          'success': true,
          'attempts': attempts,
        };
      } catch (e) {
        print(' SMS attempt $attempts failed: $e');

        if (i < maxRetries - 1) {
          final delaySeconds = RETRY_DELAYS[i];
          print(' Waiting ${delaySeconds}s before retry...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }

    return {
      'success': false,
      'attempts': attempts,
      'error': 'All retry attempts failed',
    };
  }

  // ==================== EMERGENCY CALL ====================

  Future<Map<String, dynamic>> _makeEmergencyCall(
      String phone,
      String contactName,
      ) async {
    try {
      final phoneUrl = 'tel:$phone';
      final uri = Uri.parse(phoneUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return {
          'success': true,
          'message': 'Call initiated to $contactName',
        };
      } else {
        return {
          'success': false,
          'error': 'Cannot launch phone dialer',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== RETRY QUEUE ====================

  Future<void> _queueRetry({
    required String eventId,
    required String contactName,
    required String phone,
    required String message,
  }) async {
    try {
      await _firestore
          .collection('panic_events')
          .doc(eventId)
          .collection('retry_queue')
          .add({
        'contactName': contactName,
        'phone': phone,
        'message': message,
        'queuedAt': FieldValue.serverTimestamp(),
        'nextRetryAt': DateTime.now().add(const Duration(seconds: 30)),
        'retryAttempts': 0,
        'maxRetries': MAX_RETRY_ATTEMPTS,
        'status': 'queued',
      });

      print(' Retry queued for $contactName');
    } catch (e) {
      print(' Failed to queue retry: $e');
    }
  }

  // ==================== LOGGING ====================

  Future<void> _logContactAttempt({
    required String eventId,
    required String contactName,
    required String phone,
    required String method,
    required String status,
    required int attempts,
    String? error,
  }) async {
    try {
      await _firestore
          .collection('panic_events')
          .doc(eventId)
          .collection('contact_attempts')
          .add({
        'contactName': contactName,
        'phone': phone,
        'method': method,
        'status': status,
        'attempts': attempts,
        'error': error,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(' Failed to log contact attempt: $e');
    }
  }

  // ==================== LOCATION ====================

  Future<Position?> _getLocation() async {
    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        print(' Location permission denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      return position;
    } catch (e) {
      print(' Location error: $e');
      return null;
    }
  }

  // ==================== RETRY PROCESSOR ====================

  /// Process retry queue (call this periodically)
  Future<void> processRetryQueue(String eventId) async {
    try {
      final now = DateTime.now();
      final retries = await _firestore
          .collection('panic_events')
          .doc(eventId)
          .collection('retry_queue')
          .where('status', isEqualTo: 'queued')
          .get();

      for (var doc in retries.docs) {
        final data = doc.data();
        final nextRetry = (data['nextRetryAt'] as Timestamp).toDate();

        if (now.isAfter(nextRetry)) {
          final phone = data['phone'] as String;
          final message = data['message'] as String;
          final contactName = data['contactName'] as String;
          final attempts = data['retryAttempts'] as int;

          print(' Processing retry for $contactName (attempt ${attempts + 1})');

          try {
            await _smsService.sendSMS(phoneNumber: phone, message: message);

            // Success - remove from queue
            await doc.reference.update({
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });

            print(' Retry successful for $contactName');
          } catch (e) {
            // Failed - update retry count
            final newAttempts = attempts + 1;

            if (newAttempts >= MAX_RETRY_ATTEMPTS) {
              await doc.reference.update({
                'status': 'failed',
                'failedAt': FieldValue.serverTimestamp(),
                'error': e.toString(),
              });
              print(' Retry failed permanently for $contactName');
            } else {
              await doc.reference.update({
                'retryAttempts': newAttempts,
                'nextRetryAt': now.add(Duration(seconds: RETRY_DELAYS[newAttempts])),
              });
              print(' Retry failed, scheduling next attempt for $contactName');
            }
          }
        }
      }
    } catch (e) {
      print(' Error processing retry queue: $e');
    }
  }

  // ==================== EMERGENCY INFO ====================

  /// Get emergency information for a specific user
  Future<Map<String, dynamic>?> getEmergencyInfo(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print(' User document not found');
        return null;
      }

      final userData = userDoc.data();

      // Get emergency contacts
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      final contacts = contactsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'phone': data['phone'] ?? '',
          'priority': data['priority'] ?? 2,
          'relationship': data['relationship'] ?? 'Contact',
        };
      }).toList();

      // Get medical info if exists
      Map<String, dynamic>? medicalInfo;
      try {
        final medicalDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medical_info')
            .doc('profile')
            .get();

        if (medicalDoc.exists) {
          medicalInfo = medicalDoc.data();
        }
      } catch (e) {
        print(' No medical info found: $e');
      }

      return {
        'user': {
          'id': userId,
          'name': userData?['name'] ?? 'User',
          'email': userData?['email'] ?? '',
          'phone': userData?['phone'] ?? '',
        },
        'contacts': contacts,
        'medicalInfo': medicalInfo,
        'totalContacts': contacts.length,
        'hasMedicalInfo': medicalInfo != null,
      };
    } catch (e) {
      print(' Error getting emergency info: $e');
      return null;
    }
  }

  /// Get recent panic events for a user
  Future<List<Map<String, dynamic>>> getRecentPanicEvents(
      String userId, {
        int limit = 10,
      }) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'timestamp': data['timestamp'],
          'location': data['location'],
          'status': data['status'],
          'contactsNotified': data['contactsNotified'] ?? 0,
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        };
      }).toList();
    } catch (e) {
      print(' Error getting panic events: $e');
      return [];
    }
  }

  /// Get active panic alerts
  Future<List<Map<String, dynamic>>> getActivePanicAlerts(String userId) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .get();

      return eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'timestamp': data['timestamp'],
          'location': data['location'],
          'contactsNotified': data['contactsNotified'] ?? 0,
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        };
      }).toList();
    } catch (e) {
      print(' Error getting active alerts: $e');
      return [];
    }
  }

  /// Cancel an active panic alert
  Future<bool> cancelPanicAlert(String eventId) async {
    try {
      await _firestore.collection('panic_events').doc(eventId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Stop location tracking
      _locationHistory.stopTracking();

      print(' Panic alert $eventId cancelled');
      return true;
    } catch (e) {
      print(' Error cancelling panic alert: $e');
      return false;
    }
  }

  /// Resolve/complete a panic alert
  Future<bool> resolvePanicAlert(String eventId) async {
    try {
      await _firestore.collection('panic_events').doc(eventId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      // Stop location tracking
      _locationHistory.stopTracking();

      print(' Panic alert $eventId resolved');
      return true;
    } catch (e) {
      print(' Error resolving panic alert: $e');
      return false;
    }
  }

  /// Get panic statistics for a user
  Future<Map<String, dynamic>> getPanicStatistics(String userId) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .get();

      final events = eventsSnapshot.docs;
      final totalEvents = events.length;

      int activeAlerts = 0;
      int cancelledAlerts = 0;
      int resolvedAlerts = 0;
      int totalContactsNotified = 0;
      int totalSMSSent = 0;
      int totalCallsMade = 0;

      for (var doc in events) {
        final data = doc.data();
        final status = data['status'] as String?;

        switch (status) {
          case 'active':
            activeAlerts++;
            break;
          case 'cancelled':
            cancelledAlerts++;
            break;
          case 'resolved':
            resolvedAlerts++;
            break;
        }

        totalContactsNotified += (data['contactsNotified'] as int? ?? 0);
        totalSMSSent += (data['smsSent'] as int? ?? 0);
        totalCallsMade += (data['callsMade'] as int? ?? 0);
      }

      return {
        'totalEvents': totalEvents,
        'activeAlerts': activeAlerts,
        'cancelledAlerts': cancelledAlerts,
        'resolvedAlerts': resolvedAlerts,
        'totalContactsNotified': totalContactsNotified,
        'totalSMSSent': totalSMSSent,
        'totalCallsMade': totalCallsMade,
        'averageContactsPerAlert': totalEvents > 0
            ? (totalContactsNotified / totalEvents).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print(' Error getting panic statistics: $e');
      return {
        'totalEvents': 0,
        'activeAlerts': 0,
        'cancelledAlerts': 0,
        'resolvedAlerts': 0,
        'totalContactsNotified': 0,
        'totalSMSSent': 0,
        'totalCallsMade': 0,
        'averageContactsPerAlert': '0.0',
      };
    }
  }

  /// Get panic event details
  Future<Map<String, dynamic>?> getPanicEventDetails(String eventId) async {
    try {
      final eventDoc = await _firestore
          .collection('panic_events')
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        return null;
      }

      final data = eventDoc.data()!;

      // Get contact attempts
      final attemptsSnapshot = await _firestore
          .collection('panic_events')
          .doc(eventId)
          .collection('contact_attempts')
          .orderBy('timestamp', descending: false)
          .get();

      final attempts = attemptsSnapshot.docs.map((doc) {
        return doc.data();
      }).toList();

      // Get retry queue
      final retrySnapshot = await _firestore
          .collection('panic_events')
          .doc(eventId)
          .collection('retry_queue')
          .get();

      final retries = retrySnapshot.docs.map((doc) {
        return doc.data();
      }).toList();

      return {
        'id': eventId,
        'event': data,
        'contactAttempts': attempts,
        'retryQueue': retries,
      };
    } catch (e) {
      print(' Error getting panic event details: $e');
      return null;
    }
  }

  /// Delete old panic events (cleanup)
  Future<int> deleteOldPanicEvents(String userId, {int daysOld = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final eventsSnapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int deletedCount = 0;

      for (var doc in eventsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      print(' Deleted $deletedCount old panic events');
      return deletedCount;
    } catch (e) {
      print(' Error deleting old events: $e');
      return 0;
    }
  }
}