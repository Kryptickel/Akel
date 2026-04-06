import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SafeWordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Check if safe word is enabled
  Future<bool> isSafeWordEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('safe_word_enabled') ?? false;
    } catch (e) {
      debugPrint('❌ Error checking safe word status: $e');
      return false;
    }
  }

// Get the configured safe word
  Future<String?> getSafeWord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('safe_word');
    } catch (e) {
      debugPrint('❌ Error getting safe word: $e');
      return null;
    }
  }

// Set safe word
  Future<void> setSafeWord(String safeWord) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('safe_word', safeWord.trim().toLowerCase());
      await prefs.setBool('safe_word_enabled', true);
      debugPrint('✅ Safe word set successfully');
    } catch (e) {
      debugPrint('❌ Error setting safe word: $e');
      rethrow;
    }
  }

// Disable safe word
  Future<void> disableSafeWord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('safe_word_enabled', false);
      debugPrint('✅ Safe word disabled');
    } catch (e) {
      debugPrint('❌ Error disabling safe word: $e');
      rethrow;
    }
  }

// Remove safe word
  Future<void> removeSafeWord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('safe_word');
      await prefs.remove('safe_word_enabled');
      debugPrint('✅ Safe word removed');
    } catch (e) {
      debugPrint('❌ Error removing safe word: $e');
      rethrow;
    }
  }

// Verify safe word
  Future<bool> verifySafeWord(String inputWord) async {
    try {
      final enabled = await isSafeWordEnabled();
      if (!enabled) return false;

      final storedWord = await getSafeWord();
      if (storedWord == null) return false;

      final matches = inputWord.trim().toLowerCase() == storedWord;

      if (matches) {
        debugPrint('🔐 Safe word verified - Silent panic triggered');
      }

      return matches;
    } catch (e) {
      debugPrint('❌ Error verifying safe word: $e');
      return false;
    }
  }

// Log safe word usage
  Future<void> logSafeWordUsage(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('safe_word_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'safe_word_triggered',
      });
      debugPrint('✅ Safe word usage logged');
    } catch (e) {
      debugPrint('❌ Error logging safe word usage: $e');
    }
  }

// Get safe word usage statistics
  Future<int> getSafeWordUsageCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('safe_word_logs')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting safe word count: $e');
      return 0;
    }
  }
}