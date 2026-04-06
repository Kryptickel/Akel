import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickSettingsService {
// Get all settings at once
  Future<Map<String, bool>> getAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'darkMode': prefs.getBool('dark_mode') ?? true,
        'silentMode': prefs.getBool('silent_mode') ?? false,
        'locationSharing': prefs.getBool('share_location') ?? true,
        'soundAlerts': prefs.getBool('sound_alerts_enabled') ?? true,
        'hapticFeedback': prefs.getBool('vibration_enabled') ?? true,
        'fallDetection': prefs.getBool('fall_detection_enabled') ?? false,
        'shakeDetection': prefs.getBool('shake_detection_enabled') ?? false,
        'sosButton': prefs.getBool('sos_button_visible') ?? true,
        'notifications': prefs.getBool('notifications_enabled') ?? true,
        'locationServices': prefs.getBool('location_enabled') ?? true,
      };
    } catch (e) {
      debugPrint('❌ Get all settings error: $e');
      return {};
    }
  }

// Toggle a specific setting
  Future<bool> toggleSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      debugPrint('✅ Setting toggled: $key = $value');
      return true;
    } catch (e) {
      debugPrint('❌ Toggle setting error: $e');
      return false;
    }
  }

// Get single setting
  Future<bool> getSetting(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      debugPrint('❌ Get setting error: $e');
      return defaultValue;
    }
  }
}