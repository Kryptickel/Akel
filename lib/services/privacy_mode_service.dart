import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyModeService {
  static final PrivacyModeService _instance = PrivacyModeService._internal();
  factory PrivacyModeService() => _instance;
  PrivacyModeService._internal();

  /// Check if privacy mode is enabled
  Future<bool> isPrivacyModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('privacy_mode_enabled') ?? false;
    } catch (e) {
      debugPrint('❌ Check privacy mode error: $e');
      return false;
    }
  }

  /// Enable/disable privacy mode
  Future<void> setPrivacyMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_mode_enabled', enabled);

      debugPrint(enabled ? '🔒 Privacy mode enabled' : '🔓 Privacy mode disabled');
    } catch (e) {
      debugPrint('❌ Set privacy mode error: $e');
      rethrow;
    }
  }

  /// Get privacy settings
  Future<Map<String, bool>> getPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'enabled': prefs.getBool('privacy_mode_enabled') ?? false,
        'disable_analytics': prefs.getBool('privacy_disable_analytics') ?? false,
        'disable_crash_reports': prefs.getBool('privacy_disable_crash_reports') ?? false,
        'disable_location_history': prefs.getBool('privacy_disable_location_history') ?? false,
        'disable_contact_sync': prefs.getBool('privacy_disable_contact_sync') ?? false,
        'disable_usage_stats': prefs.getBool('privacy_disable_usage_stats') ?? false,
        'auto_delete_history': prefs.getBool('privacy_auto_delete_history') ?? false,
        'encrypt_local_data': prefs.getBool('privacy_encrypt_local_data') ?? false,
        'block_screenshots': prefs.getBool('privacy_block_screenshots') ?? false,
        'incognito_mode': prefs.getBool('privacy_incognito_mode') ?? false,
      };
    } catch (e) {
      debugPrint('❌ Get privacy settings error: $e');
      return {};
    }
  }

  /// Save privacy setting
  Future<void> savePrivacySetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_$key', value);

      debugPrint('✅ Privacy setting saved: $key = $value');
    } catch (e) {
      debugPrint('❌ Save privacy setting error: $e');
      rethrow;
    }
  }

  /// Clear all privacy settings
  Future<void> clearPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keys = prefs.getKeys().where((key) => key.startsWith('privacy_'));
      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('🧹 Privacy settings cleared');
    } catch (e) {
      debugPrint('❌ Clear privacy settings error: $e');
      rethrow;
    }
  }
}