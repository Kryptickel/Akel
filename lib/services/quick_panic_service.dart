import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/emergency_contact.dart';
import '../services/contact_service.dart';
import '../services/sms_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../services/enhanced_location_service.dart';

class QuickPanicService {
  static final QuickPanicService _instance = QuickPanicService._internal();
  factory QuickPanicService() => _instance;
  QuickPanicService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContactService _contactService = ContactService();
  final SMSService _smsService = SMSService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();
  final EnhancedLocationService _locationService = EnhancedLocationService();

  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  bool _isPanicActive = false;
  bool _countdownCancelled = false;

// Callbacks
  Function(int)? _onCountdownTick;
  Function()? _onPanicTriggered;
  Function()? _onPanicCancelled;

// Statistics
  int _totalPanicsTriggered = 0;
  int _totalPanicsCancelled = 0;
  DateTime? _lastPanicTime;

  /// Initialize service
  Future<void> initialize({
    Function(int)? onCountdownTick,
    Function()? onPanicTriggered,
    Function()? onPanicCancelled,
  }) async {
    _onCountdownTick = onCountdownTick;
    _onPanicTriggered = onPanicTriggered;
    _onPanicCancelled = onPanicCancelled;

    debugPrint('✅ Quick Panic Service initialized');
  }

  /// Start panic countdown
  Future<void> startPanicCountdown({
    required String userId,
    int countdownSeconds = 10,
  }) async {
    if (_isPanicActive) {
      debugPrint('⚠️ Panic already active');
      return;
    }

    _isPanicActive = true;
    _countdownSeconds = countdownSeconds;
    _countdownCancelled = false;

    debugPrint('🚨 Starting panic countdown: $countdownSeconds seconds');

// Start vibration pattern
    _vibrationService.panic();
    _soundService.playWarning();

// Start countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _countdownSeconds--;

      _onCountdownTick?.call(_countdownSeconds);

      if (_countdownSeconds <= 0) {
        timer.cancel();
        if (!_countdownCancelled) {
          await _triggerPanic(userId);
        }
      } else if (_countdownSeconds <= 3) {
// Increase intensity in last 3 seconds
        _vibrationService.warning();
        _soundService.playWarning();
      }
    });
  }

  /// Cancel panic countdown
  Future<void> cancelPanicCountdown() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isPanicActive = false;
    _countdownCancelled = true;
    _totalPanicsCancelled++;

    await _vibrationService.success();
    await _soundService.playSuccess();

    _onPanicCancelled?.call();

    debugPrint('✅ Panic countdown cancelled');
  }

  /// Trigger panic immediately (skip countdown)
  Future<void> triggerPanicNow(String userId) async {
    await _triggerPanic(userId);
  }

  /// Internal panic trigger
  Future<void> _triggerPanic(String userId) async {
    _isPanicActive = false;
    _countdownTimer?.cancel();
    _totalPanicsTriggered++;
    _lastPanicTime = DateTime.now();

    debugPrint('🚨 PANIC TRIGGERED!');

// Intense vibration and sound
    await _vibrationService.panic();
    await _soundService.playAlarm();

    try {
// Get current location
      Position? position;
      String? address;

      try {
        position = await _locationService.getCurrentLocation();
        if (position != null) {
          address = await _locationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Could not get location: $e');
      }

// Get emergency contacts
      final contacts = await _contactService.getEmergencyContacts(userId);

      if (contacts.isEmpty) {
        debugPrint('⚠️ No emergency contacts found');
        _onPanicTriggered?.call();
        return;
      }

// Filter active contacts
      final activeContacts = contacts.where((c) => c.isActive).toList();

      if (activeContacts.isEmpty) {
        debugPrint('⚠️ No active emergency contacts found');
        _onPanicTriggered?.call();
        return;
      }

// Sort by priority (high priority first)
      activeContacts.sort((a, b) => a.priority.compareTo(b.priority));

// Create panic record
      final panicId = await _createPanicRecord(
        userId: userId,
        position: position,
        address: address,
      );

// Build location text
      final locationText = position != null
          ? '\nLocation: https://www.google.com/maps?q=${position.latitude},${position.longitude}'
          : '\nLocation: Not available';

      final addressText = address != null ? '\nAddress: $address' : '';

// Get user info
      final userProfile = await _getUserProfile(userId);
      final userName = userProfile?['name'] ?? 'Unknown User';

// Send alerts to all contacts
      int successCount = 0;
      int failureCount = 0;

      for (final contact in activeContacts) {
        try {
// Build personalized message
          final message = '🚨 EMERGENCY ALERT! 🚨\n\n'
              'From: $userName\n'
              'Contact: ${contact.name}${contact.relationship != null ? " (${contact.relationship})" : ""}\n'
              'Priority: ${contact.priorityName}\n\n'
              'Emergency activated at: ${DateTime.now().toString()}'
              '$locationText'
              '$addressText\n\n'
              'Please respond immediately!\n'
              'Sent via AKEL Panic Button';

// Send SMS
          await _smsService.sendSMS(
            phoneNumber: contact.phone, // ✅ FIXED - Use property, not map
            message: message,
          );

          successCount++;
          debugPrint('✅ Alert sent to ${contact.name} (${contact.phone})');
        } catch (e) {
          failureCount++;
          debugPrint('❌ Failed to send alert to ${contact.name}: $e');
        }
      }

// Update panic record with sent status
      await _updatePanicRecord(
        panicId: panicId,
        alertsSent: successCount,
        alertsFailed: failureCount,
      );

// Log to contact interactions
      for (final contact in activeContacts.take(successCount)) {
        await _contactService.logContactInteraction(
          userId,
          contact.id,
          'panic_alert',
        );
      }

      _onPanicTriggered?.call();

      debugPrint('✅ Panic alerts: $successCount sent, $failureCount failed out of ${activeContacts.length} contacts');
    } catch (e) {
      debugPrint('❌ Panic trigger error: $e');
      _onPanicTriggered?.call();
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Get user profile error: $e');
      return null;
    }
  }

  /// Create panic record in Firestore
  Future<String> _createPanicRecord({
    required String userId,
    Position? position,
    String? address,
  }) async {
    try {
      final docRef = await _firestore.collection('panic_events').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'quick_panic',
        'location': position != null
            ? {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        }
            : null,
        'address': address,
        'status': 'active',
        'alertsSent': 0,
        'alertsFailed': 0,
      });

// Also add to user's panic history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('panic_history')
          .doc(docRef.id)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'quick_panic',
        'location': position != null
            ? {
          'latitude': position.latitude,
          'longitude': position.longitude,
        }
            : null,
        'address': address,
      });

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Create panic record error: $e');
      return '';
    }
  }

  /// Update panic record
  Future<void> _updatePanicRecord({
    required String panicId,
    required int alertsSent,
    int alertsFailed = 0,
  }) async {
    try {
      await _firestore.collection('panic_events').doc(panicId).update({
        'alertsSent': alertsSent,
        'alertsFailed': alertsFailed,
        'alertsSentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Update panic record error: $e');
    }
  }

  /// Resolve panic
  Future<void> resolvePanic(String panicId) async {
    try {
      await _firestore.collection('panic_events').doc(panicId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Panic resolved: $panicId');
    } catch (e) {
      debugPrint('❌ Resolve panic error: $e');
    }
  }

  /// Get panic history for user
  Future<List<Map<String, dynamic>>> getPanicHistory(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('panic_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Get panic history error: $e');
      return [];
    }
  }

  /// Get active panics
  Future<List<Map<String, dynamic>>> getActivePanics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
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
      debugPrint('❌ Get active panics error: $e');
      return [];
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalPanicsTriggered': _totalPanicsTriggered,
      'totalPanicsCancelled': _totalPanicsCancelled,
      'lastPanicTime': _lastPanicTime?.toIso8601String(),
      'isPanicActive': _isPanicActive,
      'countdownSeconds': _countdownSeconds,
      'cancelRate': _totalPanicsTriggered > 0
          ? (_totalPanicsCancelled / (_totalPanicsTriggered + _totalPanicsCancelled) * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Get detailed statistics from Firestore
  Future<Map<String, dynamic>> getDetailedStatistics(String userId) async {
    try {
      final panicHistory = await getPanicHistory(userId);

      final total = panicHistory.length;
      final thisMonth = panicHistory.where((p) {
        final timestamp = (p['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) return false;
        final now = DateTime.now();
        return timestamp.year == now.year && timestamp.month == now.month;
      }).length;

      final thisWeek = panicHistory.where((p) {
        final timestamp = (p['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) return false;
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        return timestamp.isAfter(weekAgo);
      }).length;

      return {
        'total': total,
        'thisMonth': thisMonth,
        'thisWeek': thisWeek,
        'lastPanic': panicHistory.isNotEmpty ? panicHistory.first['timestamp'] : null,
        'averagePerMonth': total > 0 ? (total / 12).toStringAsFixed(1) : '0.0',
      };
    } catch (e) {
      debugPrint('❌ Get detailed statistics error: $e');
      return {
        'total': 0,
        'thisMonth': 0,
        'thisWeek': 0,
        'lastPanic': null,
        'averagePerMonth': '0.0',
      };
    }
  }

  /// Get active panic status
  bool get isPanicActive => _isPanicActive;
  int get countdownSeconds => _countdownSeconds;

  /// Dispose
  void dispose() {
    _countdownTimer?.cancel();
  }
}