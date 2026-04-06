import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserService {
  static const String _userProfileKey = 'user_profile';
  static const String _emergencyContactsKey = 'emergency_contacts';
  static const String _emergencyMessageKey = 'emergency_message';
  static const String _userPreferencesKey = 'user_preferences';

  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  /// Check if user profile exists
  Future<bool> hasUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userProfileKey);
    } catch (e) {
      debugPrint(' Error checking user profile: $e');
      return false;
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);

      if (profileJson != null && profileJson.isNotEmpty) {
        final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
        return UserProfile.fromJson(profileMap);
      }
      return null;
    } catch (e) {
      debugPrint(' Error getting user profile: $e');
      return null;
    }
  }

  /// Save user profile
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      final success = await prefs.setString(_userProfileKey, profileJson);

      if (success) {
        debugPrint(' User profile saved successfully');
      }
      return success;
    } catch (e) {
      debugPrint(' Error saving user profile: $e');
      return false;
    }
  }

  /// Update user profile (alias for saveUserProfile)
  Future<bool> updateUserProfile(UserProfile profile) async {
    return await saveUserProfile(profile);
  }

  /// Get emergency contacts
  Future<List<String>> getEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_emergencyContactsKey) ?? [];
    } catch (e) {
      debugPrint(' Error getting emergency contacts: $e');
      return [];
    }
  }

  /// Save emergency contacts
  Future<bool> saveEmergencyContacts(List<String> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Remove duplicates and empty strings
      final cleanContacts = contacts
          .where((contact) => contact.trim().isNotEmpty)
          .toSet()
          .toList();

      final success = await prefs.setStringList(_emergencyContactsKey, cleanContacts);

      if (success) {
        debugPrint(' Emergency contacts saved: ${cleanContacts.length} contacts');
      }
      return success;
    } catch (e) {
      debugPrint(' Error saving emergency contacts: $e');
      return false;
    }
  }

  /// Add emergency contact
  Future<bool> addEmergencyContact(String contact) async {
    try {
      final contacts = await getEmergencyContacts();
      if (!contacts.contains(contact) && contact.trim().isNotEmpty) {
        contacts.add(contact);
        return await saveEmergencyContacts(contacts);
      }
      return false;
    } catch (e) {
      debugPrint(' Error adding emergency contact: $e');
      return false;
    }
  }

  /// Remove emergency contact
  Future<bool> removeEmergencyContact(String contact) async {
    try {
      final contacts = await getEmergencyContacts();
      contacts.remove(contact);
      return await saveEmergencyContacts(contacts);
    } catch (e) {
      debugPrint(' Error removing emergency contact: $e');
      return false;
    }
  }

  /// Get emergency message
  Future<String> getEmergencyMessage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emergencyMessageKey) ??
          " Emergency! I need immediate assistance. Please send help to my location.";
    } catch (e) {
      debugPrint(' Error getting emergency message: $e');
      return " Emergency! I need immediate assistance. Please send help to my location.";
    }
  }

  /// Save emergency message
  Future<bool> saveEmergencyMessage(String message) async {
    try {
      if (message.trim().isEmpty) {
        debugPrint(' Cannot save empty emergency message');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_emergencyMessageKey, message);

      if (success) {
        debugPrint(' Emergency message saved');
      }
      return success;
    } catch (e) {
      debugPrint(' Error saving emergency message: $e');
      return false;
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_userPreferencesKey);

      if (prefsJson != null && prefsJson.isNotEmpty) {
        return jsonDecode(prefsJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint(' Error getting user preferences: $e');
      return {};
    }
  }

  /// Save user preferences
  Future<bool> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = jsonEncode(preferences);
      return await prefs.setString(_userPreferencesKey, prefsJson);
    } catch (e) {
      debugPrint(' Error saving user preferences: $e');
      return false;
    }
  }

  /// Update specific user preference
  Future<bool> updateUserPreference(String key, dynamic value) async {
    try {
      final preferences = await getUserPreferences();
      preferences[key] = value;
      return await saveUserPreferences(preferences);
    } catch (e) {
      debugPrint(' Error updating user preference: $e');
      return false;
    }
  }

  /// Clear all user data
  Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_emergencyContactsKey);
      await prefs.remove(_emergencyMessageKey);
      await prefs.remove(_userPreferencesKey);

      debugPrint(' All user data cleared');
      return true;
    } catch (e) {
      debugPrint(' Error clearing user data: $e');
      return false;
    }
  }

  /// Clear only user profile (keep emergency data)
  Future<bool> clearUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);

      debugPrint(' User profile cleared');
      return true;
    } catch (e) {
      debugPrint(' Error clearing user profile: $e');
      return false;
    }
  }

  /// Export all user data
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final profile = await getUserProfile();
      final contacts = await getEmergencyContacts();
      final message = await getEmergencyMessage();
      final preferences = await getUserPreferences();

      return {
        'profile': profile?.toJson(),
        'emergencyContacts': contacts,
        'emergencyMessage': message,
        'preferences': preferences,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint(' Error exporting user data: $e');
      return {};
    }
  }

  /// Import user data
  Future<bool> importUserData(Map<String, dynamic> data) async {
    try {
      if (data['profile'] != null) {
        final profile = UserProfile.fromJson(data['profile']);
        await saveUserProfile(profile);
      }

      if (data['emergencyContacts'] != null) {
        final contacts = List<String>.from(data['emergencyContacts']);
        await saveEmergencyContacts(contacts);
      }

      if (data['emergencyMessage'] != null) {
        await saveEmergencyMessage(data['emergencyMessage']);
      }

      if (data['preferences'] != null) {
        await saveUserPreferences(data['preferences']);
      }

      debugPrint(' User data imported successfully');
      return true;
    } catch (e) {
      debugPrint(' Error importing user data: $e');
      return false;
    }
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'serviceName': 'UserService',
      'singleton': true,
      'keys': [
        _userProfileKey,
        _emergencyContactsKey,
        _emergencyMessageKey,
        _userPreferencesKey,
      ],
    };
  }
}