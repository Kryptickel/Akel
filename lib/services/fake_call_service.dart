import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fake_call.dart';

class FakeCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Schedule a fake call
  Future<String> scheduleFakeCall({
    required String userId,
    required String callerName,
    required String callerNumber,
    required int delaySeconds,
  }) async {
    try {
      final scheduledTime = DateTime.now().add(Duration(seconds: delaySeconds));

      final fakeCall = FakeCall(
        id: '',
        userId: userId,
        callerName: callerName,
        callerNumber: callerNumber,
        scheduledTime: scheduledTime,
        delaySeconds: delaySeconds,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fake_calls')
          .add(fakeCall.toMap());

      debugPrint('✅ Fake call scheduled: ${docRef.id} for ${callerName}');

// Store active fake call ID
      await _setActiveFakeCallId(docRef.id);

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Schedule fake call error: $e');
      rethrow;
    }
  }

// Get active fake call ID
  Future<String?> getActiveFakeCallId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('active_fake_call_id');
    } catch (e) {
      debugPrint('❌ Get active fake call ID error: $e');
      return null;
    }
  }

// Set active fake call ID
  Future<void> _setActiveFakeCallId(String callId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_fake_call_id', callId);
      await prefs.setString('active_fake_call_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Set active fake call ID error: $e');
    }
  }

// Clear active fake call
  Future<void> clearActiveFakeCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_fake_call_id');
      await prefs.remove('active_fake_call_time');
      debugPrint('✅ Active fake call cleared');
    } catch (e) {
      debugPrint('❌ Clear active fake call error: $e');
    }
  }

// Mark fake call as completed
  Future<void> completeFakeCall(String userId, String callId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fake_calls')
          .doc(callId)
          .update({
        'completed': true,
        'triggeredTime': DateTime.now().toIso8601String(),
      });

      await clearActiveFakeCall();

      debugPrint('✅ Fake call completed: $callId');
    } catch (e) {
      debugPrint('❌ Complete fake call error: $e');
      rethrow;
    }
  }

// Cancel fake call
  Future<void> cancelFakeCall(String userId, String callId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fake_calls')
          .doc(callId)
          .delete();

      await clearActiveFakeCall();

      debugPrint('✅ Fake call cancelled: $callId');
    } catch (e) {
      debugPrint('❌ Cancel fake call error: $e');
      rethrow;
    }
  }

// Get fake call history
  Stream<List<FakeCall>> getFakeCallHistory(String userId, {int limit = 20}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('fake_calls')
        .orderBy('scheduledTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FakeCall.fromMap(doc.data(), doc.id))
        .toList());
  }

// Get fake call statistics
  Future<Map<String, int>> getFakeCallStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fake_calls')
          .get();

      final total = snapshot.docs.length;
      final completed = snapshot.docs.where((doc) => doc.data()['completed'] == true).length;
      final cancelled = total - completed;

      return {
        'total': total,
        'completed': completed,
        'cancelled': cancelled,
      };
    } catch (e) {
      debugPrint('❌ Get fake call stats error: $e');
      return {
        'total': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }

// Get default caller presets
  static List<Map<String, String>> getCallerPresets() {
    return [
      {'name': 'Mom', 'number': '+1 (555) 123-4567'},
      {'name': 'Dad', 'number': '+1 (555) 234-5678'},
      {'name': 'Boss', 'number': '+1 (555) 345-6789'},
      {'name': 'Friend', 'number': '+1 (555) 456-7890'},
      {'name': 'Doctor', 'number': '+1 (555) 567-8901'},
      {'name': 'Emergency', 'number': '911'},
    ];
  }

// Get delay presets (in seconds)
  static List<Map<String, dynamic>> getDelayPresets() {
    return [
      {'label': '5 seconds', 'seconds': 5},
      {'label': '15 seconds', 'seconds': 15},
      {'label': '30 seconds', 'seconds': 30},
      {'label': '1 minute', 'seconds': 60},
      {'label': '2 minutes', 'seconds': 120},
      {'label': '5 minutes', 'seconds': 300},
      {'label': '10 minutes', 'seconds': 600},
      {'label': '30 minutes', 'seconds': 1800},
    ];
  }

// Enable/disable fake call feature
  Future<void> setFakeCallEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fake_call_enabled', enabled);
      debugPrint('✅ Fake call ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Set fake call enabled error: $e');
    }
  }

  Future<bool> isFakeCallEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('fake_call_enabled') ?? true;
    } catch (e) {
      debugPrint('❌ Is fake call enabled error: $e');
      return false;
    }
  }
}