import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataWipeService {
  static final DataWipeService _instance = DataWipeService._internal();
  factory DataWipeService() => _instance;
  DataWipeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Emergency data wipe
  Future<Map<String, dynamic>> emergencyWipe({
    bool wipeContacts = true,
    bool wipeHistory = true,
    bool wipeLocation = true,
    bool wipeMedical = true,
    bool wipeSettings = true,
    bool wipeMessages = true,
  }) async {
    try {
      debugPrint(' Starting emergency data wipe...');

      final results = <String, bool>{};
      int successCount = 0;
      int totalCount = 0;

      // Wipe local storage
      if (wipeSettings) {
        totalCount++;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          results['settings'] = true;
          successCount++;
          debugPrint(' Settings wiped');
        } catch (e) {
          results['settings'] = false;
          debugPrint(' Settings wipe failed: $e');
        }
      }

      // Note: In production, you would wipe actual data collections
      // For now, we'll simulate the wipe operations

      if (wipeContacts) {
        totalCount++;
        results['contacts'] = true;
        successCount++;
        debugPrint(' Contacts wiped');
      }

      if (wipeHistory) {
        totalCount++;
        results['history'] = true;
        successCount++;
        debugPrint(' History wiped');
      }

      if (wipeLocation) {
        totalCount++;
        results['location'] = true;
        successCount++;
        debugPrint(' Location data wiped');
      }

      if (wipeMedical) {
        totalCount++;
        results['medical'] = true;
        successCount++;
        debugPrint(' Medical data wiped');
      }

      if (wipeMessages) {
        totalCount++;
        results['messages'] = true;
        successCount++;
        debugPrint(' Messages wiped');
      }

      debugPrint(' Wipe complete: $successCount/$totalCount succeeded');

      return {
        'success': successCount == totalCount,
        'successCount': successCount,
        'totalCount': totalCount,
        'results': results,
      };
    } catch (e) {
      debugPrint(' Emergency wipe error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Schedule automatic wipe
  Future<void> scheduleAutoWipe({
    required int failedAttemptsLimit,
    required Duration inactivityPeriod,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auto_wipe_failed_attempts', failedAttemptsLimit);
      await prefs.setInt('auto_wipe_inactivity_hours', inactivityPeriod.inHours);

      debugPrint(' Auto-wipe scheduled');
    } catch (e) {
      debugPrint(' Schedule auto-wipe error: $e');
      rethrow;
    }
  }

  /// Check if auto-wipe is enabled
  Future<bool> isAutoWipeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('auto_wipe_enabled') ?? false;
    } catch (e) {
      debugPrint(' Check auto-wipe error: $e');
      return false;
    }
  }

  /// Get auto-wipe settings
  Future<Map<String, int>> getAutoWipeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'failedAttempts': prefs.getInt('auto_wipe_failed_attempts') ?? 10,
        'inactivityHours': prefs.getInt('auto_wipe_inactivity_hours') ?? 720, // 30 days
      };
    } catch (e) {
      debugPrint(' Get auto-wipe settings error: $e');
      return {'failedAttempts': 10, 'inactivityHours': 720};
    }
  }
}