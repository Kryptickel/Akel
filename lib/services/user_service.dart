import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserService {
  static const String _userProfileKey = 'user_profile';
  static const String _emergencyContactsKey = 'emergency_contacts';
  static const String _emergencyMessageKey = 'emergency_message';

  Future<bool> hasUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userProfileKey);
    } catch (e) {
      return false;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      
      if (profileJson != null) {
        final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
        return UserProfile.fromJson(profileMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString(_userProfileKey, profileJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_emergencyContactsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveEmergencyContacts(List<String> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_emergencyContactsKey, contacts);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> getEmergencyMessage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emergencyMessageKey) ?? 
          "Emergency! I need immediate assistance. Please send help to my location.";
    } catch (e) {
      return "Emergency! I need immediate assistance. Please send help to my location.";
    }
  }

  Future<bool> saveEmergencyMessage(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emergencyMessageKey, message);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    return await saveUserProfile(profile);
  }

  Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_emergencyContactsKey);
      await prefs.remove(_emergencyMessageKey);
      return true;
    } catch (e) {
      return false;
    }
  }
}