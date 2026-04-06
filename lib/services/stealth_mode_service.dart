import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StealthModeService {
  static final StealthModeService _instance = StealthModeService._internal();
  factory StealthModeService() => _instance;
  StealthModeService._internal();

  /// Check if stealth mode is enabled
  Future<bool> isStealthModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('stealth_mode_enabled') ?? false;
    } catch (e) {
      debugPrint('❌ Check stealth mode error: $e');
      return false;
    }
  }

  /// Enable/disable stealth mode
  Future<void> setStealthMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stealth_mode_enabled', enabled);

      debugPrint(enabled ? '🥷 Stealth mode enabled' : '👁️ Stealth mode disabled');
    } catch (e) {
      debugPrint('❌ Set stealth mode error: $e');
      rethrow;
    }
  }

  /// Check if specific stealth feature is enabled
  Future<bool> isFeatureHidden(String featureKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stealthEnabled = prefs.getBool('stealth_mode_enabled') ?? false;

      if (!stealthEnabled) return false;

      return prefs.getBool('stealth_hide_$featureKey') ?? false;
    } catch (e) {
      debugPrint('❌ Check feature hidden error: $e');
      return false;
    }
  }

  /// Set feature visibility in stealth mode
  Future<void> setFeatureHidden(String featureKey, bool hidden) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stealth_hide_$featureKey', hidden);

      debugPrint('🔒 Feature $featureKey ${hidden ? 'hidden' : 'visible'}');
    } catch (e) {
      debugPrint('❌ Set feature hidden error: $e');
      rethrow;
    }
  }

  /// Get stealth mode settings
  Future<Map<String, bool>> getStealthSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'enabled': prefs.getBool('stealth_mode_enabled') ?? false,
        'hide_app_name': prefs.getBool('stealth_hide_app_name') ?? false,
        'hide_panic_button': prefs.getBool('stealth_hide_panic_button') ?? false,
        'hide_notifications': prefs.getBool('stealth_hide_notifications') ?? false,
        'hide_emergency_contacts': prefs.getBool('stealth_hide_emergency_contacts') ?? false,
        'hide_location_sharing': prefs.getBool('stealth_hide_location_sharing') ?? false,
        'disguise_app_icon': prefs.getBool('stealth_disguise_app_icon') ?? false,
        'silent_alerts': prefs.getBool('stealth_silent_alerts') ?? false,
        'no_countdown': prefs.getBool('stealth_no_countdown') ?? false,
        'hide_recent_activity': prefs.getBool('stealth_hide_recent_activity') ?? false,
      };
    } catch (e) {
      debugPrint('❌ Get stealth settings error: $e');
      return {
        'enabled': false,
        'hide_app_name': false,
        'hide_panic_button': false,
        'hide_notifications': false,
        'hide_emergency_contacts': false,
        'hide_location_sharing': false,
        'disguise_app_icon': false,
        'silent_alerts': false,
        'no_countdown': false,
        'hide_recent_activity': false,
      };
    }
  }

  /// Save all stealth settings
  Future<void> saveStealthSettings(Map<String, bool> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in settings.entries) {
        if (entry.key == 'enabled') {
          await prefs.setBool('stealth_mode_enabled', entry.value);
        } else {
          await prefs.setBool('stealth_${entry.key}', entry.value);
        }
      }

      debugPrint('✅ Stealth settings saved');
    } catch (e) {
      debugPrint('❌ Save stealth settings error: $e');
      rethrow;
    }
  }

  /// Get disguised app name
  Future<String> getDisguisedAppName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('stealth_disguised_name') ?? 'Calculator';
    } catch (e) {
      debugPrint('❌ Get disguised name error: $e');
      return 'Calculator';
    }
  }

  /// Set disguised app name
  Future<void> setDisguisedAppName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stealth_disguised_name', name);

      debugPrint('🎭 Disguised app name set to: $name');
    } catch (e) {
      debugPrint('❌ Set disguised name error: $e');
      rethrow;
    }
  }

  /// Stealth mode disguise options
  static const List<Map<String, dynamic>> disguiseOptions = [
    {
      'name': 'Calculator',
      'icon': Icons.calculate,
      'color': 0xFF2196F3,
    },
    {
      'name': 'Notes',
      'icon': Icons.note,
      'color': 0xFFFF9800,
    },
    {
      'name': 'Weather',
      'icon': Icons.cloud,
      'color': 0xFF03A9F4,
    },
    {
      'name': 'Calendar',
      'icon': Icons.calendar_today,
      'color': 0xFFF44336,
    },
    {
      'name': 'Clock',
      'icon': Icons.access_time,
      'color': 0xFF9C27B0,
    },
    {
      'name': 'Contacts',
      'icon': Icons.contacts,
      'color': 0xFF4CAF50,
    },
    {
      'name': 'Photos',
      'icon': Icons.photo_library,
      'color': 0xFFE91E63,
    },
    {
      'name': 'Music',
      'icon': Icons.music_note,
      'color': 0xFF673AB7,
    },
  ];

  /// Clear all stealth settings
  Future<void> clearStealthSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keys = prefs.getKeys().where((key) => key.startsWith('stealth_'));
      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('🧹 Stealth settings cleared');
    } catch (e) {
      debugPrint('❌ Clear stealth settings error: $e');
      rethrow;
    }
  }
}