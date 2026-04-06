import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/checkin.dart';
import 'panic_service.dart';

class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final PanicService _panicService = PanicService();

  static bool _initialized = false;

  // Initialize timezone and notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Set local timezone (default to UTC)
      tz.setLocalLocation(tz.getLocation('UTC'));

      debugPrint(' Check-in service initialized with timezone: UTC');
      _initialized = true;
    } catch (e) {
      debugPrint(' Check-in service initialization error: $e');
    }
  }

  // Schedule a check-in
  Future<String> scheduleCheckIn({
    required String userId,
    required DateTime scheduledTime,
    String frequency = 'once',
    String? notes,
  }) async {
    try {
      final checkIn = CheckIn(
        id: '',
        userId: userId,
        scheduledTime: scheduledTime,
        frequency: frequency,
        notes: notes,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .add(checkIn.toMap());

      debugPrint(' Check-in scheduled: ${docRef.id}');

      // Schedule notification
      await _scheduleNotification(docRef.id, scheduledTime, notes);

      // If recurring, schedule next check-in
      if (frequency != 'once') {
        await _scheduleRecurringCheckIn(userId, scheduledTime, frequency, notes);
      }

      return docRef.id;
    } catch (e) {
      debugPrint(' Schedule check-in error: $e');
      rethrow;
    }
  }

  // Complete a check-in
  Future<void> completeCheckIn(String userId, String checkInId, {String? location}) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .doc(checkInId)
          .update({
        'completed': true,
        'completedTime': DateTime.now().toIso8601String(),
        'location': location,
      });

      debugPrint(' Check-in completed: $checkInId');

      // Cancel notification
      await _cancelNotification(checkInId);
    } catch (e) {
      debugPrint(' Complete check-in error: $e');
      rethrow;
    }
  }

  // Mark check-in as missed and trigger alert
  Future<void> markCheckInMissed(String userId, String checkInId) async {
    try {
      // Get check-in details
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .doc(checkInId)
          .get();

      if (!doc.exists) {
        return;
      }

      final checkIn = CheckIn.fromMap(doc.data()!, doc.id);

      // Don't process if already handled
      if (checkIn.completed || checkIn.alertSent) {
        return;
      }

      // Mark as missed
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .doc(checkInId)
          .update({
        'missed': true,
        'alertSent': true,
      });

      debugPrint(' Check-in missed: $checkInId - Triggering alert');

      // Get user name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'User';

      // Trigger panic alert
      await _panicService.triggerPanic(userId, userName);

      debugPrint(' Missed check-in alert sent');
    } catch (e) {
      debugPrint(' Mark check-in missed error: $e');
      rethrow;
    }
  }

  // Get upcoming check-ins
  Stream<List<CheckIn>> getUpcomingCheckIns(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('check_ins')
        .where('completed', isEqualTo: false)
        .where('missed', isEqualTo: false)
        .orderBy('scheduledTime')
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CheckIn.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Get check-in history
  Stream<List<CheckIn>> getCheckInHistory(String userId, {int limit = 20}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('check_ins')
        .orderBy('scheduledTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CheckIn.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Cancel check-in
  Future<void> cancelCheckIn(String userId, String checkInId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .doc(checkInId)
          .delete();

      await _cancelNotification(checkInId);

      debugPrint(' Check-in cancelled: $checkInId');
    } catch (e) {
      debugPrint(' Cancel check-in error: $e');
      rethrow;
    }
  }

  // Check for missed check-ins (call this periodically)
  Future<void> checkForMissedCheckIns(String userId) async {
    try {
      final now = DateTime.now();
      final fifteenMinutesAgo = now.subtract(const Duration(minutes: 15));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .where('completed', isEqualTo: false)
          .where('missed', isEqualTo: false)
          .where('alertSent', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        final checkIn = CheckIn.fromMap(doc.data(), doc.id);

        if (checkIn.scheduledTime.isBefore(fifteenMinutesAgo)) {
          await markCheckInMissed(userId, checkIn.id);
        }
      }
    } catch (e) {
      debugPrint(' Check missed check-ins error: $e');
    }
  }

  // Get check-in statistics
  Future<Map<String, int>> getCheckInStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .get();

      final total = snapshot.docs.length;
      final completed = snapshot.docs.where((doc) => doc.data()['completed'] == true).length;
      final missed = snapshot.docs.where((doc) => doc.data()['missed'] == true).length;
      final pending = total - completed - missed;

      return {
        'total': total,
        'completed': completed,
        'missed': missed,
        'pending': pending,
      };
    } catch (e) {
      debugPrint(' Get check-in stats error: $e');
      return {
        'total': 0,
        'completed': 0,
        'missed': 0,
        'pending': 0,
      };
    }
  }

  // Private: Schedule notification
  Future<void> _scheduleNotification(String checkInId, DateTime scheduledTime, String? notes) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final notificationId = checkInId.hashCode.abs();

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'checkin_channel',
        'Check-in Reminders',
        channelDescription: 'Safety check-in notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification 5 minutes before check-in
      final notificationTime = scheduledTime.subtract(const Duration(minutes: 5));

      if (notificationTime.isAfter(DateTime.now())) {
        // Convert to TZ DateTime
        final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

        // FIXED: Removed uiLocalNotificationDateInterpretation parameter (Lines 302-303)
        await _notifications.zonedSchedule(
          notificationId,
          ' Safety Check-in Reminder',
          notes ?? 'Your check-in is in 5 minutes. Tap to confirm you\'re safe.',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        debugPrint(' Notification scheduled for $notificationTime (ID: $notificationId)');
      }

      // Also schedule notification at check-in time
      final checkInNotificationTime = scheduledTime;
      if (checkInNotificationTime.isAfter(DateTime.now())) {
        final checkInDate = tz.TZDateTime.from(checkInNotificationTime, tz.local);
        final checkInNotificationId = (checkInId.hashCode + 1).abs();

        // FIXED: Removed uiLocalNotificationDateInterpretation parameter (Lines 322-323)
        await _notifications.zonedSchedule(
          checkInNotificationId,
          ' Safety Check-in Due NOW',
          'Please confirm you\'re safe! This check-in is now due.',
          checkInDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        debugPrint(' Check-in notification scheduled for $checkInNotificationTime (ID: $checkInNotificationId)');
      }
    } catch (e) {
      debugPrint(' Schedule notification error: $e');
    }
  }

  // Private: Cancel notification
  Future<void> _cancelNotification(String checkInId) async {
    try {
      final notificationId = checkInId.hashCode.abs();
      final checkInNotificationId = (checkInId.hashCode + 1).abs();

      await _notifications.cancel(notificationId);
      await _notifications.cancel(checkInNotificationId);

      debugPrint(' Notifications cancelled for $checkInId');
    } catch (e) {
      debugPrint(' Cancel notification error: $e');
    }
  }

  // Private: Schedule recurring check-in
  Future<void> _scheduleRecurringCheckIn(
      String userId,
      DateTime lastScheduledTime,
      String frequency,
      String? notes,
      ) async {
    try {
      final DateTime nextTime;

      switch (frequency) {
        case 'hourly':
          nextTime = lastScheduledTime.add(const Duration(hours: 1));
          break;
        case 'daily':
          nextTime = lastScheduledTime.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextTime = lastScheduledTime.add(const Duration(days: 7));
          break;
        default:
          return;
      }

      await scheduleCheckIn(
        userId: userId,
        scheduledTime: nextTime,
        frequency: frequency,
        notes: notes,
      );
    } catch (e) {
      debugPrint(' Schedule recurring check-in error: $e');
    }
  }

  // Enable/disable check-in system
  Future<void> setCheckInEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('checkin_enabled', enabled);
      debugPrint(' Check-in system ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint(' Set check-in enabled error: $e');
    }
  }

  Future<bool> isCheckInEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('checkin_enabled') ?? false;
    } catch (e) {
      debugPrint(' Is check-in enabled error: $e');
      return false;
    }
  }
}